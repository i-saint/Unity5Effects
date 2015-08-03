Shader "Ist/ZPrePass" {
CGINCLUDE
struct ia_out
{
    float4 vertex : POSITION;
};
struct vs_out
{
    float4 vertex : SV_POSITION;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}

half4 frag(vs_out v) : SV_Target
{
    return 0;
}
ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "Queue" = "Geometry-100" }

    Pass{
        Tags{ "LightMode" = "Deferred" }
        Cull Back
        ColorMask 0

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
ENDCG
    }
}

Fallback Off
}
