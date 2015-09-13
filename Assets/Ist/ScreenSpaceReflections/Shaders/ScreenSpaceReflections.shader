Shader "Hidden/ScreenSpaceReflections" {
Properties{
    _MainTex("Base (RGB)", 2D) = "" {}
}
SubShader {
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Off

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"
sampler2D _MainTex;
sampler2D _ReflectionBuffer;
sampler2D _AccumulationBuffer;

float4 _Params0;
float4 _Params1;
float4 _BlurOffset;
float4x4 _WorldToCamera;

#define _Intensity          _Params0.x
#define _RayMarchDistance   _Params0.y
#define _RayDiffusion       _Params0.z
#define _FalloffDistance    _Params0.w
#define _MaxAccumulation    _Params1.x
#define _RayHitRadius       _Params1.y
#define _RayStepBoost       _Params1.z

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
    o.vertex = o.screen_pos = v.vertex;
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

vs_out vert_combine(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

// on d3d9, _CameraDepthTexture is bilinear-filtered. so we need to sample center of pixels.
#if SHADER_API_D3D9
    #define UVOffset ((_ScreenParams.zw-1.0)*0.5)
#else
    #define UVOffset 0.0
#endif

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


struct RayHitData
{
    float hit;
    float advance;
    float3 pos;
    float2 uv;
};

RayHitData RayMarching(float3 p, float3 n, float march_step, float hit_radius, float smoothness, float diffusion_seed)
{
    float3x3 proj = tofloat3x3(unity_CameraProjection);

    float3 vp = mul(_WorldToCamera, float4(p, 1.0)).xyz;
    float3 cam_dir = normalize(p - _WorldSpaceCameraPos);
    float3 ref_dir = normalize(reflect(cam_dir, n.xyz) + Diffusion(p + diffusion_seed, _RayDiffusion) * (1.0-smoothness));
    float3 ref_vdir = mul(tofloat3x3(_WorldToCamera), ref_dir);
    float jitter = march_step * Jitter(p + diffusion_seed);

    float hit = 0.0;
    float adv = 0.0;
    float3 ray_vpos = 0.0;
    float2 ray_uv = 0.0;

    // raymarch
    for(int k=0; k<MAX_MARCH; ++k) {
        adv = march_step * k + jitter;
        march_step *= (1.0+_RayStepBoost);
        ray_vpos = vp + ref_vdir * adv;

        float3 ray_ppos = mul(proj, ray_vpos);
        ray_uv = ray_ppos.xy / ray_vpos.z * 0.5 + 0.5 + UVOffset;
        float ray_depth = ray_vpos.z;
        float ref_depth = GetLinearDepth(ray_uv);

        if(ray_depth > ref_depth) {
            hit = 1.0;
            break;
        }
    }

    // trace back
#ifdef ENABLE_RAY_TRACEBACK
    for(int l=0; l<MAX_TRACEBACK_MARCH-1; ++l) {
        adv -= (march_step/MAX_TRACEBACK_MARCH);
        float3 ray_vpos_ = vp + ref_vdir * adv;
        float3 ray_ppos = mul(proj, ray_vpos_);
        float2 ray_uv_ = ray_ppos.xy / ray_vpos_.z * 0.5 + 0.5 + UVOffset;
        float ray_depth = ray_vpos_.z;
        float ref_depth = GetLinearDepth(ray_uv_);

        if(ray_depth < ref_depth) {
            break;
        }
        ray_uv = ray_uv_;
        ray_vpos = ray_vpos_;
    }
#endif

    float3 ray_pos = p + ref_dir * adv;
    float3 ref_pos = GetPosition(ray_uv);
    float3 ref_normal = GetNormal(ray_uv);
    if(/*dot(ref_normal, ref_dir) > 0.0 ||*/
        length(ref_pos.xyz- ray_pos.xyz) > hit_radius)
    {
        hit = 0.0;
    }

    RayHitData r;
    r.hit = hit;
    r.advance = adv;
    r.pos = ray_pos;
    r.uv = ray_uv;
    return r;
}

void SampleHitFragment(RayHitData ray, float smoothness, inout float4 blend_color, inout float accumulation)
{
    float2 edge = abs(ray.uv * 2.0 - 1.0);
    float edge_attr = pow(1.0 - max(edge.x, edge.y), 0.5);
    blend_color.a += max(1.0 - (ray.advance / _FalloffDistance), 0.0) * edge_attr * smoothness * ray.hit;

    blend_color.rgb += tex2D(_MainTex, ray.uv).rgb;
    accumulation += 1.0;
}

ps_out frag_reflections(vs_out i)
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w + UVOffset;

    ps_out r;
    r.color = 0.0;
    r.accumulation = 0.0;

    float depth = GetDepth(uv);
    if(depth == 1.0) { return r; }

    float3 p = GetPosition(uv);
    float3 n = GetNormal(uv);
    float4 smoothness = GetSpecular(uv).w;

    float2 prev_uv;
    float4 prev_result;
    float3 prev_pos;
    float accumulation;
    {
        float4 ppos = mul(_PrevViewProj, float4(p, 1.0) );
        prev_uv = (ppos.xy / ppos.w) * 0.5 + 0.5;
        prev_result = tex2D(_ReflectionBuffer, prev_uv);
        accumulation = tex2D(_AccumulationBuffer, prev_uv).x * _MaxAccumulation;
        prev_pos = GetPrevPosition(uv);
    }

    float diff = length(p-prev_pos);
    accumulation *= max(1.0-(0.05+diff*20.0), 0.0);
    float4 blend_color = prev_result * accumulation;
    float march_step = _RayMarchDistance / MAX_MARCH;
    float hit_radius = _RayHitRadius;

    RayHitData hit = RayMarching(p, n, march_step, hit_radius, smoothness, 0.0);
    SampleHitFragment(hit, smoothness, blend_color, accumulation);
//#if NUM_RAYS >= 2
//    RayMarching(0.1, p, uv, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
//#endif
//#if NUM_RAYS >= 4
//    RayMarching(0.2, p, uv, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
//    RayMarching(0.3, p, uv, cam_dir, n, smoothness, march_step, hit_radius, blend_color, accumulation);
//#endif
    r.color = blend_color / accumulation;
    r.accumulation = min(accumulation, _MaxAccumulation) / _MaxAccumulation;
    return r;
}


half4 frag_blur(vs_out i) : SV_Target
{
    const float weights[5] = {0.05, 0.09, 0.12, 0.16, 0.16};
    float2 uv = i.screen_pos.xy / i.screen_pos.w + UVOffset;
    float2 o = _BlurOffset.xy;

    float4 r = 0.0;
    r += tex2D(_ReflectionBuffer, uv - o*4.0) * weights[0];
    r += tex2D(_ReflectionBuffer, uv - o*3.0) * weights[1];
    r += tex2D(_ReflectionBuffer, uv - o*2.0) * weights[2];
    r += tex2D(_ReflectionBuffer, uv - o*1.0) * weights[3];
    r += tex2D(_ReflectionBuffer, uv        ) * weights[4];
    r += tex2D(_ReflectionBuffer, uv + o*1.0) * weights[3];
    r += tex2D(_ReflectionBuffer, uv + o*2.0) * weights[2];
    r += tex2D(_ReflectionBuffer, uv + o*3.0) * weights[1];
    r += tex2D(_ReflectionBuffer, uv + o*4.0) * weights[0];
    return r;
}


float4 frag_combine(vs_out i) : SV_Target
{
    float2 uv = i.screen_pos.xy / i.screen_pos.w;

    float accumulation = tex2D(_AccumulationBuffer, uv).x;
    float4 color = tex2D(_MainTex, uv);
    float4 ref_color = tex2D(_ReflectionBuffer, uv);
    float alpha = saturate(ref_color.a * _Intensity);
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
        #pragma fragment frag_blur
        #pragma target 3.0
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert_combine
        #pragma fragment frag_combine
        #pragma target 3.0
        ENDCG
    }
}
}
