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
#ifndef BR_WITHOUT_INSTANCE_SCALE
    if(GetFlag_Scale()) {
        vertex.xyz *= GetInstanceScale(instance_id);
    }
#endif // BR_WITHOUT_INSTANCE_SCALE
#ifndef BR_WITHOUT_INSTANCE_ROTATION
    if(GetFlag_Rotation()) {
        float3x3 rot = quaternion_to_matrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
        normal.xyz = mul(rot, normal.xyz);
        tangent.xyz = mul(rot, tangent.xyz);
    }
#endif // BR_WITHOUT_INSTANCE_ROTATION
    vertex.xyz += GetInstanceTranslation(instance_id);

#ifndef BR_WITHOUT_INSTANCE_UVOFFSET
    if(GetFlag_UVOffset()) {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
#endif // BR_WITHOUT_INSTANCE_UVOFFSET
#ifndef BR_WITHOUT_INSTANCE_COLOR
    if(GetFlag_Color()) {
        color *= GetInstanceColor(instance_id);
    }
#endif // BR_WITHOUT_INSTANCE_COLOR
#ifndef BR_WITHOUT_INSTANCE_EMISSION
    if(GetFlag_Emission()) {
        emission += GetInstanceEmission(instance_id);
    }
#endif // BR_WITHOUT_INSTANCE_EMISSION
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
        float4 color;
        float4 emission;
    };

    void vert(inout appdata_full v, out Input o)
    {
        UNITY_INITIALIZE_OUTPUT(Input,o);

        float4 color = v.color * g_base_color;
        float4 emission = g_base_emission;
        ApplyInstanceTransform(v.texcoord1.xy, v.vertex, v.normal, v.tangent, v.texcoord.xy, color, emission);

        o.uv_MainTex = v.texcoord.xy;
        o.color = color;
        o.emission = emission;
    }
#endif



// legacy surface
#ifdef BR_SURFACE
    void surf(Input IN, inout SurfaceOutput o)
    {
        fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.color;
        o.Albedo = c.rgb;
        o.Alpha = c.a;
        o.Emission = IN.emission.xyz;
    }
#endif // BR_SURFACE



#ifdef BR_SURFACE_DETAILED
    void surf(Input IN, inout SurfaceOutput o)
    {
        fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.color;
        o.Albedo = c.rgb;
        o.Alpha = c.a;
        o.Normal = tex2D(_NormalMap, IN.uv_MainTex).xyz;
        o.Emission = g_base_emission + tex2D(_EmissionMap, IN.uv_MainTex).xyz;
        o.Specular *= tex2D(_SpecularMap, IN.uv_MainTex).x;
        o.Gloss *= tex2D(_GrossMap, IN.uv_MainTex).x;
    }
#endif // BR_SURFACE_DETAILED



#ifdef BR_STANDARD
    void surf(Input IN, inout SurfaceOutputStandard o)
    {
        fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
        o.Albedo = c.rgb;
        o.Metallic = _Metallic;
        o.Smoothness = _Glossiness;
        o.Alpha = c.a;
    }
#endif // BR_STANDARD


#endif // BRSurface_h
