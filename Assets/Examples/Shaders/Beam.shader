Shader "Examples/Beam"
{
Properties {
    _Color ("Color", Color) = (0,0,0)
    _ColorToMultiply ("Color To Multiply", Vector) = (1,1,1,1)
}

SubShader
{
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }

CGINCLUDE

float4 _Color;
float4 _ColorToMultiply;
float4 _BeamDirection; // xyz: direction w: length

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
};

struct ps_out
{
    float4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    float3 pos1 = mul(_Object2World, v.vertex).xyz;
    float3 pos2 = pos1 + _BeamDirection.xyz * _BeamDirection.w;
    float3 n = normalize(mul(_Object2World, float4(v.normal.xyz,0.0)).xyz);
    float3 pos = dot(-_BeamDirection.xyz, n.xyz)>0.0 ? pos1 : pos2;

    vs_out o;
    o.vertex = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    return o;
}

ps_out frag(vs_out i)
{
    ps_out r;
    r.color = _Color * _ColorToMultiply;
    return r;
}
ENDCG

    Pass {
        Cull Back
        ZTest LEqual
        ZWrite Off

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
