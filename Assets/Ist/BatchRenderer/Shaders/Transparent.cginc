#ifndef BRTransparent_h
#define BRTransparent_h

#include "UnityCG.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/BatchRenderer.cginc"


void ApplyInstanceTransformSimplified(float2 id, inout float4 vertex, inout float2 texcoord, inout float4 color)
{
    int instance_id = GetBatchBegin() + id.x;
    if(instance_id >= GetNumInstances()) {
        vertex.xyz *= 0.0;
        return;
    }

    vertex.xyz *= GetBaseScale();
#if ENABLE_INSTANCE_SCALE
    {
        vertex.xyz *= GetInstanceScale(instance_id);
    }
#endif
#if ENABLE_INSTANCE_ROTATION
    {
        float3x3 rot = quaternion_to_matrix33(GetInstanceRotation(instance_id));
        vertex.xyz = mul(rot, vertex.xyz);
    }
#endif
    vertex.xyz += GetInstanceTranslation(instance_id);
    vertex = mul(UNITY_MATRIX_VP, vertex);

#if ENABLE_INSTANCE_UVOFFSET
    {
        float4 u = GetInstanceUVOffset(instance_id);
        texcoord = texcoord*u.xy + u.zw;
    }
#endif
#if ENABLE_INSTANCE_COLOR
    {
        color *= GetInstanceColor(instance_id);
    }
#endif
}


#ifdef BR_TRANSPARENT
    sampler2D _MainTex;
    float4 g_base_color;

    struct appdata_t {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;
        float2 texcoord1 : TEXCOORD1;
    };

    struct v2f {
        float4 vertex : SV_POSITION;
        float2 texcoord : TEXCOORD0;
        float4 color : TEXCOORD1;
    };

    v2f vert(appdata_t v)
    {
        float4 color = g_base_color;
        ApplyInstanceTransformSimplified(v.texcoord1, v.vertex, v.texcoord, color);

        v2f o;
        o.vertex = v.vertex;
        o.texcoord = v.texcoord;
        o.color = color;
        return o;
    }

    float4 frag(v2f i) : SV_Target
    {
        float4 color = tex2D(_MainTex, i.texcoord) * i.color;
        return color;
    }
#endif // BR_TRANSPARENT

#endif // BRTransparent_h
