// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Ist/WaterSurface" {
SubShader {
    Tags { "Queue"="Transparent-100" "RenderType"="Transparent" }
    Blend Off
    ZTest Less
    ZWrite Off
    Cull Back

CGINCLUDE
#include "Noise.cginc"
#include "Assets/Ist/GBufferUtils/Shaders/GBufferUtils.cginc"

#define ENABLE_REFLECTIONS

#if QUALITY_FAST
    #define MAX_MARCH 12
#elif QUALITY_HIGH
    #define MAX_MARCH 32
#else // QUALITY_MEDIUM
    #define MAX_MARCH 16
#endif

sampler2D _RandomVectors;
sampler2D _FrameBuffer1;
float4 _Params1;
float4 _Params2;
float4 _Params3;

float4 _FresnelColor;
float4 _FalloffColor;
#define _ScrollSpeed    _Params1.x
#define _Scale          _Params1.y
#define _MarchStep      _Params1.z
#define _MarchBoost     _Params1.w
#define _Refraction     _Params2.x
#define _Reflection     _Params2.y
#define _Attenuation    _Params2.z
#define _FresnelBias    _Params3.x
#define _FresnelScale   _Params3.y
#define _FresnelPow     _Params3.z


struct ia_out
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
    float4 world_pos : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    float3 binormal : TEXCOORD4;
};

struct ps_out
{
    float4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos.y *= _ProjectionParams.x;
    o.world_pos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = normalize(mul(unity_ObjectToWorld, float4(v.normal.xyz, 0.0)).xyz);
    o.tangent = float4(normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz,0.0)).xyz), v.tangent.w);
    o.binormal = normalize(cross(o.normal, o.tangent) * v.tangent.w);
    return o;
}




float compute_octave(float3 pos, float scale)
{
    float time = _Time.y*_ScrollSpeed;
    float o1 = sea_octave(pos.xzy*1.25*scale + float3(1.0,2.0,-1.5)*time*1.25 + sin(pos.xzy+time*8.3)*0.15, 4.0);
    float o2 = sea_octave(pos.xzy*2.50*scale + float3(2.0,-1.0,1.0)*time*-2.0 - sin(pos.xzy+time*6.3)*0.2, 8.0);
    return o1 * o2;
}

float3 guess_normal(float3 p, float scale)
{
    const float d = 0.02;
    float o = 1.0-(compute_octave(p, scale)*0.5+0.5);
    return normalize( float3(
        compute_octave(p+float3(  d,0.0,0.0), scale)-compute_octave(p+float3( -d,0.0,0.0), scale),
        compute_octave(p+float3(0.0,0.0,  d), scale)-compute_octave(p+float3(0.0,0.0, -d), scale),
        0.02*o ));
}

float jitter(float3 p)
{
    float v = dot(p,1.0)+_Time.y;
    return frac(sin(v)*43758.5453);
}

ps_out frag(vs_out i)
{
    float2 coord = i.screen_pos.xy / i.screen_pos.w;

    float3 vn = i.normal.xyz;
    float3 wn = guess_normal(i.world_pos.xyz, _Scale);
    float3x3 tbn = float3x3( i.tangent.xyz, i.binormal, i.normal.xyz);
    wn = normalize(mul(wn, tbn));
    float3 n = normalize(wn + vn);

    float pd = length(i.world_pos.xyz - _WorldSpaceCameraPos.xyz);
    float3 cam_dir = normalize(i.world_pos - _WorldSpaceCameraPos);
    float ray_adv = 0.0;
    float2 ray_coord = 0.0;
    float ref_depth = 0.0;

    ps_out r;
    {
        float3 eye = normalize(_WorldSpaceCameraPos.xyz - i.world_pos.xyz);
        float step = _MarchStep;
        ray_adv = step * jitter(i.world_pos.xyz);
        float3 refdir = normalize(-eye + -reflect(-eye, n.xyz)*_Refraction);
        for(int k=0; k<MAX_MARCH; ++k) {
            float3 ray_pos = i.world_pos + refdir * ray_adv;
            float4 ray_pos4 = mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0));
            ray_pos4.y *= _ProjectionParams.x;
            float ray_depth = ComputeDepth(ray_pos4);
            ray_coord = (ray_pos4.xy / ray_pos4.w) * 0.5 + 0.5;
            ref_depth = GetDepth(ray_coord);
            if(ray_depth >= ref_depth) { break; }
            ray_adv += step;
            step *= _MarchBoost;
        }

        float3 hit_pos = GetPosition(ray_coord);
        float dist_surface = dot(i.normal.xyz, i.world_pos.xyz);
        float dist_hitpos = dot(i.normal.xyz, hit_pos.xyz);
        // dist_hitpos > dist_surface : hit_pos is above the surface
        float l = clamp((dist_surface - dist_hitpos) * 1000, 0, 1);
        ray_coord = lerp(coord, ray_coord, l);

        r.color = tex2D(_FrameBuffer1, ray_coord);
        r.color = lerp(_FalloffColor, r.color, max(1.0 - ray_adv * _Attenuation, 0.0));

        float fresnel = _FresnelBias + pow(1.0 + dot(cam_dir, n), _FresnelPow) * _FresnelScale;
        r.color += _FresnelColor * fresnel;
    }

#ifdef ENABLE_REFLECTIONS
    {
        // fake
        float distance = 1.0;
        float3 ref_dir = reflect(cam_dir, normalize(i.normal.xyz+n.xyz*0.2));
        float4 ray_pos4 = mul(UNITY_MATRIX_VP, float4(i.world_pos.xyz + ref_dir*distance, 1.0) );
        ray_pos4.y *= _ProjectionParams.x;
        float2 ray_coord = (ray_pos4.xy / ray_pos4.w + 1.0) * 0.5;
        half4 fc = tex2D(_FrameBuffer1, ray_coord);
        r.color.xyz = lerp(r.color.xyz, fc.xyz, saturate(fc.w)*_Reflection);
    }
#endif // ENABLE_REFLECTIONS
    //r.color.rgb = n * 0.5 + 0.5; // 
    //r.color = ray_adv * 0.1; // for debug
    return r;
}
ENDCG

    GrabPass {
        "_FrameBuffer1"
    }
    Pass {
        CGPROGRAM
        #pragma multi_compile QUALITY_FAST QUALITY_MEDIUM QUALITY_HIGH
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
