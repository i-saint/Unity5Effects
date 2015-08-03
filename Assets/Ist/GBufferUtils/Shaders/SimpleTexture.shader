Shader "Ist/GbufferUtils/SimpleTexture"
{
Properties {
    _MainTex("Color", 2D) = "white" {}
    _ColorToAdd ("Color To Add", Color) = (0,0,0)
    _ColorToMultiply ("Color To Multiply", Color) = (1,1,1)
}

SubShader
{
CGINCLUDE

sampler2D _MainTex;
float4 _ColorToAdd;
float4 _ColorToMultiply;

struct ia_out
{
    float4 vertex : POSITION;
    float4 texcoord : TEXCOORD0;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 texcoord : TEXCOORD0;
};

struct ps_out
{
    float4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.texcoord = v.texcoord;
    return o;
}

ps_out frag(vs_out i)
{
    ps_out r;
    r.color = tex2D(_MainTex, i.texcoord) * _ColorToMultiply + _ColorToAdd;
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
