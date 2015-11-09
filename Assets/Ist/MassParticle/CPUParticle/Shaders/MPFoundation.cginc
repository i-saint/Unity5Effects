#ifndef MPFoundation_h
#define MPFoundation_h

#include "Assets/Ist/Foundation/Shaders/Math.cginc"

int         g_batch_begin;
int         g_num_max_instances;
int         g_num_instances;
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

// o_pos: w=ID
// o_params: y=lifetime, z=fade scale
void ParticleTransform(inout appdata_full v, out float4 o_pos, out float4 o_vel, out float4 o_params)
{
    int iid = v.texcoord1.x + g_batch_begin;
    if (iid >= g_num_instances) {
        v.vertex.xyz *= 0.0;
        return;
    }
    GetParticleParams(iid, o_pos, o_vel, o_params);
    float lifetime = o_params.y;
    float fade = min(1.0, lifetime / g_fade_time);
    o_params.z = fade;

    v.vertex.xyz *= g_size;
    v.vertex.xyz *= fade;
    v.vertex.xyz *= saturate(lifetime * 10000000); // 0 if dead
#ifdef MP_ENABLE_SPIN
    if(g_spin != 0.0) {
        float ang = (dot(o_pos.xyz, 1.0) * min(1.0, o_vel.w*0.02)) * g_spin;
        float3x3 rot = RotateAxis33(normalize(iq_rand(o_pos.www)), ang);
        v.vertex.xyz = mul(rot, v.vertex.xyz);
        v.normal.xyz = mul(rot, v.normal.xyz);
    }
#endif // MP_ENABLE_SPIN
    v.vertex.xyz += o_pos.xyz;
}


#endif // MPFoundation_h
