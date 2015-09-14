Shader "Hidden/Ist/GbufferUtils/GBufferCopy" {
CGINCLUDE
#include "UnityCG.cginc"

sampler2D _CameraGBufferTexture0;   // diffuse color (rgb), occlusion (a)
sampler2D _CameraGBufferTexture1;   // spec color (rgb), smoothness (a)
sampler2D _CameraGBufferTexture2;   // normal (rgb), --unused, very low precision-- (a) 
sampler2D _CameraGBufferTexture3;   // emission (rgb), --unused-- (a)
sampler2D_float _CameraDepthTexture;

struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};

struct ps_out_gbuffer
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
    float depth             : SV_Depth;
};
struct ps_out_depth
{
    float4 depth             : SV_Target0;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.screen_pos = v.vertex;
#if UNITY_UV_STARTS_AT_TOP
    o.screen_pos.y *= -1.0;
#endif
    return o;
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#if SHADER_API_D3D9
    #define UVOffset ((_ScreenParams.zw-1.0)*0.5)
#else
    #define UVOffset 0.0
#endif

ps_out_gbuffer frag_gbuffer(vs_out v)
{
    float2 tc = v.screen_pos * 0.5 + 0.5 + UVOffset;

    ps_out_gbuffer o;
    o.diffuse           = tex2D(_CameraGBufferTexture0, tc);
    o.spec_smoothness   = tex2D(_CameraGBufferTexture1, tc);
    o.normal            = tex2D(_CameraGBufferTexture2, tc);
    o.emission          = tex2D(_CameraGBufferTexture3, tc);
    o.depth             = tex2D(_CameraDepthTexture,    tc).x;
    return o;
}

ps_out_depth frag_depth(vs_out v)
{
    float2 tc = v.screen_pos * 0.5 + 0.5 + UVOffset;

    ps_out_depth o;
    o.depth = tex2D(_CameraDepthTexture, tc).x;
    return o;
}
ENDCG


SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite On
    Cull Off

    // gbuffer & depth
    Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_gbuffer
ENDCG
    }

    // depth only
    Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag_depth
ENDCG
    }
}
}
