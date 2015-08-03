#ifndef MPFoundation_h
#define MPFoundation_h

#include "Assets/Ist/BatchRenderer/Shaders/Math.cginc"

int         g_batch_begin;
sampler2D   g_instance_data;
float       g_size;
float       g_fade_time;
float       g_spin;
float4      g_instance_data_size;


float3 iq_rand( float3 p )
{
    p = float3( dot(p,float3(127.1,311.7,311.7)), dot(p,float3(269.5,183.3,183.3)), dot(p,float3(269.5,183.3,183.3)) );
    return frac(sin(p)*43758.5453)*2.0-1.0;
}


// o_pos: w=ID
// o_params: y=lifetime
void GetParticleParams(int iid, out float4 o_pos, out float4 o_vel, out float4 o_params)
{
    float i = iid*3;
    float4 t = float4(
        g_instance_data_size.xy * float2(fmod(i, g_instance_data_size.z) + 0.5, floor(i/g_instance_data_size.z) + 0.5),
        0.0, 0.0);
    float4 pitch = float4(g_instance_data_size.x, 0.0, 0.0, 0.0);
    o_pos   = tex2Dlod(g_instance_data, t + pitch*0.0);
    o_vel   = tex2Dlod(g_instance_data, t + pitch*1.0);
    o_params= tex2Dlod(g_instance_data, t + pitch*2.0);
}

void ParticleTransform(inout appdata_full v, out float4 pos, out float4 vel, out float4 params)
{
    int iid = v.texcoord1.x + g_batch_begin;
    GetParticleParams(iid, pos, vel, params);
    float lifetime = params.y;

    v.vertex.xyz *= g_size;
    v.vertex.xyz *= min(1.0, lifetime/g_fade_time);
    if(lifetime<=0.0) {
        v.vertex.xyz = 0.0;
    }
#ifdef MP_ENABLE_SPIN
    if(g_spin != 0.0) {
        float ang = (dot(pos.xyz, 1.0) * min(1.0, vel.w*0.02)) * g_spin;
        float3x3 rot = rotation_matrix33(normalize(iq_rand(pos.www)), ang);
        v.vertex.xyz = mul(rot, v.vertex.xyz);
        v.normal.xyz = mul(rot, v.normal.xyz);
    }
#endif // MP_ENABLE_SPIN
    v.vertex.xyz += pos.xyz;
}


#endif // MPFoundation_h
