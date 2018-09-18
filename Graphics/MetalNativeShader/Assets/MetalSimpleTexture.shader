Shader "MetalSimpleTexture"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			METALINCLUDE
			#include <metal_stdlib>
			#include <metal_texture>
			ENDMETAL

			METALPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			using namespace metal;

			// currently METALPROGRAM supports only one uniform buffer, shared between vertex program and fragment shader
			struct Globals
			{
				METAL_CONST_MATRIX(float, 4,4, unity_ObjectToWorld);
				METAL_CONST_MATRIX(float, 4,4, unity_MatrixVP);
				METAL_CONST_VECTOR(half, 4, _Color);
			};

			struct ColorInput
			{
				float4 color;
			};

			struct InputVP
			{
				float4 pos METAL_VERTEX_INPUT(0);
				float2 uv  METAL_VERTEX_INPUT(4);
			};
			struct OutputVP
			{
				float4 pos [[ position ]];
				float2 uv  [[ user(TEXCOORD0) ]];
			};
			struct OutputFS
			{
				half4 color [[ color(0) ]];
			};

			vertex OutputVP vert(constant Globals& glob [[ buffer(0) ]], InputVP input [[ stage_in ]])
			{
				OutputVP output;
				output.pos = glob.unity_MatrixVP * (glob.unity_ObjectToWorld * input.pos);
				output.uv = input.uv;
				return output;
			}
			fragment OutputFS frag(constant Globals& glob [[ buffer(0) ]], METAL_BUFFER_INPUT(ColorInput, 1, _ColorBuffer),
				METAL_TEX_INPUT(texture2d<half, access::sample>, 0, _MainTex),
				OutputVP input [[ stage_in ]])
			{
				METAL_BUFFER_INPUT_DATA(ColorInput, _ColorBuffer)

				OutputFS output;
				output.color.rgb = glob._Color.rgb * (half3)_ColorBuffer[0].color.xyz * _MainTex.sample(sampler__MainTex, input.uv).xyz;
				output.color.a = 1;
				return output;
			}
			ENDMETAL
		}
	}
}
