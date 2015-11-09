#ifndef Trail_h
#define Trail_h

#include "UnityCG.cginc"
#define MPGP_FOR_DRAW
#include "MPGPFoundation.cginc"

fixed4 _BaseColor;
float  _FadeTime;
int     g_batch_begin;
float   g_width;
StructuredBuffer<Particle> particles;
StructuredBuffer<TrailParams> params;
StructuredBuffer<TrailVertex> vertices;

struct ia_out {
    float4 vertex : POSITION;
};

struct vs_out {
    float4 vertex : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float4 color : TEXCOORD01;
};

struct ps_out
{
    float4 color : COLOR0;
};


vs_out vert(ia_out io)
{
    uint vertex_id = io.vertex.x;
    uint instance_id = g_batch_begin + io.vertex.y;

    float lifetime = particles[instance_id].lifetime;
    float fade = min(lifetime/_FadeTime, 1.0);

    float4 vp = 0.0;
    float2 tc = 0.0;
    if(lifetime > 0.0) {
        uint ii = (particles[instance_id].id % params[0].max_entities) * params[0].max_history;
        TrailVertex tv = vertices[ii + vertex_id/2];

        float3 pos = tv.position;
        float3 tangent = tv.tangent;
        float3 aim_camera = normalize(_WorldSpaceCameraPos-pos);
        float3 distance = cross(tangent, aim_camera) * (g_width*0.5f);

        // right if vertex_id%2==0. otherwise left 
        float rl = 1.0 - 2.0*(vertex_id & 1);
        pos += distance * rl;

        vp = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
        tc = tv.texcoord;
        tc.x = rl*0.5 + 0.5;
    }

    vs_out o;
    o.vertex = vp;
    o.texcoord = tc;
    o.color = _BaseColor * fade;

    return o;
}

ps_out frag(vs_out vo)
{
    ps_out o;
    float ua = pow( 1.0 - abs(vo.texcoord.x*2.0f-1.0f)+0.0001, 0.5 );
    float va = pow((vo.texcoord.y+0.0001), 0.5);
    float a = ua * va;
    o.color = vo.color;
    o.color.a *= a;
    return o;
}

#endif // Trail_h
