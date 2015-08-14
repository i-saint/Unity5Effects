Shader "Hidden/Ist/RimLight" {
Properties{
    _MainTex("Base (RGB)", 2D) = "" {}
}
SubShader{
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

sampler2D _MainTex;
float4 _Color;
float4 _Params1;
float4 _Params2;
#define _Intensity      _Params1.w
#define _FresnelBias    _Params1.x
#define _FresnelScale   _Params1.y
#define _FresnelPow     _Params1.z
#define _EdgeIntensity  _Params2.x
#define _EdgeThreshold  _Params2.y
#define _EdgeRadius     _Params2.z


struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};

struct ps_out
{
    half4 color : SV_Target;
};


vs_out vert (ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}


#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy / i.screen_pos.w;

    float depth = GetDepth(coord);
    if (depth >= 1.0) {
        ps_out r;
        r.color = tex2D(_MainTex, coord);
        return r;
    }

    float3 p = GetPosition(coord).xyz;
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos.xyz);
    float3 n1 = GetNormal(coord).xyz;
    float h = saturate(_FresnelBias + pow(dot(cam_dir, n1) + 1.0, _FresnelPow) * _FresnelScale) * _Intensity;

#if ENABLE_EDGE_HIGHLIGHTING
    float2 pixel_size = (_ScreenParams.zw - 1.0) * _EdgeRadius;
    float3 n2 = GetNormal(coord + float2(pixel_size.x, 0.0)).xyz;
    float3 n3 = GetNormal(coord + float2(0.0, pixel_size.y)).xyz;

    //if (dot(n1, n2)<_EdgeThreshold || dot(n1, n3)<_EdgeThreshold) {
    //    h += _EdgeIntensity;
    //}
    // equivalent to above code. this if more faster in some cases.
    float t1 = dot(n1, n2) - _EdgeThreshold;
    float t2 = dot(n1, n3) - _EdgeThreshold;
    float t = clamp(min(min(t1, t2), 0.0) * -100000.0, 0.0, 1.0);
    h += _EdgeIntensity * t;
#endif

#if ENABLE_SMOOTHNESS_ATTENUAION
    h *= GetSpecular(coord).w;
#endif

    ps_out r;
    r.color = tex2D(_MainTex, coord) + _Color * h;
    return r;
}
ENDCG

    Pass {
        CGPROGRAM
        #pragma multi_compile ___ ENABLE_EDGE_HIGHLIGHTING
        #pragma multi_compile ___ ENABLE_SMOOTHNESS_ATTENUAION
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
