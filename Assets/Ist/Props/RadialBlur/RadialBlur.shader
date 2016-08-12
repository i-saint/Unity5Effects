// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Ist/RadialBlur" {
CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"
#include "Assets/Ist/Foundation/Shaders/BuiltinVariablesExt.cginc"

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
#define _AttenuationPow     _Params1.y
#define _Reverse            _Params1.z

float4 _Scale;
float4 _OffsetCenter;
half4 _ColorBias;
half4 _BloomThreshold;
half4 _BloomIntensity;


struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
};
struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 center : TEXCOORD1;
    float4 world_pos : TEXCOORD2;
    float4 obj_pos : TEXCOORD3;
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
    O.center = ComputeScreenPos(mul(UNITY_MATRIX_VP, float4(GetObjectPosition() + _OffsetCenter.xyz, 1)));

    O.world_pos = mul(unity_ObjectToWorld, I.vertex);
    O.obj_pos = float4(GetObjectPosition(), 1);
    return O;
}


ps_out frag (vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float2 center = I.center.xy / I.center.w;
    float opacity = 1.0;

    float3 hit = IntersectionEyeViewPlane(I.world_pos.xyz, I.obj_pos.xyz);
    float dist = length((hit - I.obj_pos.xyz) / _Scale.xyz);
    opacity = saturate(1 - dist * 2);
    //if (opacity <= 0) { discard; }
    opacity = pow(opacity, _AttenuationPow);
    opacity = lerp(opacity, 1 - opacity, _Reverse);

    float2 dir = normalize(coord - center);
    float step = length(coord - center)*_Radius / ITERATION;

    float4 color = 0.0;
    float blend_rate = 0.0;
    for (int k = 0; k<ITERATION; ++k) {
        float r = 1.0 - (1.0 / ITERATION * k);
        blend_rate += r;
        float4 c = tex2D(_FrameBuffer_RadialBlur, coord - dir*(step*k));
        color.rgb += c.rgb * r;
        color.rgb += (max(c.rgb - _BloomThreshold.rgb, 0) * _BloomIntensity.rgb) * r;
    }
    color.rgb /= blend_rate;

    ps_out O;
    O.color.rgb = color.rgb * _ColorBias.rgb;
    O.color.a = opacity;

#if ENABLE_DEBUG
    O.color.rgb = opacity;
    O.color.a = 1;
#endif
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
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
        #pragma multi_compile ___ ENABLE_DEBUG
        ENDCG
    }
}
}
