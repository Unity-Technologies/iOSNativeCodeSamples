#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import "UnityAppController.h"

#include "Unity/IUnityInterface.h"
#include "Unity/IUnityGraphics.h"
#include "Unity/IUnityGraphicsMetal.h"

// plugin globals

static IUnityInterfaces*    g_UnityInterfaces   = 0;
static IUnityGraphics*      g_Graphics          = 0;

// NB finally in 2017.4 we switched to versioned metal plugin interface
// NB old unversioned interface will be still provided for some time for backwards compatibility
static IUnityGraphicsMetalV1* g_MetalGraphics = 0;


// plugin assets

static id<MTLFunction> g_VProg, g_FShaderColor, g_FShaderTexture;
static id<MTLBuffer> g_VB, g_IB;
static MTLVertexDescriptor* g_VertexDesc;

static void CreatePluginAssets() {
    NSString* shaderStr = @
        "#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "struct AppData\n"
        "{\n"
        "    float4 in_pos [[attribute(0)]];\n"
        "};\n"
        "struct VProgOutput\n"
        "{\n"
        "    float4 out_pos [[position]];\n"
        "    float2 texcoord;\n"
        "};\n"
        "struct FShaderOutput\n"
        "{\n"
        "    half4 frag_data [[color(0)]];\n"
        "};\n"
        "vertex VProgOutput vprog(AppData input [[stage_in]])\n"
        "{\n"
        "    VProgOutput out = { float4(input.in_pos.xy, 0, 1), input.in_pos.zw };\n"
        "    return out;\n"
        "}\n"
        "constexpr sampler blit_tex_sampler(address::clamp_to_edge, filter::linear);\n"
        "fragment FShaderOutput fshader_tex(VProgOutput input [[stage_in]], texture2d<half> tex [[texture(0)]])\n"
        "{\n"
        "    FShaderOutput out = { tex.sample(blit_tex_sampler, input.texcoord) };\n"
        "    return out;\n"
        "}\n"
        "fragment FShaderOutput fshader_color(VProgOutput input [[stage_in]])\n"
        "{\n"
        "    FShaderOutput out = { half4(1,0,0,1) };\n"
        "    return out;\n"
        "}\n";

    id<MTLDevice> device = g_MetalGraphics->MetalDevice(); NSBundle* mtlBundle = g_MetalGraphics->MetalBundle();

    id<MTLLibrary> lib = [device newLibraryWithSource:shaderStr options:nil error:nil];
    g_VProg = [lib newFunctionWithName:@"vprog"];
    g_FShaderColor = [lib newFunctionWithName:@"fshader_color"], g_FShaderTexture = [lib newFunctionWithName:@"fshader_tex"];

    // pos.x pos.y uv.x uv.y
    const float vdata[] = {
        -1.0f,  0.0f, 0.0f, 0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        0.0f, -1.0f, 1.0f, 1.0f,
        0.0f,  0.0f, 1.0f, 0.0f,
    };
    const uint16_t idata[] = {0, 1, 2, 2, 3, 0};

    g_VB = [device newBufferWithBytes:vdata length:sizeof(vdata) options:MTLResourceOptionCPUCacheModeDefault];
    g_IB = [device newBufferWithBytes:idata length:sizeof(idata) options:MTLResourceOptionCPUCacheModeDefault];


    MTLVertexAttributeDescriptor* attrDesc = [[mtlBundle classNamed:@"MTLVertexAttributeDescriptor"] new];
    attrDesc.format = MTLVertexFormatFloat4;

    MTLVertexBufferLayoutDescriptor* streamDesc = [[mtlBundle classNamed:@"MTLVertexBufferLayoutDescriptor"] new];
    streamDesc.stride = 4 * sizeof(float);
    streamDesc.stepFunction = MTLVertexStepFunctionPerVertex;
    streamDesc.stepRate = 1;

    g_VertexDesc = [[mtlBundle classNamed:@"MTLVertexDescriptor"] vertexDescriptor];
    g_VertexDesc.attributes[0] = attrDesc;
    g_VertexDesc.layouts[0] = streamDesc;
}

// to simplify our lives: we will use similar setup for both "color rect" and "texture" draw calls
// the only reason we cannot pre-alloc them is that we want to handle changing RT transparently
static id<MTLRenderPipelineState> CreateCommonRenderPipeline(id<MTLFunction> fs, MTLPixelFormat format, int sampleCount) {
    id<MTLDevice> device = g_MetalGraphics->MetalDevice(); NSBundle* mtlBundle = g_MetalGraphics->MetalBundle();

    MTLRenderPipelineDescriptor* pipeDesc = [[mtlBundle classNamed:@"MTLRenderPipelineDescriptor"] new];

    MTLRenderPipelineColorAttachmentDescriptor* colorDesc = [[mtlBundle classNamed:@"MTLRenderPipelineColorAttachmentDescriptor"] new];
    colorDesc.pixelFormat = format;
    pipeDesc.colorAttachments[0] = colorDesc;

    pipeDesc.fragmentFunction = fs;
    pipeDesc.vertexFunction = g_VProg;
    pipeDesc.vertexDescriptor = g_VertexDesc;
    pipeDesc.sampleCount = sampleCount;

    return [device newRenderPipelineStateWithDescriptor:pipeDesc error:nil];
}


// extra draw call: we will hook into current rendering and draw simple colored rect

static MTLPixelFormat g_ExtraDrawCallPixelFormat = MTLPixelFormatInvalid; static int g_ExtraDrawCallSampleCount = 0;
static id<MTLRenderPipelineState> g_ExtraDrawCallPipe = nil;

static void DoExtraDrawCall() {
    // get current render pass setup
    id<MTLTexture> rt = g_MetalGraphics->CurrentRenderPassDescriptor().colorAttachments[0].texture;

    if(rt.pixelFormat != g_ExtraDrawCallPixelFormat || rt.sampleCount != g_ExtraDrawCallSampleCount) {
        // RT format changed - recreate render pipeline
        g_ExtraDrawCallPixelFormat = rt.pixelFormat, g_ExtraDrawCallSampleCount = (int)rt.sampleCount;
        g_ExtraDrawCallPipe = CreateCommonRenderPipeline(g_FShaderColor, g_ExtraDrawCallPixelFormat, g_ExtraDrawCallSampleCount);
    }

    // get current command encoder, update render setup and do extra draw call
    id<MTLRenderCommandEncoder> cmd = (id<MTLRenderCommandEncoder>)g_MetalGraphics->CurrentCommandEncoder();
    [cmd setRenderPipelineState:g_ExtraDrawCallPipe];
    [cmd setCullMode:MTLCullModeNone];
    [cmd setVertexBuffer:g_VB offset:0 atIndex:0];
    [cmd drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:6 indexType:MTLIndexTypeUInt16 indexBuffer:g_IB indexBufferOffset:0];
}

// copy of render surface to a texture

static UnityRenderBuffer g_CopySrcRB = 0, g_CopyDstRB = 0;
UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API void SetRTCopyTargets(void* src, void* dst) {
    g_CopySrcRB = src, g_CopyDstRB = dst;
}

// we need to take special care about what "texture" do we use
//   as in case we are given AA-ed RT we need to use "resolved" texture
static id<MTLTexture> GetColorTexture(UnityRenderBuffer rb) {
    id<MTLTexture> tex = g_MetalGraphics->AAResolvedTextureFromRenderBuffer(rb);
    return tex ? tex : g_MetalGraphics->TextureFromRenderBuffer(rb);
}

static id<MTLTexture> g_RTCopy = nil;

static MTLPixelFormat g_RTCopyPixelFormat = MTLPixelFormatInvalid; static int g_RTCopySampleCount = 0;
static id<MTLRenderPipelineState> g_RTCopyPipe = nil;

static void DoCaptureRT() {
    id<MTLDevice> device = g_MetalGraphics->MetalDevice(); NSBundle* mtlBundle = g_MetalGraphics->MetalBundle();

    if(g_CopySrcRB == 0 || g_CopyDstRB == 0) {
        fprintf(stderr, "RTs to copy are not set!\n");
        return;
    }

    // end current encoder
    g_MetalGraphics->EndCurrentCommandEncoder();

    // get actual texture we want to copy
    id<MTLTexture> src = GetColorTexture(g_CopySrcRB);

    // make sure we recreate texture itself if needed
    if(!g_RTCopy || g_RTCopy.width != src.width || g_RTCopy.height != src.height || g_RTCopy.pixelFormat != src.pixelFormat) {
        MTLTextureDescriptor* txDesc = [[mtlBundle classNamed: @"MTLTextureDescriptor"]
            texture2DDescriptorWithPixelFormat:src.pixelFormat width:src.width height:src.height mipmapped: NO];
        g_RTCopy = [device newTextureWithDescriptor:txDesc];
    }

    // do the copy to temp texture
    id<MTLBlitCommandEncoder> blit = [g_MetalGraphics->CurrentCommandBuffer() blitCommandEncoder];
    [blit copyFromTexture:src sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(src.width, src.height, 1)
        toTexture:g_RTCopy destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)];
    [blit endEncoding];
    blit = nil;

    // render to dst RT
    id<MTLTexture> dst = GetColorTexture(g_CopyDstRB);

    // prepare render pass
    MTLRenderPassColorAttachmentDescriptor* att = [[mtlBundle classNamed: @"MTLRenderPassColorAttachmentDescriptor"] new];
    // NB we assume AA was already resolved, so we dont care
    att.texture = dst; att.loadAction = MTLLoadActionLoad, att.storeAction = MTLStoreActionStore;

    MTLRenderPassDescriptor* desc = [[mtlBundle classNamed: @"MTLRenderPassDescriptor"] new];
    desc.colorAttachments[0] = att;

    // prepare render pipeline
    if(dst.pixelFormat != g_RTCopyPixelFormat || dst.sampleCount != g_RTCopySampleCount) {
        // RT format changed - recreate render pipeline
        g_RTCopyPixelFormat = dst.pixelFormat, g_RTCopySampleCount = (int)dst.sampleCount;
        g_RTCopyPipe = CreateCommonRenderPipeline(g_FShaderTexture, g_RTCopyPixelFormat, g_RTCopySampleCount);
    }

    // render
    id<MTLRenderCommandEncoder> cmd = [g_MetalGraphics->CurrentCommandBuffer() renderCommandEncoderWithDescriptor:desc];
    [cmd setRenderPipelineState:g_RTCopyPipe];
    [cmd setCullMode:MTLCullModeNone];
    [cmd setVertexBuffer:g_VB offset:0 atIndex:0];
    [cmd setFragmentTexture:g_RTCopy atIndex:0];
    [cmd drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:6 indexType:MTLIndexTypeUInt16 indexBuffer:g_IB indexBufferOffset:0];
    [cmd endEncoding];
    cmd = nil;
}



// unity<->plugin interop


enum EventID {
    event_ExtraDrawCall = 0,
    event_CaptureRT,
};
static void UNITY_INTERFACE_API OnRenderEvent(int eventID) {
    switch(eventID) {
        case event_ExtraDrawCall:   DoExtraDrawCall(); break;
        case event_CaptureRT:       DoCaptureRT(); break;
    }
}
static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType) {
    switch (eventType) {
        case kUnityGfxDeviceEventInitialize:
            assert(g_Graphics->GetRenderer() == kUnityGfxRendererMetal);
            CreatePluginAssets();
            break;
        default:
            // ignore others
            break;
    }
}

UnityRenderingEvent UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetRenderEventFunc() {
    return OnRenderEvent;
}


//
void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces) {
    g_UnityInterfaces = unityInterfaces;
    g_Graphics = UNITY_GET_INTERFACE(g_UnityInterfaces, IUnityGraphics);
    g_MetalGraphics = UNITY_GET_INTERFACE(g_UnityInterfaces, IUnityGraphicsMetalV1);

    // we get plugin load after initial graphics init, so do callback manually
    g_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
    OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}
void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload() {
    g_Graphics->UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);
}

// hooking into trampoline

@interface MyAppController : UnityAppController
{
}
- (void)shouldAttachRenderDelegate;
@end
@implementation MyAppController
- (void)shouldAttachRenderDelegate {
    // unlike desktops where plugin dynamic library is automatically loaded and registered
    // we need to do that manually on iOS
    UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
}
@end
IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);

