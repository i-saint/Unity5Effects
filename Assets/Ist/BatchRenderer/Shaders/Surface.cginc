#ifndef BRSurface_h
#define BRSurface_h

#include "UnityCG.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/BatchRenderer.cginc"



void ApplyInstanceTransform2(int instance_id, inout float4 vertex, inout float3 normal, inout float4 tangent, inout float2 texcoord, inout float4 color, inout float4 emission)
{
    if(instance_id >= GetNumInstances()) {
        vertex.xyz *= 0.0;
        return;
    }
    vertex.xyz *= GetBaseScale();
#ifdef ENABLE_INSTANCE_SCALE
    if (GetFlag_Scale()) {
        vertex.xyz *= GetInstanceScale(instance_id);
    }
#endif // ENABLE_INSTANCE_SCALE
#ifdef ENABLE_INSTANCE_ROTATION
    if (GetFlag_Rotation()) {
        float3x3 rot = quaternion_to_matrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
        normal.xyz = mul(rot, normal.xyz);
        tangent.xyz = mul(rot, tangent.xyz);
    }
#endif // ENABLE_INSTANCE_ROTATION
    vertex.xyz += GetInstanceTranslation(instance_id);

#ifdef ENABLE_INSTANCE_UVOFFSET
    if (GetFlag_UVOffset()) {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
#endif // ENABLE_INSTANCE_UVOFFSET
#ifdef ENABLE_INSTANCE_COLOR
    if (GetFlag_Color()) {
        color *= GetInstanceColor(instance_id);
    }
#endif // ENABLE_INSTANCE_COLOR
#ifdef ENABLE_INSTANCE_EMISSION
    if (GetFlag_Emission()) {
        emission += GetInstanceEmission(instance_id);
    }
#endif // ENABLE_INSTANCE_EMISSION
}

void ApplyInstanceTransform(float2 id, inout float4 vertex, inout float3 normal, inout float4 tangent, inout float2 texcoord, inout float4 color, inout float4 emission)
{
    int instance_id = GetBatchBegin() + id.x;
    ApplyInstanceTransform2(instance_id, vertex, normal, tangent, texcoord, color, emission);
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
    fixed4 g_base_emission;

    struct Input {
        float2 uv_MainTex;
#ifdef ENABLE_INSTANCE_COLOR
        float4 color;
#endif // ENABLE_INSTANCE_COLOR
#ifdef ENABLE_INSTANCE_EMISSION
        float4 emission;
#endif // ENABLE_INSTANCE_EMISSION
    };

    void vert(inout appdata_full V, out Input O)
    {
        UNITY_INITIALIZE_OUTPUT(Input,O);

        float4 color = V.color * g_base_color;
        float4 emission = g_base_emission;
        ApplyInstanceTransform(V.texcoord1.xy, V.vertex, V.normal, V.tangent, V.texcoord.xy, color, emission);

        O.uv_MainTex = V.texcoord.xy;
#ifdef ENABLE_INSTANCE_COLOR
        O.color = color;
#endif // ENABLE_INSTANCE_COLOR
#ifdef ENABLE_INSTANCE_EMISSION
        O.emission = emission;
#endif // ENABLE_INSTANCE_EMISSION
    }
#endif



// legacy surface
#ifdef BR_SURFACE
    void surf(Input I, inout SurfaceOutput O)
    {
        fixed4 c = tex2D(_MainTex, I.uv_MainTex);
#ifdef ENABLE_INSTANCE_COLOR
        c *= I.color;
#endif // ENABLE_INSTANCE_COLOR
        O.Albedo = c.rgb;
        O.Alpha = c.a;
        O.Emission = g_base_emission;
#ifdef ENABLE_INSTANCE_EMISSION
        O.Emission += I.emission.xyz;
#endif // ENABLE_INSTANCE_EMISSION
    }
#endif // BR_SURFACE



#ifdef BR_SURFACE_DETAILED
    void surf(Input I, inout SurfaceOutput O)
    {
        fixed4 c = tex2D(_MainTex, I.uv_MainTex);
#ifdef ENABLE_INSTANCE_COLOR
        c *= I.color;
#endif // ENABLE_INSTANCE_COLOR
        O.Albedo = c.rgb;
        O.Alpha = c.a;
        O.Normal = tex2D(_NormalMap, I.uv_MainTex).xyz;
        O.Specular *= tex2D(_SpecularMap, I.uv_MainTex).x;
        O.Gloss *= tex2D(_GrossMap, I.uv_MainTex).x;
        O.Emission = g_base_emission + tex2D(_EmissionMap, I.uv_MainTex).xyz;
#ifdef ENABLE_INSTANCE_EMISSION
        O.Emission += I.emission.xyz;
#endif // ENABLE_INSTANCE_EMISSION
    }
#endif // BR_SURFACE_DETAILED



#ifdef BR_STANDARD
    void surf(Input I, inout SurfaceOutputStandard O)
    {
        fixed4 c = tex2D(_MainTex, I.uv_MainTex) * _Color;
#ifdef ENABLE_INSTANCE_COLOR
        c *= I.color;
#endif // ENABLE_INSTANCE_COLOR
        O.Albedo = c.rgb;
        O.Metallic = _Metallic;
        O.Smoothness = _Glossiness;
        O.Alpha = c.a;
#ifdef ENABLE_INSTANCE_EMISSION
        O.Emission = I.emission;
#endif // ENABLE_INSTANCE_EMISSION
    }
#endif // BR_STANDARD


#endif // BRSurface_h
