Shader "GBufferUtils/GBufferCopy" {
CGINCLUDE
sampler2D _CameraGBufferTexture0;   // diffuse color (rgb), occlusion (a)
sampler2D _CameraGBufferTexture1;   // spec color (rgb), smoothness (a)
sampler2D _CameraGBufferTexture2;   // normal (rgb), --unused, very low precision-- (a) 
sampler2D _CameraGBufferTexture3;   // emission (rgb), --unused-- (a)
sampler2D_float _CameraDepthTexture;

struct ia_out
{
    float4 vertex : POSITION;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 spos : TEXCOORD0;
};

struct ps_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
    float depth             : SV_Target4;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.spos = o.vertex;
    return o;
}

ps_out frag(vs_out v)
{
#if UNITY_UV_STARTS_AT_TOP
    v.spos.y *= -1.0;
#endif
    float2 tc = v.spos * 0.5 + 0.5;

    ps_out o;
    o.diffuse           = tex2D(_CameraGBufferTexture0, tc);
    o.spec_smoothness   = tex2D(_CameraGBufferTexture1, tc);
    o.normal            = tex2D(_CameraGBufferTexture2, tc);

    half3 emission = tex2D(_CameraGBufferTexture3, tc).xyz;
#ifdef UNITY_HDR_ON
    o.emission          = float4(emission, 1.0);
#else
    o.emission          = exp2(float4(-emission, 1.0));
#endif

    o.depth             = tex2D(_CameraDepthTexture, tc).x;
    return o;
}
ENDCG

SubShader {
    Cull Off

    Pass {
CGPROGRAM
#pragma multi_compile ___ UNITY_HDR_ON

#pragma vertex vert
#pragma fragment frag
ENDCG
    }
}
Fallback Off
}
