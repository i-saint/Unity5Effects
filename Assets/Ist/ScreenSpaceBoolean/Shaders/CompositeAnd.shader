Shader "Hidden/Ist/Boolean/AndComposite"
{

SubShader
{
CGINCLUDE
sampler2D _BackDepth;
sampler2D _BackDepth2;
sampler2D _FrontDepth;
sampler2D _FrontDepth2;

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

    float fd1 = tex2D(_FrontDepth, coord).x;
    float fd2 = tex2D(_FrontDepth2, coord).x;
    float bd1 = tex2D(_BackDepth, coord).x;
    float bd2 = tex2D(_BackDepth2, coord).x;
    if(bd2 < fd1 || bd1 < fd2) { discard; }

    ps_out r;
    r.color = r.depth = max(fd1, fd2);
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
