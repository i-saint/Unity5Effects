Shader "Ist/DoNothing" {
CGINCLUDE
struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4  vertex : SV_POSITION;
};

struct ps_out
{
    float4  color : SV_Target;
};


vs_out vert(ia_out I)
{
    vs_out O;
    O.vertex = float4(0.0, 0.0, 0.0, 1.0);
    return O;
}

ps_out frag(vs_out I)
{
    ps_out O;
    O.color = 0.0;
    return O;
}
ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
    Cull Off

    Pass {
        Tags { "LightMode" = "Deferred" }
        ColorMask 0
        ZWrite Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
ENDCG
    }
}
}
