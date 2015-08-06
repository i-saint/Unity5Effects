#ifndef MPSurface_h
#define MPSurface_h

#define MP_ENABLE_SPIN
#define MP_ENABLE_HEAT_EMISSION

#ifdef MP_SHADOW_COLLECTOR
#   define SHADOW_COLLECTOR_PASS
#endif // MP_SHADOW_COLLECTOR

#include "UnityCG.cginc"
#include "MPFoundation.cginc"

float4 _HeatColor;
float _HeatThreshold;
float _HeatIntensity;


#ifdef MP_DEPTH_PREPASS
    #define MP_SHADOW_CASTER
#endif // MP_DEPTH_PREPASS



#if defined(MP_STANDARD) || defined(MP_SURFACE)
    sampler2D _MainTex;
    fixed4 _Color;

    struct Input {
        float2 uv_MainTex;
    #ifdef MP_ENABLE_HEAT_EMISSION
        float4 velocity;
    #endif // MP_ENABLE_HEAT_EMISSION
    };

    void vert(inout appdata_full v, out Input data)
    {
        UNITY_INITIALIZE_OUTPUT(Input,data);

        float4 pos;
        float4 vel;
        float4 params;
        ParticleTransform(v, pos, vel, params);

    #ifdef MP_ENABLE_HEAT_EMISSION
        data.velocity = vel;
    #endif // MP_ENABLE_HEAT_EMISSION
    }
#endif // defined(MP_STANDARD) || defined(MP_SURFACE)



// legacy surface shader
#ifdef MP_SURFACE
    void surf(Input IN, inout SurfaceOutput o)
    {
        o.Albedo = _Color * tex2D(_MainTex, IN.uv_MainTex);

#ifdef MP_ENABLE_HEAT_EMISSION
        float speed = IN.velocity.w;
        float ei = max(speed - _HeatThreshold, 0.0) * _HeatIntensity;
        o.Emission += _HeatColor.rgb*ei;
#endif // MP_ENABLE_HEAT_EMISSION
    }
#endif // MP_SURFACE



// standard shader
#ifdef MP_STANDARD
    half _Glossiness;
    half _Metallic;

    void surf(Input IN, inout SurfaceOutputStandard o)
    {
        fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
        o.Albedo = c.rgb;
        o.Metallic = _Metallic;
        o.Smoothness = _Glossiness;
        o.Alpha = c.a;

#ifdef MP_ENABLE_HEAT_EMISSION
        float speed = IN.velocity.w;
        float ei = max(speed - _HeatThreshold, 0.0) * _HeatIntensity;
        o.Emission += _HeatColor.rgb*ei;
#endif // MP_ENABLE_HEAT_EMISSION
    }
#endif // MP_STANDARD



// shadow caster
#ifdef MP_SHADOW_CASTER
    struct v2f
    { 
        V2F_SHADOW_CASTER;
    };

    v2f vert( appdata_full v )
    {
        float4 pos;
        float4 vel;
        float4 params;
        ParticleTransform(v, pos, vel, params);

        v2f o;
        TRANSFER_SHADOW_CASTER(o)
        return o;
    }

    float4 frag( v2f i ) : SV_Target
    {
        SHADOW_CASTER_FRAGMENT(i)
    }
#endif // MP_SHADOW_CASTER



// legacy shadow collector
#ifdef MP_SHADOW_COLLECTOR
    struct v2f { 
        V2F_SHADOW_COLLECTOR;
    };

    v2f vert( appdata_full v )
    {
        float4 pos;
        float4 vel;
        float4 params;
        ParticleTransform(v, pos, vel, params);

        v2f o;
        TRANSFER_SHADOW_COLLECTOR(o)
        return o;
    }
        
    fixed4 frag (v2f i) : SV_Target
    {
        SHADOW_COLLECTOR_FRAGMENT(i)
    }
#endif // MP_SHADOW_COLLECTOR


#endif // MPSurface_h
