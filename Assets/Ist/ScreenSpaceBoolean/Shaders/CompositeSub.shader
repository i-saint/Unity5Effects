Shader "Hidden/Ist/Boolean/SubComposite"
{

SubShader
{
CGINCLUDE
sampler2D _TmpDepth;
sampler2D _BackDepth;

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
    float depth : SV_Depth;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = v.vertex;
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy * 0.5 + 0.5;
    ps_out r;
    r.color = r.depth = tex2D(_TmpDepth, coord).x;
    if(r.depth==0.0) { discard; }
    return r;
}
ENDCG

    Pass {
        Cull Off
        ZTest LEqual
        ZWrite On
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }

}
}
