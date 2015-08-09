Shader "Ist/RadialBlur" {

CGINCLUDE
#include "UnityCG.cginc"

#if QUALITY_FAST
    #define ITERATION 16
#elif QUALITY_HIGH
    #define ITERATION 48
#else // QUALITY_MEDIUM
    #define ITERATION 32
#endif

sampler2D _FrameBuffer_RadialBlur;
float4 _Params1;

#define _Radius             _Params1.x
#define _AttenuationBias    _Params1.y
#define _AttenuationPow     _Params1.z
#define _Reverse            _Params1.w

float4 _OffsetCenter;
half4 _ColorBias;
half4 _BloomThreshold;
half4 _BloomIntensity;

float3 GetObjectPosition()
{
    return float3(_Object2World[0][3], _Object2World[1][3], _Object2World[2][3]);
}

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
};
struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 world_pos : TEXCOORD1;
    float4 center : TEXCOORD2;
    float3 normal : TEXCOORD3;
};
struct ps_out
{
    half4 color : SV_Target;
};

vs_out vert (ia_out I)
{
    vs_out O;
    O.vertex = mul(UNITY_MATRIX_MVP, I.vertex);
    O.screen_pos = ComputeScreenPos(O.vertex);
    O.world_pos = mul(_Object2World, I.vertex);
    O.center = ComputeScreenPos(mul(UNITY_MATRIX_VP, float4(GetObjectPosition() + _OffsetCenter.xyz, 1)));
    O.normal = normalize(mul(_Object2World, float4(-I.normal.xyz, 0)).xyz);
    return O;
}
    
ps_out frag (vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float2 center = I.center.xy / I.center.w;
    float3 eye = normalize(I.world_pos.xyz - _WorldSpaceCameraPos.xyz);
    float opacity = 1;
#if ENABLE_ATTENUATION
    opacity = abs(dot(eye, I.normal));
    opacity = lerp(opacity, 1-opacity, _Reverse);
    opacity = pow(saturate(opacity + _AttenuationBias), _AttenuationPow);
#endif


    float2 dir = normalize(coord - center);
    float step = length(coord - center)*_Radius / ITERATION;

    float4 color = 0.0;
    float blend_rate = 0.0;
    for (int k = 0; k<ITERATION; ++k) {
        float r = 1.0 - (1.0 / ITERATION * k);
        blend_rate += r;
        float4 c = tex2D(_FrameBuffer_RadialBlur, coord - dir*(step*k));
#if ENABLE_BLUR
        color.rgb += c.rgb * r;
#endif
#if ENABLE_BLOOM
        color.rgb += (max(c.rgb - _BloomThreshold.rgb, 0) * _BloomIntensity.rgb) * r;
#endif
    }
    color.rgb /= blend_rate;
#if ENABLE_BLUR
#else
    color += tex2D(_FrameBuffer_RadialBlur, coord);
#endif


    ps_out O;
    O.color.rgb = color.rgb * _ColorBias.rgb;
    O.color.a = opacity;

    //O.color = opacity;
    //O.color.a = 1;
    return O;
}
ENDCG

Subshader {
    Tags { "Queue"="Overlay+90" "RenderType"="Opaque" }
    Cull Front
    ZTest Off
    ZWrite Off
    Blend SrcAlpha OneMinusSrcAlpha

    GrabPass {
        "_FrameBuffer_RadialBlur"
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
        #pragma multi_compile ___ ENABLE_ATTENUATION
        #pragma multi_compile ___ ENABLE_BLUR
        #pragma multi_compile ___ ENABLE_BLOOM
        ENDCG
    }
}
}
