Shader "Hidden/Ist/ZFog" {
Properties{
    _MainTex("Base (RGB)", 2D) = "" {}
}
SubShader{
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/Math.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/Geometry.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/BuiltinVariablesExt.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

sampler2D _MainTex;
float4 _Color1;
float4 _Color2;
float4 _Params1;
float4 _Params2;
#define _Near1  _Params1.x
#define _Far1   _Params1.y
#define _Pow1   _Params1.z
#define _Near2  _Params2.x
#define _Far2   _Params2.y
#define _Pow2   _Params2.z


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

ps_out frag(vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;

    float depth = GetDepth(coord);

    float3 p = GetPosition(coord).xyz;
    float3 cam_dir = -GetCameraForward();
    Plane plane = { cam_dir , -dot(cam_dir, _WorldSpaceCameraPos.xyz) };
    float d = DistancePointPlane(p, plane);

    float fog1 = pow(saturate((d - _Near1) / (_Far1 - _Near1)), _Pow1);
    float fog2 = pow(saturate((d - _Near2) / (_Far2 - _Near2)), _Pow2);
    float4 r = tex2D(_MainTex, coord);
    r.rgb = lerp(r.rgb, _Color1.rgb, fog1*_Color1.a);
    r.rgb = lerp(r.rgb, _Color2.rgb, fog2*_Color2.a);

    ps_out O;
    O.color = r;
    return O;
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
