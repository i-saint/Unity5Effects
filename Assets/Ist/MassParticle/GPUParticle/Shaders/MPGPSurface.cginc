#ifndef MPGPSurface_h
#define MPGPSurface_h

#define MPGP_ENABLE_SPIN
#define MPGP_ENABLE_HEAT_EMISSION
#define MPGP_FOR_DRAW


#if (defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL))
    #define MPGP_WITH_STRUCTURED_BUFFER
#endif

#ifdef MPGP_SHADOW_COLLECTOR
#   define SHADOW_COLLECTOR_PASS
#endif // MPGP_SHADOW_COLLECTOR

#include "UnityCG.cginc"
#include "MPGPFoundation.cginc"

#ifdef MPGP_WITH_STRUCTURED_BUFFER
StructuredBuffer<Particle> particles;
#endif // MPGP_WITH_STRUCTURED_BUFFER
int         g_batch_begin;
float       g_size;
float       g_fade_time;
float       g_spin;

float _HeatThreshold;
float _HeatIntensity;
float4 _HeatColor;


int ParticleTransform(inout appdata_full v)
{
    int iid = v.texcoord1.x + g_batch_begin;
#ifdef MPGP_WITH_STRUCTURED_BUFFER
    Particle p = particles[iid];

    if(p.lifetime<=0.0) {
        v.vertex.xyz = 0.0;
        return iid;
    }
    v.vertex.xyz *= g_size * min(1.0, p.lifetime/g_fade_time);
    #ifdef MPGP_ENABLE_SPIN
    if(g_spin != 0.0) {
        float ang = (dot(p.position.xyz, 1.0) * min(1.0, p.speed*0.02)) * g_spin;
        float3x3 rot = RotateAxis33(normalize(iq_rand(p.id.xxx)), ang);
        v.vertex.xyz = mul(rot, v.vertex.xyz);
        v.normal.xyz = mul(rot, v.normal.xyz);
    }
    #endif // MPGP_ENABLE_SPIN
    v.vertex.xyz += p.position.xyz;
#endif // MPGP_WITH_STRUCTURED_BUFFER
    return iid;
}



#if defined(MPGP_STANDARD) || defined(MPGP_SURFACE)
    sampler2D _MainTex;
    half4 _Color;
    half4 _Emission;

    struct Input {
        float2 uv_MainTex;
#ifdef MPGP_ENABLE_HEAT_EMISSION
        float4 velocity;
#endif // MPGP_ENABLE_HEAT_EMISSION
    };

    void vert(inout appdata_full v, out Input data)
    {
        UNITY_INITIALIZE_OUTPUT(Input,data);

        int iid = ParticleTransform(v);
    #ifdef MPGP_WITH_STRUCTURED_BUFFER
#ifdef MPGP_ENABLE_HEAT_EMISSION
        data.velocity = float4(particles[iid].velocity, particles[iid].speed);
#endif // MPGP_ENABLE_HEAT_EMISSION
    #endif // MPGP_WITH_STRUCTURED_BUFFER
    }
#endif // defined(MPGP_STANDARD) || defined(MPGP_SURFACE)



// legacy surface shader
#ifdef MPGP_SURFACE
    void surf(Input IN, inout SurfaceOutput o)
    {
        o.Albedo = _Color * tex2D(_MainTex, IN.uv_MainTex);
        o.Emission += _Emission;

#ifdef MPGP_ENABLE_HEAT_EMISSION
        float speed = IN.velocity.w;
        float ei = max(speed - _HeatThreshold, 0.0) * _HeatIntensity;
        o.Emission += _HeatColor.rgb*ei;
#endif // MPGP_ENABLE_HEAT_EMISSION
    }
#endif // MPGP_SURFACE



// standard shader
#ifdef MPGP_STANDARD
    half _Glossiness;
    half _Metallic;

    void surf(Input IN, inout SurfaceOutputStandard o)
    {
        fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
        o.Albedo = c.rgb;
        o.Metallic = _Metallic;
        o.Smoothness = _Glossiness;
        o.Alpha = c.a;
        o.Emission += _Emission;

#ifdef MPGP_ENABLE_HEAT_EMISSION
        float speed = IN.velocity.w;
        float ei = max(speed - _HeatThreshold, 0.0) * _HeatIntensity;
        o.Emission += _HeatColor.rgb*ei;
#endif // MPGP_ENABLE_HEAT_EMISSION
    }
#endif // MPGP_STANDARD



// shadow caster
#ifdef MPGP_SHADOW_CASTER
    struct v2f
    { 
        V2F_SHADOW_CASTER;
    };

    v2f vert( appdata_full v )
    {
        int iid = ParticleTransform(v);

        v2f o;
        TRANSFER_SHADOW_CASTER(o)
        return o;
    }

    float4 frag( v2f i ) : SV_Target
    {
        SHADOW_CASTER_FRAGMENT(i)
    }
#endif // MPGP_SHADOW_CASTER



// legacy shadow collector
#ifdef MPGP_SHADOW_COLLECTOR
    struct v2f { 
        V2F_SHADOW_COLLECTOR;
    };

    v2f vert( appdata_full v )
    {
        int iid = ParticleTransform(v);

        v2f o;
        TRANSFER_SHADOW_COLLECTOR(o)
        return o;
    }
        
    fixed4 frag (v2f i) : SV_Target
    {
        SHADOW_COLLECTOR_FRAGMENT(i)
    }
#endif // MPGP_SHADOW_COLLECTOR



// transparent
#if defined(MPGP_TRANSPARENT)
    half4 _Color;
    half4 _Emission;

    struct vs_out
    {
        float4 vertex : SV_Position;
    };

    struct ps_out
    {
        half4 color : SV_Target;
    };

    vs_out vert( appdata_full v )
    {
        int iid = ParticleTransform(v);

        vs_out o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        return o;
    }
        
    ps_out frag(vs_out i)
    {
        ps_out o;
        o.color = _Color + _Emission;
        return o;
    }
#endif


#if defined(MPGP_BILLBOARD) || defined(MPGP_FIXED_BILLBOARD)

    void ApplyBillboardTransform(inout appdata_full v)
    {
        int iid = v.texcoord1.x + g_batch_begin;

    #ifdef MPGP_WITH_STRUCTURED_BUFFER
        MPGPParticle p = particles[iid];

        if(p.lifetime<=0.0) {
            v.vertex.xyz = 0.0;
            return;
        }

        float3 camera_pos = _WorldSpaceCameraPos.xyz;
        float3 pos = p.position;
        float3 look = normalize(pos-camera_pos);
        float3 up = float3(0.0, 1.0, 0.0);

        v.vertex.xyz *= g_size;
        v.vertex.xyz *= min(1.0, p.lifetime/g_fade_time);
        #ifdef MPGP_ENABLE_SPIN
        if(g_spin != 0.0) {
            float ang = (dot(p.position.xyz, 1.0) * min(1.0, p.speed*0.02)) * g_spin;
            float3x3 rot = rotation_matrix33(normalize(iq_rand(p.id)), ang);
            v.vertex.xyz = mul(rot, v.vertex.xyz);
            v.normal.xyz = mul(rot, v.normal.xyz);
        }
        #endif // MPGP_ENABLE_SPIN
        v.vertex.xyz = mul(Look33(look, up), vertex.xyz);
        v.vertex.xyz += pos;
        vertex = mul(UNITY_MATRIX_VP, vertex);
    #endif // MPGP_WITH_STRUCTURED_BUFFER
    }


    bool ApplyViewPlaneProjection(inout float4 vertex, float3 pos)
    {
        float4 vp = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
        if(vp.z<0.0) {
            vertex.xyz *= 0.0;
            return false;
        }

        float aspect = _ScreenParams.x / _ScreenParams.y;
        float3 camera_pos = _WorldSpaceCameraPos.xyz;
        float3 look = normalize(camera_pos-pos);
        Plane view_plane = {look, 1.0};
        pos = camera_pos + ProjectToPlane(view_plane, pos-camera_pos);
        vertex.y *= -aspect;
        vertex.xy += vp.xy / vp.w;
        vertex.zw = float2(0.0, 1.0);
        return true;
    }

    void ApplyViewPlaneBillboardTransform(inout appdata_full v)
    {
        int iid = v.texcoord1.x + g_batch_begin;

    #ifdef MPGP_WITH_STRUCTURED_BUFFER
        float3 pos = particles[iid].position;
        v.vertex.xyz *= g_size;

        float4 vp = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
        if(vp.z<0.0) {
            v.vertex.xyz *= 0.0;
            return false;
        }

        float aspect = _ScreenParams.x / _ScreenParams.y;
        float3 camera_pos = _WorldSpaceCameraPos.xyz;
        float3 look = normalize(camera_pos-pos);
        Plane view_plane = {look, 1.0};
        pos = camera_pos + ProjectToPlane(view_plane, pos-camera_pos);
        v.vertex.y *= -aspect;
        v.vertex.xy += vp.xy / vp.w;
        v.vertex.zw = float2(0.0, 1.0);
    #endif // MPGP_WITH_STRUCTURED_BUFFER
    }
#endif // defined(MPGP_BILLBOARD) || defined(MPGP_FIXED_BILLBOARD)


#endif // MPGPSurface_h
