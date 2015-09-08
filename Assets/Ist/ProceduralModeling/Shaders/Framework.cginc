
#ifndef MAP_NORMAL
#   define MAP_NORMAL map
#endif


float3 guess_normal(float3 p)
{
    const float d = 0.001;
    return normalize(float3(
        MAP_NORMAL(p + float3(d, 0.0, 0.0)) - MAP_NORMAL(p + float3(-d, 0.0, 0.0)),
        MAP_NORMAL(p + float3(0.0, d, 0.0)) - MAP_NORMAL(p + float3(0.0, -d, 0.0)),
        MAP_NORMAL(p + float3(0.0, 0.0, d)) - MAP_NORMAL(p + float3(0.0, 0.0, -d))));
}

void raymarching(inout raymarch_data rmd)
{
    float3 ray_dir = normalize(rmd.ray_pos - GetCameraPosition());

    float prev = 0.0;
    for (int i = 0; i<MAX_MARCH_STEPS; ++i) {
        prev = rmd.last_distance;
        rmd.last_distance = map(rmd.ray_pos);
        rmd.total_distance += rmd.last_distance;
        rmd.ray_pos += ray_dir * rmd.last_distance;
        rmd.num_steps += 1.0;
        if (rmd.last_distance < 0.001) { break; }
    }

#if ENABLE_TRACEBACK
    if (rmd.last_distance == 0.0) {
        float step = -prev / MAX_TRACEBACK_STEPS;
        for (int i = 0; i<MAX_TRACEBACK_STEPS; ++i) {
            rmd.total_distance += step;
            rmd.ray_pos += ray_dir * step;
            rmd.last_distance = map(rmd.ray_pos);
            if (rmd.last_distance > 0) { break; }
        }
    }
#endif // ENABLE_TRACEBACK


    if (_Clipping == 1) {
        float3 pl = localize(rmd.ray_pos);
        float d = sdBox(pl, _Scale*0.5);
        if (d > _CutoutDistance) { discard; }
    }
    else if (_Clipping == 2) {
        float3 pl = localize(rmd.ray_pos);
        float d = sdSphere(pl, _Scale.x*0.5);
        if (d > _CutoutDistance) { discard; }
    }
}



gbuffer_out frag_gbuffer(vs_out I)
{
    float2 coord = I.screen_pos.xy / I.screen_pos.w;
    float3 world_pos = I.world_pos.xyz;

    raymarch_data rmd;
    UNITY_INITIALIZE_OUTPUT(raymarch_data,rmd);
    rmd.ray_pos = world_pos;

    initialize(rmd);

    raymarching(rmd);
    float3 normal = I.world_normal;
    //float3 d1 = ddx(world_pos);
    //float3 d2 = ddy(world_pos);
    //normal = normalize(cross(d2, d1));
    if (rmd.total_distance > 0.0) {
        normal = guess_normal(rmd.ray_pos);
    }

    gbuffer_out O;
    O.diffuse = float4(_Color.rgb, 1.0);
    O.spec_smoothness = float4(_SpecularColor.rgb, _Smoothness);
    O.normal = float4(normal*0.5 + 0.5, 1.0);
    O.emission = float4(_EmissionColor.rgb, 1.0);
#if ENABLE_DEPTH_OUTPUT
    O.depth = ComputeDepth(mul(UNITY_MATRIX_VP, float4(rmd.ray_pos, 1.0)));
#endif

    posteffect(O, I, rmd);

#ifndef UNITY_HDR_ON
    O.emission = exp2(-O.emission);
#endif
    return O;
}


struct v2f_shadow {
    float4 pos : SV_POSITION;
    LIGHTING_COORDS(0, 1)
};

v2f_shadow vert_shadow(appdata_full I)
{
    v2f_shadow O;
    O.pos = mul(UNITY_MATRIX_MVP, I.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(O);
    return O;
}

half4 frag_shadow(v2f_shadow IN) : SV_Target
{
    return 0.0;
}

