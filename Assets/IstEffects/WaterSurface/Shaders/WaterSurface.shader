Shader "WaterSurface/Surface" {
Properties {
    g_speed ("g_speed", Float) = 1.0
    g_refraction ("g_refraction", Float) = 0.05
    g_reflection_intensity ("g_reflection_intensity ", Float) = 0.3
    g_fresnel ("g_fresnel", Float) = 0.25
    g_raymarch_step ("g_raymarch_step", Float) = 0.2
    g_attenuation_by_distance ("g_attenuation_by_distance", Float) = 0.02
}
SubShader {
    Tags { "Queue"="Transparent+100" "RenderType"="Opaque" }
    Blend Off
    ZTest Less
    ZWrite Off
    Cull Back

CGINCLUDE
#include "Compat.cginc"
#include "Noise.cginc"
#include "Assets/IstEffects/GBufferUtils/Shaders/GBufferUtils.cginc"

#define MAX_MARCH 16

sampler2D _FrameBuffer1;
float g_speed;
float g_refraction;
float g_reflection_intensity;
float g_fresnel;
float g_raymarch_step;
float g_attenuation_by_distance;

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
    float time = _Time.y*g_speed;
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

    float3 n = guess_normal(i.world_pos.xyz, 1.0);
    float3x3 tbn = float3x3( i.tangent.xyz, i.binormal, i.normal.xyz);
    n = normalize(mul(n, tbn));

    float pd = length(i.world_pos.xyz - _WorldSpaceCameraPos.xyz);
    float fade = max(1.0-pd*0.05, 0.0);
    float3 cam_dir = normalize(i.world_pos - _WorldSpaceCameraPos);
    float2 ref_coord = 0.0;
    float ref_depth = 0.0;

    ps_out r;
    {
        float3 eye = normalize(_WorldSpaceCameraPos.xyz-i.world_pos.xyz);
        float adv = g_raymarch_step * jitter(i.world_pos.xyz);
        float3 refdir = normalize(-eye + -reflect(-eye, n.xyz)*g_refraction);
        for(int k=0; k<MAX_MARCH; ++k) {
            float4 tpos = mul(UNITY_MATRIX_VP, float4((i.world_pos+refdir * adv), 1.0) );
            float ray_depth = ComputeDepth(tpos);
            ref_coord = (tpos.xy / tpos.w + 1.0) * 0.5;
            #if UNITY_UV_STARTS_AT_TOP
                ref_coord.y = 1.0 - ref_coord.y;
            #endif
            ref_depth = GetDepth(ref_coord);
            if(ray_depth >= ref_depth) { break; }
            adv = adv + g_raymarch_step;
        }

        float f1 = max(1.0-abs(dot(n, eye))-0.5, 0.0)*2.0;
        float f2 = 1.0-abs(dot(i.normal, eye));

        r.color = tex2D(_FrameBuffer1, ref_coord);
        r.color *= 0.9;
        r.color = r.color * max(1.0 - adv * g_attenuation_by_distance, 0.0);
        r.color += (f1 * f2) * g_fresnel * fade;
        //r.color = adv;
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
        r.color.xyz += tex2D(_FrameBuffer1, tcoord).xyz * g_reflection_intensity;
    }
#endif // ENABLE_REFLECTIONS
    //r.color.rgb = pow(n*0.5+0.5, 4.0); // for debug
    //r.color.rgb = ref_depth; // for debug
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
