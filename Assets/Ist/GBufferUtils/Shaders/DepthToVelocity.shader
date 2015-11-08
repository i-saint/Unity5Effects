Shader "Hidden/Ist/GbufferUtils/DepthToVelocity" {
CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

#define ENABLE_DISCONTINUITY 1

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


struct ps_out
{
    half4 velocity : SV_Target0;
#if ENABLE_DISCONTINUITY
    half4 discontinuity : SV_Target1;
#endif
};

half GetDefference(float z, half3 n, float2 uv)
{
    float nz = GetDepth(uv);
    float3 np = GetPosition(uv*2.0-1.0, nz);
    half3 nn = -normalize(cross(ddx(np), ddy(np)));

    half2 ndiff = abs(n.xy - nn.xy);
    half  sn = (ndiff.x + ndiff.y);

    float zdiff = abs(abs(z - nz) * _ProjectionParams.z);
    half  sz = zdiff * 0.1;

    return max(sn, sz);
}

half4 GetDiscontinuity(float2 uv, float z, half3 n)
{
    float2 texel_size = (_ScreenParams.zw - 1.0) * 1.0;

    return 1.0-half4(
        GetDefference(z, n, uv + float2( texel_size.x, 0.0)), // right
        GetDefference(z, n, uv + float2(-texel_size.x, 0.0)), // left
        GetDefference(z, n, uv + float2(0.0,  texel_size.y)), // up
        GetDefference(z, n, uv + float2(0.0, -texel_size.y))  // down
    );
}

ps_out frag(vs_out I)
{
    ps_out O;
    UNITY_INITIALIZE_OUTPUT(ps_out, O);

    float2 spos = I.screen_pos.xy / I.screen_pos.w;
    float2 uv = spos * 0.5 + 0.5 + UVOffset;

    float depth = GetDepth(uv);
    if (depth >= 1.0) { return O; }
    float3 p = GetPosition(spos, depth);

    float4 ppos4 = mul(_PrevViewProj, float4(p.xyz, 1.0));
    float2 pspos = ppos4.xy / ppos4.w;
    float2 prev_uv = pspos * 0.5 + 0.5 + UVOffset;
    float  prev_depth = GetPrevDepth(prev_uv);

    O.velocity = half4(
        uv - prev_uv,
        length(p - GetPrevPosition(pspos, prev_depth)),
        length(p - GetPrevPosition(spos, depth)));

#if ENABLE_DISCONTINUITY
    half3 n = -normalize(cross(ddx(p), ddy(p)));
    O.discontinuity = GetDiscontinuity(uv, depth, n);
#endif
    return O;
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
