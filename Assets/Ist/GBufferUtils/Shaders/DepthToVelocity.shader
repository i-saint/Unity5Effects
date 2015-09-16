Shader "Hidden/Ist/GbufferUtils/DepthToVelocity" {
CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};



vs_out vert(ia_out I)
{
    vs_out O;
    O.vertex = O.screen_pos = I.vertex;
#if UNITY_UV_STARTS_AT_TOP
    O.screen_pos.y *= -1.0;
#endif
    return O;
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#if SHADER_API_D3D9
    #define UVOffset ((_ScreenParams.zw-1.0)*0.5)
#else
    #define UVOffset 0.0
#endif

half4 frag(vs_out I) : SV_Target
{
    float2 spos = I.screen_pos.xy / I.screen_pos.w;
    float2 uv = spos * 0.5 + 0.5 + UVOffset;

    float depth = GetDepth(uv);
    if (depth >= 1.0) { return 0.0; }
    float3 p = GetPosition(spos, depth);

    float4 ppos4 = mul(_PrevViewProj, float4(p.xyz, 1.0));
    float2 pspos = ppos4.xy / ppos4.w;
    float2 prev_uv = pspos * 0.5 + 0.5 + UVOffset;
    float  prev_depth = GetPrevDepth(prev_uv);

    return half4(
        uv-prev_uv,
        length(p - GetPrevPosition(pspos, prev_depth)),
        length(p - GetPrevPosition(spos, depth)));
}
ENDCG


SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
