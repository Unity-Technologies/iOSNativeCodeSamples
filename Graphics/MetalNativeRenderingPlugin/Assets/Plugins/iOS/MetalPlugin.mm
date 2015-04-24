#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import <Metal/Metal.h>

#if UNITY_VERSION < 500
	typedef void* UnityRenderBuffer;
#endif


static void SetGraphicsDeviceFunc(void* device, int deviceType, int eventType);
static void PluginRenderMarkerFunc(int marker);


@interface MyAppController : UnityAppController
{
}
- (void)shouldAttachRenderDelegate;
@end
@implementation MyAppController
- (void)shouldAttachRenderDelegate;
{
	UnityRegisterRenderingPlugin(&SetGraphicsDeviceFunc, &PluginRenderMarkerFunc);
}
@end
IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);


static id<MTLTexture> g_CaptureTexture = nil;
extern "C" void SetCaptureBuffers(void* colorBuffer, void* depthBuffer)
{
	g_CaptureTexture = UnityRenderBufferMTLTexture((UnityRenderBuffer)colorBuffer);
}

static id<MTLTexture> g_RenderColorTexture		= nil;
static id<MTLTexture> g_RenderDepthTexture		= nil;
static id<MTLTexture> g_RenderStencilTexture	= nil;
extern "C" void SetRenderBuffers(void* colorBuffer, void* depthBuffer)
{
	g_RenderColorTexture 	= UnityRenderBufferMTLTexture((UnityRenderBuffer)colorBuffer);
	g_RenderDepthTexture 	= UnityRenderBufferMTLTexture((UnityRenderBuffer)depthBuffer);
	g_RenderStencilTexture	= UnityRenderBufferStencilMTLTexture((UnityRenderBuffer)depthBuffer);
}

static id<MTLTexture> g_TextureCopy	= nil;
static id<MTLTexture> CreateTextureCopyIfNeeded()
{
	bool create = false;
	if(g_TextureCopy == nil)
		create = true;
	else if(g_TextureCopy.width != g_CaptureTexture.width || g_TextureCopy.height != g_CaptureTexture.height)
		create = true;

	if(create)
	{
		MTLTextureDescriptor* txDesc =
			[[UnityGetMetalBundle() classNamed:@"MTLTextureDescriptor"]
				texture2DDescriptorWithPixelFormat:g_CaptureTexture.pixelFormat
				width:g_CaptureTexture.width
				height:g_CaptureTexture.height
				mipmapped:NO
			];
		g_TextureCopy = [UnityGetMetalDevice() newTextureWithDescriptor:txDesc];
	}

	return g_TextureCopy;
}

static id<MTLFunction>				g_VProg;
static id<MTLFunction>				g_FShader;
static id<MTLBuffer>				g_VB;
static id<MTLBuffer>				g_IB;
static id<MTLRenderPipelineState>	g_Pipe;
static MTLVertexDescriptor*			g_VertexDesc;
static void InitMetalPipeline()
{
	if(!g_VProg)
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

		id<MTLLibrary> lib = [UnityGetMetalDevice() newLibraryWithSource:shaderStr options:nil error:nil];
		g_VProg		= [lib newFunctionWithName:@"vprog"];
		g_FShader	= [lib newFunctionWithName:@"fshader"];

		// pos.x pos.y uv.x uv.y
		const float vdata[] =
		{
			-1.0f,  0.0f, 0.0f, 0.0f,
			-1.0f, -1.0f, 0.0f, 1.0f,
			 0.0f, -1.0f, 1.0f, 1.0f,
			 0.0f,  0.0f, 1.0f, 0.0f,
		};
		const uint16_t idata[] = {0, 1, 2, 2, 3, 0};

		g_VB = [UnityGetMetalDevice() newBufferWithBytes:vdata length:sizeof(vdata) options:MTLResourceOptionCPUCacheModeDefault];
		g_IB = [UnityGetMetalDevice() newBufferWithBytes:idata length:sizeof(idata) options:MTLResourceOptionCPUCacheModeDefault];

		MTLVertexAttributeDescriptor* attrDesc = [[[UnityGetMetalBundle() classNamed:@"MTLVertexAttributeDescriptor"] alloc] init];
		attrDesc.format			= MTLVertexFormatFloat4;
		attrDesc.offset			= 0;
		attrDesc.bufferIndex	= 0;

		MTLVertexBufferLayoutDescriptor* streamDesc = [[[UnityGetMetalBundle() classNamed:@"MTLVertexBufferLayoutDescriptor"] alloc] init];
		streamDesc.stride = 4*sizeof(float);
		streamDesc.stepFunction = MTLVertexStepFunctionPerVertex;
		streamDesc.stepRate = 1;

		g_VertexDesc = [[UnityGetMetalBundle() classNamed:@"MTLVertexDescriptor"] vertexDescriptor];
		g_VertexDesc.attributes[0] = attrDesc;
		g_VertexDesc.layouts[0] = streamDesc;


		// TODO: for now we expect "render" RT to not change
		MTLRenderPipelineDescriptor* pipeDesc = [[[UnityGetMetalBundle() classNamed:@"MTLRenderPipelineDescriptor"] alloc] init];

		pipeDesc.depthAttachmentPixelFormat	= g_RenderDepthTexture.pixelFormat;
		pipeDesc.stencilAttachmentPixelFormat = g_RenderStencilTexture.pixelFormat;
		pipeDesc.sampleCount = 1;

		MTLRenderPipelineColorAttachmentDescriptor* colorDesc = [[[UnityGetMetalBundle() classNamed:@"MTLRenderPipelineColorAttachmentDescriptor"] alloc] init];
		colorDesc.pixelFormat = g_RenderColorTexture.pixelFormat;
		colorDesc.blendingEnabled = NO;
		pipeDesc.colorAttachments[0] = colorDesc;

		pipeDesc.vertexFunction = g_VProg;
		pipeDesc.fragmentFunction = g_FShader;
		pipeDesc.vertexDescriptor = g_VertexDesc;

		g_Pipe = [UnityGetMetalDevice() newRenderPipelineStateWithDescriptor:pipeDesc error:nil];
	}
}


static void SetGraphicsDeviceFunc(void* device, int deviceType, int eventType)
{
	assert(deviceType == 16 && "Only Metal is supported with this plugin");
}
static void PluginRenderMarkerFunc(int marker)
{
	if(marker == 0)
	{
		// capture RT

		UnityEndCurrentMTLCommandEncoder();

		id<MTLTexture> src = g_CaptureTexture;
		id<MTLTexture> dst = CreateTextureCopyIfNeeded();

		id<MTLBlitCommandEncoder> blit = [UnityCurrentMTLCommandBuffer() blitCommandEncoder];
		[blit copyFromTexture:src sourceSlice:0 sourceLevel:0
			sourceOrigin:MTLOriginMake(0,0,0) sourceSize:MTLSizeMake(src.width, src.height, 1)
			toTexture:dst destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0,0,0)
		];
		[blit endEncoding];
		blit = nil;
	}
	else if(marker == 1)
	{
		// render

		InitMetalPipeline();

		id<MTLRenderCommandEncoder> cmd = (id<MTLRenderCommandEncoder>)UnityCurrentMTLCommandEncoder();
		[cmd setRenderPipelineState:g_Pipe];
		[cmd setCullMode:MTLCullModeNone];
		[cmd setVertexBuffer:g_VB offset:0 atIndex:0];
		[cmd setFragmentTexture:g_TextureCopy atIndex:0];
		[cmd drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:6 indexType:MTLIndexTypeUInt16 indexBuffer:g_IB indexBufferOffset:0];
	}
}
