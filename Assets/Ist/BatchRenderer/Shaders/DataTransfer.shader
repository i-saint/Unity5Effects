Shader "BatchRenderer/DataTransfer" {

SubShader {
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE

struct ia_out
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 data : TEXCOORD0;
};

struct ps_out
{
    float4 color : SV_Target;
};

int g_begin;
float4 g_texel;

float4 InstanceIDToScreenPosition(float id)
{
    id += g_begin;
    float xi = fmod(id, g_texel.z);
    float yi = floor(id / g_texel.z);
    float2 pixel_size = g_texel.xy * 2.0;
    float2 pos = pixel_size * (float2(xi, yi) + 0.5) - 1.0;
#if UNITY_UV_STARTS_AT_TOP
    pos.y *= -1.0;
#endif
    return float4(pos, 0.0, 1.0);
}

vs_out vert(ia_out io)
{
    vs_out o;
    o.vertex = InstanceIDToScreenPosition(io.uv.x);
    o.data = float4(io.vertex.xyz, io.uv.y);
    return o;
}

ps_out frag(vs_out vo)
{
    ps_out po = { vo.data };
    return po;
}
ENDCG

    Pass {
        CGPROGRAM
        #ifdef SHADER_API_OPENGL
            #pragma glsl
        #endif
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}

}
