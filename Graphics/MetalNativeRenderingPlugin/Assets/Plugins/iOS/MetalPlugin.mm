#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import <Metal/Metal.h>

#include "Unity/IUnityInterface.h"
#include "Unity/IUnityGraphics.h"
#include "Unity/IUnityGraphicsMetal.h"


static void UNITY_INTERFACE_API OnRenderEvent(int eventID);
static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType);
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces);
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload();

static IUnityInterfaces*    s_UnityInterfaces   = 0;
static IUnityGraphics*      s_Graphics          = 0;
static IUnityGraphicsMetal* s_MetalGraphics     = 0;


@interface MyAppController : UnityAppController
{
}
- (void)shouldAttachRenderDelegate;
@end
@implementation MyAppController
- (void)shouldAttachRenderDelegate;
{
    UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
}
@end
IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);


static id<MTLTexture> g_RenderColorTexture      = nil;
static id<MTLTexture> g_RenderDepthTexture      = nil;
static id<MTLTexture> g_RenderStencilTexture    = nil;
extern "C" void SetRenderBuffers(void* colorBuffer, void* depthBuffer)
{
    g_RenderColorTexture    = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)colorBuffer);
    g_RenderDepthTexture    = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)depthBuffer);
    g_RenderStencilTexture  = s_MetalGraphics->StencilTextureFromRenderBuffer((UnityRenderBuffer)depthBuffer);
}

static id<MTLTexture> g_TextureCopy = nil;
static id<MTLTexture> CreateTextureCopyIfNeeded(id<MTLTexture> captureRT)
{
    bool create = false;
    if (g_TextureCopy == nil)
        create = true;
    else if (g_TextureCopy.width != captureRT.width || g_TextureCopy.height != captureRT.height)
        create = true;

    if (create)
    {
        MTLTextureDescriptor* txDesc =
            [[s_MetalGraphics->MetalBundle() classNamed: @"MTLTextureDescriptor"]
                texture2DDescriptorWithPixelFormat: captureRT.pixelFormat
                width: captureRT.width height: captureRT.height mipmapped: NO
            ];
        g_TextureCopy = [s_MetalGraphics->MetalDevice() newTextureWithDescriptor: txDesc];
    }

    return g_TextureCopy;
}

static id<MTLFunction>              g_VProg;
static id<MTLFunction>              g_FShader;
static id<MTLBuffer>                g_VB;
static id<MTLBuffer>                g_IB;
static id<MTLRenderPipelineState>   g_Pipe;
static MTLVertexDescriptor*         g_VertexDesc;

static void InitMetalAssets()
{
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
        "fragment FShaderOutput fshader(VProgOutput input [[stage_in]], texture2d<half> tex [[texture(0)]])\n"
        "{\n"
        "    FShaderOutput out = { tex.sample(blit_tex_sampler, input.texcoord) };\n"
        "    return out;\n"
        "}\n";

    id<MTLLibrary> lib = [s_MetalGraphics->MetalDevice() newLibraryWithSource:shaderStr options:nil error:nil];
    g_VProg     = [lib newFunctionWithName:@"vprog"];
    g_FShader   = [lib newFunctionWithName:@"fshader"];

    // pos.x pos.y uv.x uv.y
    const float vdata[] =
    {
        -1.0f,  0.0f, 0.0f, 0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        0.0f, -1.0f, 1.0f, 1.0f,
        0.0f,  0.0f, 1.0f, 0.0f,
    };
    const uint16_t idata[] = {0, 1, 2, 2, 3, 0};

    g_VB = [s_MetalGraphics->MetalDevice() newBufferWithBytes:vdata length:sizeof(vdata) options:MTLResourceOptionCPUCacheModeDefault];
    g_IB = [s_MetalGraphics->MetalDevice() newBufferWithBytes:idata length:sizeof(idata) options:MTLResourceOptionCPUCacheModeDefault];

    MTLVertexAttributeDescriptor* attrDesc = [[[s_MetalGraphics->MetalBundle() classNamed:@"MTLVertexAttributeDescriptor"] alloc] init];
    attrDesc.format         = MTLVertexFormatFloat4;
    attrDesc.offset         = 0;
    attrDesc.bufferIndex    = 0;

    MTLVertexBufferLayoutDescriptor* streamDesc = [[[s_MetalGraphics->MetalBundle() classNamed:@"MTLVertexBufferLayoutDescriptor"] alloc] init];
    streamDesc.stride       = 4 * sizeof(float);
    streamDesc.stepFunction = MTLVertexStepFunctionPerVertex;
    streamDesc.stepRate     = 1;

    g_VertexDesc = [[s_MetalGraphics->MetalBundle() classNamed:@"MTLVertexDescriptor"] vertexDescriptor];
    g_VertexDesc.attributes[0]  = attrDesc;
    g_VertexDesc.layouts[0]     = streamDesc;
}
static void InitMetalPipeline()
{
    if(!g_Pipe)
    {
        // TODO: for now we expect "render" RT to not change
        MTLRenderPipelineDescriptor* pipeDesc = [[[s_MetalGraphics->MetalBundle() classNamed:@"MTLRenderPipelineDescriptor"] alloc] init];

        pipeDesc.depthAttachmentPixelFormat     = g_RenderDepthTexture.pixelFormat;
        pipeDesc.stencilAttachmentPixelFormat   = g_RenderStencilTexture.pixelFormat;
        pipeDesc.sampleCount = 1;

        MTLRenderPipelineColorAttachmentDescriptor* colorDesc = [[[s_MetalGraphics->MetalBundle() classNamed:@"MTLRenderPipelineColorAttachmentDescriptor"] alloc] init];
        colorDesc.pixelFormat       = g_RenderColorTexture.pixelFormat;
        colorDesc.blendingEnabled   = NO;
        pipeDesc.colorAttachments[0] = colorDesc;

        pipeDesc.vertexFunction     = g_VProg;
        pipeDesc.fragmentFunction   = g_FShader;
        pipeDesc.vertexDescriptor   = g_VertexDesc;

        g_Pipe = [s_MetalGraphics->MetalDevice() newRenderPipelineStateWithDescriptor:pipeDesc error:nil];
    }
}


static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType)
{
    switch (eventType)
    {
        case kUnityGfxDeviceEventInitialize:
        {
            assert(s_Graphics->GetRenderer() == kUnityGfxRendererMetal);
            InitMetalAssets();
            break;
        }
        default:
        {
            // just ignore all others
            break;
        }
    }
}
static void UNITY_INTERFACE_API OnRenderEvent(int eventID)
{
    if(eventID == 0)
    {
        // capture RT
        id<MTLTexture> captureRT = s_MetalGraphics->CurrentRenderPassDescriptor().colorAttachments[0].texture;
        s_MetalGraphics->EndCurrentCommandEncoder();

        id<MTLTexture> src = captureRT;
        id<MTLTexture> dst = CreateTextureCopyIfNeeded(captureRT);

        id<MTLBlitCommandEncoder> blit = [s_MetalGraphics->CurrentCommandBuffer() blitCommandEncoder];
        [blit copyFromTexture:src sourceSlice:0 sourceLevel:0
            sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(src.width, src.height, 1)
            toTexture:dst destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)
        ];
        [blit endEncoding];
        blit = nil;
    }
    else if(eventID == 1)
    {
        // render

        InitMetalPipeline();

        id<MTLRenderCommandEncoder> cmd = (id<MTLRenderCommandEncoder>)s_MetalGraphics->CurrentCommandEncoder();
        [cmd setRenderPipelineState: g_Pipe];
        [cmd setCullMode: MTLCullModeNone];
        [cmd setVertexBuffer: g_VB offset: 0 atIndex: 0];
        [cmd setFragmentTexture: g_TextureCopy atIndex: 0];
        [cmd drawIndexedPrimitives: MTLPrimitiveTypeTriangle indexCount: 6 indexType: MTLIndexTypeUInt16 indexBuffer: g_IB indexBufferOffset: 0];
    }
}
extern "C" UnityRenderingEvent UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetRenderEventFunc()
{
    return OnRenderEvent;
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
    s_UnityInterfaces   = unityInterfaces;
    s_Graphics          = s_UnityInterfaces->Get<IUnityGraphics>();
    s_MetalGraphics     = s_UnityInterfaces->Get<IUnityGraphicsMetal>();

    s_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
    OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload()
{
    s_Graphics->UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);
}
