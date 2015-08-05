Shader "Ist/RadialBlurField" {
Properties {
    _Radius("Radius", Float) = 0.5
    _AttenuationBias("Attenuation Bias", Float) = 0.0
    _AttenuationPow("Attenuation Pow", Float) = 2.0
    _Reverse("Reverse", Float) = 0
    _ColorBias("Color Bias", Color) = (1,1,1,1)
}

CGINCLUDE
#include "UnityCG.cginc"

#define ITERATION 32

sampler2D _FrameBuffer1;
float _Radius;
float _AttenuationBias;
float _AttenuationPow;
float _Reverse;
half4 _ColorBias;

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
    O.center = ComputeScreenPos(mul(UNITY_MATRIX_VP, float4(GetObjectPosition(), 1)));
    O.normal = normalize(mul(_Object2World, float4(-I.normal.xyz, 0)).xyz);
    return O;
}
    
ps_out frag (vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float2 center = I.center.xy / I.center.w;
    float3 eye = normalize(I.world_pos.xyz - _WorldSpaceCameraPos.xyz);
    float opacity = abs(dot(eye, I.normal));
    opacity = lerp(opacity, 1-opacity, _Reverse);
    opacity = pow(saturate(opacity + _AttenuationBias), _AttenuationPow);


    float2 dir = normalize(coord - center);
    float step = length(coord - center)*_Radius / ITERATION;

    float4 ref_color = tex2D(_FrameBuffer1, coord);
    float4 color = 0.0;
    float blend_rate = 0.0;
    for (int k = 0; k<ITERATION; ++k) {
        float r = 1.0 - (1.0 / ITERATION * k);
        blend_rate += r;
        color.rgb += tex2D(_FrameBuffer1, coord - dir*(step*k)).rgb * r;
    }
    color.rgb /= blend_rate;


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
    Fog { Mode off }
    Cull Front
    ZTest Off
    ZWrite Off
    Blend SrcAlpha OneMinusSrcAlpha

    GrabPass {
        "_FrameBuffer1"
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
