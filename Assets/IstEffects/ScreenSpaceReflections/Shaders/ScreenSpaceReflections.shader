Shader "Hidden/ScreenSpaceReflections" {
Properties {
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"
sampler2D _FrameBuffer1;
sampler2D _ReflectionBuffer;
sampler2D _AccumulationBuffer;

float4 _Params0;
float4 _Params1;
#define _Intensity          _Params0.x
#define _RayMarchDistance   _Params0.y
#define _RayDiffusion       _Params0.z
#define _FalloffDistance    _Params0.w
#define _MaxAccumulation    _Params1.x
#define _RayHitRadius       _Params1.y

// on OpenGL ES platforms, shader compiler goes infinite loop (?) without this workaround...
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    // QUALITY_FAST
    #define MAX_MARCH 12
    #define MAX_TRACEBACK_MARCH 4
    #define NUM_RAYS 1
#else
    #if QUALITY_FAST
        #define MAX_MARCH 12
        #define MAX_TRACEBACK_MARCH 4
        #define NUM_RAYS 1
    #elif QUALITY_HIGH
        #define MAX_MARCH 32
        #define MAX_TRACEBACK_MARCH 8
        //#define NUM_RAYS 2
    #elif QUALITY_ULTRA
        #define MAX_MARCH 64
        #define MAX_TRACEBACK_MARCH 8
        //#define NUM_RAYS 4
    #else // QUALITY_MEDIUM
        #define MAX_MARCH 16
        #define MAX_TRACEBACK_MARCH 8
        #define NUM_RAYS 1
    #endif
#endif

#define ENABLE_RAY_TRACEBACK
#define ENABLE_BLURED_COMBINE


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
    half4 color : SV_Target0;
    half4 accumulation : SV_Target1;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = v.vertex;
    o.screen_pos = v.vertex;
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}


// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

float Jitter(float3 p)
{
    float v = dot(p,1.0)+_Time.y;
    return frac(sin(v)*43758.5453);
}
float3 Diffusion(float3 p, float d)
{
    p *= _Time.y;
    return (float3(frac(sin(p)*43758.5453))*2.0-1.0) * d;
}

void RayMarching(float seed, float3 p, float2 coord, float3 cam_dir, float3 n, float smoothness, float march_step, float hit_radius,
    inout float4 blend_color, inout float accumulation)
{
    float3 refdir = normalize(reflect(cam_dir, n.xyz) + Diffusion(p+seed, _RayDiffusion) * (1.0-smoothness));
    float jitter = march_step * Jitter(p+seed);
    float2 hit_coord = coord;
    float hit = 0.0;
    float adv;

    float3 ray_pos;
    float2 ray_coord;

    for(int k=0; k<MAX_MARCH; ++k) {
        adv = march_step * k + jitter;
        ray_pos = p.xyz + refdir * adv;
        float4 ray_pos4 = mul(UNITY_MATRIX_MVP, float4(ray_pos, 1.0));
        ray_pos4.y *= _ProjectionParams.x;
        ray_coord = ray_pos4.xy / ray_pos4.w * 0.5 + 0.5 + HalfPixelSize;
        float ray_depth = ComputeDepth(ray_pos4);
        float ref_depth = GetDepth(ray_coord);

        if(ray_depth > ref_depth) {
            hit = 1.0;
            break;
        }
    }

#ifdef ENABLE_RAY_TRACEBACK
    for(int l=0; l<MAX_TRACEBACK_MARCH-1; ++l) {
        adv -= (march_step/MAX_TRACEBACK_MARCH);
        float3 ray_pos_ = p.xyz + refdir * adv;
        float4 ray_pos4 = mul(UNITY_MATRIX_MVP, float4(ray_pos_, 1.0));
        ray_pos4.y *= _ProjectionParams.x;
        float2 ray_coord_ = ray_pos4.xy / ray_pos4.w * 0.5 + 0.5 + HalfPixelSize;
        float ray_depth = ComputeDepth(ray_pos4);
        float ref_depth = GetDepth(ray_coord_.xy);

        if(ray_depth < ref_depth) {
            break;
        }
        ray_coord = ray_coord_;
        ray_pos = ray_pos_;
    }
#endif

    float4 ref_pos = GetPosition(ray_coord);
    float3 ref_normal = GetNormal(ray_coord);
    if(dot(ref_normal, refdir) > 0.0 || length(ref_pos.xyz-ray_pos.xyz) > hit_radius) {
        hit = 0.0;
    }
    hit_coord = lerp(hit_coord, ray_coord, hit);
    float2 edge = abs(hit_coord * 2.0 - 1.0);
    float edge_attr = pow(1.0 - max(edge.x,edge.y), 0.5);
    blend_color.a += max(1.0 - (adv / _FalloffDistance), 0.0) * edge_attr * smoothness * hit;

    blend_color.rgb += tex2D(_FrameBuffer1, hit_coord).rgb;
    accumulation += 1.0;
}

ps_out frag_reflections(vs_out i)
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w) * 0.5 + 0.5 + HalfPixelSize;

    ps_out r;
    r.color = 0.0;
    r.accumulation = 0.0;

    float depth = GetDepth(coord);
    if(depth == 1.0) { return r; }

    float4 p = GetPosition(coord);
    float4 n = GetNormal(coord);
    float4 smoothness = GetSpecular(coord).w;
    float3 cam_dir = normalize(p.xyz - _WorldSpaceCameraPos);

    float2 prev_coord;
    float4 prev_result;
    float4 prev_pos;
    float accumulation;
    {
        float4 ppos = mul(_PrevViewProj, float4(p.xyz, 1.0) );
        prev_coord = (ppos.xy / ppos.w) * 0.5 + 0.5;
        prev_result = tex2D(_ReflectionBuffer, prev_coord);
        accumulation = tex2D(_AccumulationBuffer, prev_coord).x * _MaxAccumulation;
        prev_pos = GetPrevPosition(coord);
    }

    float diff = length(p.xyz-prev_pos.xyz);
    accumulation *= max(1.0-(0.05+diff*20.0), 0.0);
    float4 blend_color = prev_result * accumulation;
    float march_step = _RayMarchDistance / MAX_MARCH;
    float hit_radius = _RayHitRadius;

    RayMarching(0.0, p, coord, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
#if NUM_RAYS >= 2
    RayMarching(0.1, p, coord, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
#endif
#if NUM_RAYS >= 4
    RayMarching(0.2, p, coord, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
    RayMarching(0.3, p, coord, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
#endif
    r.color = blend_color / accumulation;
    //r.color = float4(diff, diff, diff, 1.0); // for debug
    r.accumulation = min(accumulation, _MaxAccumulation) / _MaxAccumulation;
    return r;
}

float4 frag_combine(vs_out i) : SV_Target
{
    float2 coord = (i.screen_pos.xy / i.screen_pos.w) * 0.5 + 0.5;
    //return tex2D(_ReflectionBuffer, coord); // for debug

    float accumulation = tex2D(_AccumulationBuffer, coord).x;
    float2 s = (_ScreenParams.zw-1.0) * 1.25;
    float4 color = tex2D(_FrameBuffer1, coord);
    float4 ref_color = 0.0;
#ifdef ENABLE_BLURED_COMBINE
    ref_color += tex2D(_ReflectionBuffer, coord+float2( 0.0, 0.0)) * 0.2;
    ref_color += tex2D(_ReflectionBuffer, coord+float2( s.x, 0.0)) * 0.125;
    ref_color += tex2D(_ReflectionBuffer, coord+float2(-s.x, 0.0)) * 0.125;
    ref_color += tex2D(_ReflectionBuffer, coord+float2( 0.0, s.y)) * 0.125;
    ref_color += tex2D(_ReflectionBuffer, coord+float2( 0.0,-s.y)) * 0.125;
    ref_color += tex2D(_ReflectionBuffer, coord+float2( s.x, s.y)) * 0.075;
    ref_color += tex2D(_ReflectionBuffer, coord+float2(-s.x, s.y)) * 0.075;
    ref_color += tex2D(_ReflectionBuffer, coord+float2(-s.x,-s.y)) * 0.075;
    ref_color += tex2D(_ReflectionBuffer, coord+float2( s.x,-s.y)) * 0.075;
#else
    ref_color += tex2D(_ReflectionBuffer, coord);
#endif

    float alpha = ref_color.a * _Intensity;
    return float4(lerp(color.rgb, ref_color.rgb, alpha), 1.0);
}

ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_reflections
        #pragma target 3.0
        #pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH QUALITY_ULTRA
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
