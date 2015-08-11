
float4 _SpecularColor;
float _Smoothness;
float _CutoutDistance;


struct ia_out
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 world_pos : TEXCOORD1;
    float3 world_normal: TEXCOORD2;
};


vs_out vert(ia_out I)
{
    vs_out O;
    O.vertex = mul(UNITY_MATRIX_MVP, I.vertex);
    O.screen_pos = ComputeScreenPos(O.vertex);
    O.world_pos = mul(_Object2World, I.vertex);
    O.world_normal = mul(_Object2World, float4(I.normal, 0.0));
    return O;
}


float3 guess_normal(float3 p)
{
    const float d = 0.001;
    return normalize(float3(
        map(p + float3(d, 0.0, 0.0)) - map(p + float3(-d, 0.0, 0.0)),
        map(p + float3(0.0, d, 0.0)) - map(p + float3(0.0, -d, 0.0)),
        map(p + float3(0.0, 0.0, d)) - map(p + float3(0.0, 0.0, -d))));
}

void raymarching(float3 pos3, const int num_steps, inout float o_total_distance, out float o_num_steps, out float o_last_distance, out float3 o_raypos)
{
    float3 ray_dir = normalize(pos3 - GetCameraPosition());
    float3 ray_pos = pos3 + ray_dir * o_total_distance;

    o_num_steps = 0.0;
    o_last_distance = 0.0;
    float prev = 0.0;
    for (int i = 0; i<num_steps; ++i) {
        prev = o_last_distance;
        o_last_distance = map(ray_pos);
        o_total_distance += o_last_distance;
        ray_pos += ray_dir * o_last_distance;
        o_num_steps += 1.0;
        if (o_last_distance < 0.001) { break; }
    }

#if ENABLE_TRACEBACK
    if (o_last_distance == 0.0) {
        float step = -prev / MAX_TRACEBACK_STEPS;
        for (int i = 0; i<MAX_TRACEBACK_STEPS; ++i) {
            o_last_distance = map(ray_pos);
            o_total_distance += step;
            ray_pos += ray_dir * step;
            if (o_last_distance > 0) { break; }
        }
    }
#endif // ENABLE_TRACEBACK


    o_raypos = pos3 + ray_dir * o_total_distance;


#if ENABLE_BOX_CLIPPING
    {
        float3 pl = localize(o_raypos);
        float d = sdBox(pl, _Scale*0.5);
        if (d > _CutoutDistance) { discard; }
    }
#endif
#if ENABLE_SPHERE_CLIPPING
    {
        float3 pl = localize(o_raypos);
        float d = sdSphere(pl, _Scale.x*0.5);
        if (d > _CutoutDistance) { discard; }
    }
#endif
}



struct gbuffer_out
{
    half4 diffuse           : SV_Target0; // RT0: diffuse color (rgb), occlusion (a)
    half4 spec_smoothness   : SV_Target1; // RT1: spec color (rgb), smoothness (a)
    half4 normal            : SV_Target2; // RT2: normal (rgb), --unused, very low precision-- (a) 
    half4 emission          : SV_Target3; // RT3: emission (rgb), --unused-- (a)
#if ENABLE_DEPTH_OUTPUT
    float depth :
    #if SHADER_TARGET >= 50
        SV_DepthGreaterEqual;
    #else
        SV_Depth;
    #endif

#endif
};

gbuffer_out frag_gbuffer(vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float3 world_pos = I.world_pos.xyz;

    float num_steps = 1.0;
    float last_distance = 0.0;
    float total_distance = 0;
    float3 ray_pos = world_pos;
    raymarching(world_pos, MAX_MARCH_STEPS, total_distance, num_steps, last_distance, ray_pos);
    float3 normal = I.world_normal;
    if (total_distance > 0.0) {
        normal = guess_normal(ray_pos);
    }


    gbuffer_out o;
    o.diffuse = float4(_Color.rgb, 1.0);
    o.spec_smoothness = float4(_SpecularColor.rgb, _Smoothness);
    o.normal = float4(normal*0.5 + 0.5, 1.0);
    o.emission = float4(_EmissionColor.rgb, 1.0);

#ifndef UNITY_HDR_ON
    o.emission = exp2(-o.emission);
#endif

#if ENABLE_DEPTH_OUTPUT
    o.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0)));
#endif
    return o;
}


struct v2f_shadow {
    float4 pos : SV_POSITION;
    LIGHTING_COORDS(0, 1)
};

v2f_shadow vert_shadow(appdata_full I)
{
    v2f_shadow o;
    o.pos = mul(UNITY_MATRIX_MVP, I.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

half4 frag_shadow(v2f_shadow IN) : SV_Target
{
    return 0.0;
}

