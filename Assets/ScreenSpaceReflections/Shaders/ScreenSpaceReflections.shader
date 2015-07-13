Shader "ScreenSpaceReflections/ScreenSpaceReflections" {
Properties {
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "Assets/FrameBufferUtils/Shaders/GBufferUtils.cginc"
sampler2D _FrameBuffer1;
sampler2D _PrevResult;
sampler2D _ReflectionBuffer;
float _Intensity;
float _RayMarchDistance;
float _RayDiffusion;
float _FalloffDistance;
float _MaxAccumulation;

#pragma multi_compile ALGORITHM_SINGLE_PASS ALGORITHM_TEMPORAL
#pragma multi_compile QUALITY_LOW QUALITY_MEDIUM QUALITY_HIGH


 #if QUALITY_LOW
    #define NUM_RAYS 4
    #define MAX_MARCH 8
 #elif QUALITY_MEDIUM
    #define NUM_RAYS 6
    #define MAX_MARCH 16
 #elif QUALITY_HIGH
    #define NUM_RAYS 9
    #define MAX_MARCH 16
 #endif


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
    float4 color : COLOR0;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.screen_pos = v.vertex;
    return o;
}



float jitter(float3 p)
{
    float v = dot(p,1.0)+_Time.y;
    return frac(sin(v)*43758.5453);
}
float3 diverge(float3 p, float d)
{
    p *= _Time.y;
    return (float3(frac(sin(p)*43758.5453))*2.0-1.0) * d;
}



ps_out frag_reflections(vs_out i)
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w) * 0.5 + 0.5;
    // see: http://docs.unity3d.com/Manual/SL-PlatformDifferences.html
    #if UNITY_UV_STARTS_AT_TOP
        coord.y = 1.0-coord.y;
    #endif

#if ALGORITHM_SINGLE_PASS

    float4 p = GetPosition(coord);
    float4 n = GetNormal(coord);
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    ps_out r;
    r.color = 0.0;

    float3 refdir = reflect(cam_dir, n.xyz);
    float s = _Intensity / NUM_RAYS;
    float3 noises[9] = {
        float3(0.0, 0.0, 0.0),
        float3(0.1080925165271518, -0.9546740999616308, -0.5485116160762447),
        float3(-0.4753686437884934, -0.8417212473681748, 0.04781893710693619),
        float3(0.7242715177221273, -0.6574584801064549, -0.7170447827462747),
        float3(-0.023355087558461607, 0.7964400038854089, 0.35384090347421204),
        float3(-0.8308210026544296, -0.7015103725420933, 0.7781031130099072),
        float3(0.3243705688309195, 0.2577797517167695, 0.012345938868925543),
        float3(0.31851240326305463, -0.22207894547397555, 0.42542751740434204),
        float3(-0.36307729185097637, -0.7307245945773899, 0.6834118993358385)
    };
    for(int j=0; j<NUM_RAYS; ++j) {
        float4 tpos = mul(UNITY_MATRIX_MVP, float4(p.xyz+(refdir+noises[j]*0.04)*_RayMarchDistance, 1.0) );
        float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
        #if UNITY_UV_STARTS_AT_TOP
            tcoord.y = 1.0-tcoord.y;
        #endif
        r.color.xyz += tex2D(_FrameBuffer1, tcoord).xyz * s;
    }
    r.color *= n.w;
    //r.color = abs(p * 0.2);
    return r;

 #elif ALGORITHM_TEMPORAL

    ps_out r;
    r.color = 0.0;

    float depth = GetDepth(coord);
    if(depth == 1.0) { return r; }

    float4 p = GetPosition(coord);
    float4 n = GetNormal(coord);
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    float2 prev_coord;
    float4 prev_result;
    float4 prev_pos;
    {
        float4 tpos = mul(_PrevViewProj, float4(p.xyz, 1.0) );
        prev_coord = (tpos.xy / tpos.w) * 0.5 + 0.5;
    #if UNITY_UV_STARTS_AT_TOP
    //	prev_coord.y = 1.0-prev_coord.y;
    #endif
        prev_result = tex2D(_PrevResult, prev_coord);
        //prev_pos = GetPosition(prev_coord);
        prev_pos = GetPrevPosition(coord);
    }

    float accumulation = prev_result.w;
    float diff = length(p.xyz-prev_pos.xyz);
    accumulation *= max(1.0-(0.025+diff*15.0), 0.0);
    float3 blend_color = prev_result.rgb * accumulation;
    float MaxDistance = _RayMarchDistance * MAX_MARCH;

    {
        float2 hit_coord;
        float3 refdir = reflect(cam_dir, n.xyz) + diverge(p, _RayDiffusion);
        float adv = _RayMarchDistance * jitter(p);

        for(int k=0; k<MAX_MARCH; ++k) {
            adv = adv + _RayMarchDistance;
            float4 tpos = mul(UNITY_MATRIX_MVP, float4((p.xyz+refdir*adv), 1.0) );
            float ray_depth = ComputeDepth(tpos);
            float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
            #if UNITY_UV_STARTS_AT_TOP
                tcoord.y = 1.0-tcoord.y;
            #endif
            float ref_depth = GetDepth(tcoord);
            float4 ref_pos = GetPosition(tcoord);
            if(ref_depth<ray_depth && ref_depth>ray_depth-0.01) {
                hit_coord = tcoord;
                break;
            }
        }

        if(adv<MaxDistance && dot(refdir, GetNormal(hit_coord).xyz)<0.0) {
            blend_color += tex2D(_FrameBuffer1, hit_coord).rgb * _Intensity * max(1.0 - (1.0/_FalloffDistance * adv), 0.0);
        }
        accumulation += 1.0;
    }

    if(accumulation < 5.0)
    {
        {
            float2 hit_coord;
            float3 refdir = reflect(cam_dir, n.xyz) + diverge(p, _RayDiffusion);
            float adv = _RayMarchDistance * jitter(p);

            for(int k=0; k<MAX_MARCH; ++k) {
                adv = adv + _RayMarchDistance;
                float4 tpos = mul(UNITY_MATRIX_MVP, float4((p.xyz+refdir*adv), 1.0) );
                float ray_depth = ComputeDepth(tpos);
                float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
                #if UNITY_UV_STARTS_AT_TOP
                    tcoord.y = 1.0-tcoord.y;
                #endif
                float ref_depth = GetDepth(tcoord);
                float4 ref_pos = GetPosition(tcoord);
                if(ref_depth<ray_depth && ref_depth>ray_depth-0.01) {
                    hit_coord = tcoord;
                    break;
                }
            }

            if(adv<MaxDistance && dot(refdir, GetNormal(hit_coord).xyz)<0.0) {
                blend_color += tex2D(_FrameBuffer1, hit_coord).rgb * _Intensity * max(1.0 - (1.0/_FalloffDistance * adv), 0.0);
            }
            accumulation += 1.0;
        }
        {
            float2 hit_coord;
            float3 refdir = reflect(cam_dir, n.xyz) + diverge(p, _RayDiffusion);
            float adv = _RayMarchDistance * jitter(p);

            for(int k=0; k<MAX_MARCH; ++k) {
                adv = adv + _RayMarchDistance;
                float4 tpos = mul(UNITY_MATRIX_MVP, float4((p.xyz+refdir*adv), 1.0) );
                float ray_depth = ComputeDepth(tpos);
                float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
                #if UNITY_UV_STARTS_AT_TOP
                    tcoord.y = 1.0-tcoord.y;
                #endif
                float ref_depth = GetDepth(tcoord);
                float4 ref_pos = GetPosition(tcoord);
                if(ref_depth<ray_depth && ref_depth>ray_depth-0.01) {
                    hit_coord = tcoord;
                    break;
                }
            }

            if(adv<MaxDistance && dot(refdir, GetNormal(hit_coord).xyz)<0.0) {
                blend_color += tex2D(_FrameBuffer1, hit_coord).rgb * _Intensity * max(1.0 - (1.0/_FalloffDistance * adv), 0.0);
            }
            accumulation += 1.0;
        }
    }

    r.color.rgb = blend_color / accumulation;
    r.color.w = min(accumulation, _MaxAccumulation);
    //r.color = diff * 10.0; // for debug

    return r;
 #endif // ALGORITHM_TEMPORAL
}


ps_out frag_combine(vs_out i)
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w) * 0.5 + 0.5;
    #if UNITY_UV_STARTS_AT_TOP
        //coord.y = 1.0-coord.y;
    #endif
    float2 s = (_ScreenParams.zw-1.0) * 1.5;
    float4 color = tex2D(_FrameBuffer1, coord);
    color += tex2D(_ReflectionBuffer, coord+float2( 0.0, 0.0)) * 0.2;
    color += tex2D(_ReflectionBuffer, coord+float2( s.x, 0.0)) * 0.125;
    color += tex2D(_ReflectionBuffer, coord+float2(-s.x, 0.0)) * 0.125;
    color += tex2D(_ReflectionBuffer, coord+float2( 0.0, s.y)) * 0.125;
    color += tex2D(_ReflectionBuffer, coord+float2( 0.0,-s.y)) * 0.125;
    color += tex2D(_ReflectionBuffer, coord+float2( s.x, s.y)) * 0.075;
    color += tex2D(_ReflectionBuffer, coord+float2(-s.x, s.y)) * 0.075;
    color += tex2D(_ReflectionBuffer, coord+float2(-s.x,-s.y)) * 0.075;
    color += tex2D(_ReflectionBuffer, coord+float2( s.x,-s.y)) * 0.075;
    color.w = 1.0;
    //color = tex2D(_ReflectionBuffer, coord); // for debug
    ps_out po = { color };
    return po;
}

ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_reflections
        #pragma target 3.0
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_combine
        #pragma target 3.0
        ENDCG
    }
}
}
