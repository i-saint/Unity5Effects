Shader "WaterSurface/Surface" {
Properties {
    _Speed("Speed", Float) = 1.0
    _Scale("Scale", Float) = 1.0
    _Refraction("Refraction", Float) = 0.05
    _ReflectionIntensity ("ReflectionIntensity ", Float) = 0.3
    _FresnelBias("Fresnel Bias", Float) = 0.0
    _FresnelScale("Fresnel Scale", Float) = 0.25
    _FresnelPow("Fresnel Pow", Float) = 5.0
    _FresnelColor("Fresnel Color", Color) = (1, 1, 1, 1)
    _RaymaechStep("RaymaechStep", Float) = 0.2
    _AttenuationByDistance("AttenuationByDistance", Float) = 0.02
    _FalloffColor("FalloffColor", Color) = (0,0,0,0)
}
SubShader {
    Tags { "Queue"="Transparent+200" "RenderType"="Opaque" }
    Blend Off
    ZTest Less
    ZWrite Off
    Cull Back

CGINCLUDE
#include "Compat.cginc"
#include "Noise.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"

#define MAX_MARCH 16
//#define ENABLE_REFLECTIONS

sampler2D _RandomVectors;
sampler2D _FrameBuffer1;
float _Speed;
float _Scale;
float _Refraction;
float _ReflectionIntensity;
float _FresnelBias;
float _FresnelScale;
float _FresnelPow;
float4 _FresnelColor;
float _RaymaechStep;
float _AttenuationByDistance;
float4 _FalloffColor;

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
    float4 spos = mul(UNITY_MATRIX_MVP, v.vertex);
    vs_out o;
    o.vertex = spos;
    o.screen_pos = spos;
    o.world_pos = mul(_Object2World, v.vertex);
    o.normal = normalize(mul(_Object2World, float4(v.normal.xyz, 0.0)).xyz);
    o.tangent = float4(normalize(mul(_Object2World, float4(v.tangent.xyz,0.0)).xyz), v.tangent.w);
    o.binormal = normalize(cross(o.normal, o.tangent) * v.tangent.w);
    return o;
}




float compute_octave(float3 pos, float scale)
{
    float time = _Time.y*_Speed;
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
    float2 coord = (i.screen_pos.xy / i.screen_pos.w + 1.0) * 0.5;
    #if UNITY_UV_STARTS_AT_TOP
        coord.y = 1.0 - coord.y;
    #endif

    float3 vn = i.normal.xyz;
    float3 wn = guess_normal(i.world_pos.xyz, _Scale);
    float3x3 tbn = float3x3( i.tangent.xyz, i.binormal, i.normal.xyz);
    wn = normalize(mul(wn, tbn));
    float3 n = normalize(wn + vn);

    float pd = length(i.world_pos.xyz - _WorldSpaceCameraPos.xyz);
    float3 cam_dir = normalize(i.world_pos - _WorldSpaceCameraPos);
    float2 ray_coord = 0.0;
    float ref_depth = 0.0;

    ps_out r;
    {
        float3 eye = normalize(_WorldSpaceCameraPos.xyz-i.world_pos.xyz);
        float adv = _RaymaechStep * jitter(i.world_pos.xyz);
        float3 refdir = normalize(-eye + -reflect(-eye, n.xyz)*_Refraction);
        for(int k=0; k<MAX_MARCH; ++k) {
            float3 ray_pos = i.world_pos + refdir * adv;
            float4 ray_pos4 = mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0));
            ray_pos4.y *= _ProjectionParams.x;
            float ray_depth = ComputeDepth(ray_pos4);
            ray_coord = (ray_pos4.xy / ray_pos4.w + 1.0) * 0.5;
            ref_depth = GetDepth(ray_coord);
            if(ray_depth >= ref_depth) { break; }
            adv = adv + _RaymaechStep;
        }

        float4 hit_pos = GetPosition(ray_coord);
        float dist1 = dot(i.normal.xyz, i.world_pos.xyz);
        float dist2 = dot(i.normal.xyz, hit_pos.xyz);
        // dist2 > dist1 : hit_pos is above the surface
        float l = clamp((dist1 - dist2) * 1000, 0, 1);
        ray_coord = lerp(coord, ray_coord, l);


        r.color = tex2D(_FrameBuffer1, ray_coord);
        r.color = lerp(_FalloffColor, r.color, max(1.0 - adv * _AttenuationByDistance, 0.0));

        float f1 = max(1.0-abs(dot(n, eye))-0.5, 0.0)*2.0;
        float f2 = 1.0 - abs(dot(i.normal, eye));
        // FRESNEL CALCS float fcbias = 0.20373;
        float fresnel = saturate(_FresnelBias + pow(1.0 + dot(cam_dir, n), _FresnelPow) * _FresnelScale);
        r.color += _FresnelColor * fresnel;
        //r.color += (f1 * f2 + (f2 * f2 * f2)) * _FresnelPow;
    }
#ifdef ENABLE_REFLECTIONS
    {
        float _RayMarchDistance = 1.0;
        float3 ref_dir = reflect(cam_dir, normalize(i.normal.xyz+n.xyz*0.2));
        float4 tpos = mul(UNITY_MATRIX_VP, float4(i.world_pos.xyz + ref_dir*_RayMarchDistance, 1.0) );
        float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
        #if UNITY_UV_STARTS_AT_TOP
            tcoord.y = 1.0-tcoord.y;
        #endif
        r.color.xyz += tex2D(_FrameBuffer1, tcoord).xyz * _ReflectionIntensity;
    }
#endif // ENABLE_REFLECTIONS
    //r.color.rgb = n * 0.5 + 0.5; // for debug
    return r;
}
ENDCG

    GrabPass {
        "_FrameBuffer1"
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 3.0
        ENDCG
    }
}
}
