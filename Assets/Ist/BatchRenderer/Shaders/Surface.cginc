#ifndef BRSurface_h
#define BRSurface_h

#include "UnityCG.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/BatchRenderer.cginc"



void ApplyInstanceTransform(int instance_id, inout float4 vertex, inout float3 normal, inout float4 tangent, inout float2 texcoord, inout float4 color, inout float4 emission)
{
    if(instance_id >= GetNumInstances()) {
        vertex.xyz *= 0.0;
        return;
    }
    vertex.xyz *= GetBaseScale();
#if ENABLE_INSTANCE_SCALE
    vertex.xyz *= GetInstanceScale(instance_id);
#endif
#if ENABLE_INSTANCE_ROTATION
    {
        float3x3 rot = QuaternionToMatrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
        normal.xyz = mul(rot, normal.xyz);
        tangent.xyz = mul(rot, tangent.xyz);
    }
#endif
    vertex.xyz += GetInstanceTranslation(instance_id);

#if ENABLE_INSTANCE_UVOFFSET
    {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
#endif
#if ENABLE_INSTANCE_COLOR
    color *= GetInstanceColor(instance_id);
#endif
#if ENABLE_INSTANCE_EMISSION
    emission += GetInstanceEmission(instance_id);
#endif
}

#if defined(BR_SURFACE) || defined(BR_SURFACE_DETAILED) || defined(BR_STANDARD)
    sampler2D _MainTex;
    sampler2D _NormalMap;
    sampler2D _EmissionMap;
    sampler2D _SpecularMap;
    sampler2D _GrossMap;
    half _Glossiness;
    half _Metallic;
    fixed4 _Color;
    fixed4 g_base_color;
    fixed4 _Emission;

    struct Input {
        float2 uv_MainTex;
#if ENABLE_INSTANCE_COLOR && SHADER_TARGET > 30
        float4 color;
#endif
#if ENABLE_INSTANCE_EMISSION
        float4 emission;
#endif
    };

    void vert(inout appdata_full I, out Input O)
    {
        UNITY_INITIALIZE_OUTPUT(Input,O);

        int iid = GetBatchBegin() + I.texcoord1.x;

        float4 color = I.color * g_base_color;
        float4 emission = 0.0;
        ApplyInstanceTransform(iid, I.vertex, I.normal, I.tangent, I.texcoord.xy, color, emission);

        O.uv_MainTex = float4(I.texcoord.xy, 0.0, 0.0);
#if ENABLE_INSTANCE_COLOR && SHADER_TARGET > 30
        o.color = color;
#endif
#if ENABLE_INSTANCE_EMISSION
        O.emission = emission;
#endif
    }
#endif



#ifdef BR_STANDARD
    void surf(Input I, inout SurfaceOutputStandard O)
    {
        fixed4 c = tex2D(_MainTex, I.uv_MainTex.xy) * _Color;
#if ENABLE_INSTANCE_COLOR && SHADER_TARGET > 30
        c *= I.color;
#endif
        O.Albedo = c.rgb;
        O.Metallic = _Metallic;
        O.Smoothness = _Glossiness;
        O.Alpha = c.a;
        O.Emission += _Emission;
#if ENABLE_INSTANCE_EMISSION
        O.Emission += I.emission;
#endif
    }
#endif // BR_STANDARD

//#ifdef BR_STANDARD_DETAILED
//    void surf(Input I, inout SurfaceOutputStandard O)
//    {
//        fixed4 c = tex2D(_MainTex, I.uv_MainTex) * _Color;
//#ifdef ENABLE_INSTANCE_COLOR
//        c *= I.color;
//#endif // ENABLE_INSTANCE_COLOR
//        O.Albedo = c.rgb;
//        O.Metallic = _Metallic;
//        O.Smoothness = _Glossiness;
//        O.Alpha = c.a;
//        O.Normal = tex2D(_NormalMap, I.uv_MainTex).xyz;
//        O.Specular *= tex2D(_SpecularMap, I.uv_MainTex).x;
//        O.Emission = tex2D(_EmissionMap, I.uv_MainTex).xyz;
//#ifdef ENABLE_INSTANCE_EMISSION
//        O.Emission += I.emission;
//#endif // ENABLE_INSTANCE_EMISSION
//    }
//#endif // BR_STANDARD


#endif // BRSurface_h
