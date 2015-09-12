Shader "Ist/ProceduralModeling/Metaball" {
Properties {
    _GridSize("Grid Size", Float) = 0.26
    _CubeSize("Cube Size", Float) = 0.22
    _Clipping("Clipping", Int) = 2

    _Color("Albedo", Color) = (0.75, 0.75, 0.8, 1.0)
    _SpecularColor("Specular", Color) = (0.2, 0.2, 0.2, 1.0)
    _Smoothness("Smoothness", Range(0, 1)) = 0.7
    _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 1.0)

    _OffsetPosition("OffsetPosition", Vector) = (0, 0, 0, 0)
    _Scale("Scale", Vector) = (1, 1, 1, 0)
    _CutoutDistance("Cutout Distance", Float) = 0.01

    _ZTest("ZTest", Int) = 4

    [Toggle(ENABLE_DEPTH_OUTPUT)] _DepthOutput("Depth Output", Float) = 0
}

CGINCLUDE

struct Metaball
{
    float3 position;
    float radius;
    float softness;
    float negative;
    float padding[2];
};

int _NumEntities;
StructuredBuffer<Metaball> _Entities;

#define MAX_MARCH_STEPS 24

#include "ProceduralModeling.cginc"


void initialize(inout raymarch_data R)
{
}

float map(float3 pg)
{
    float d = dot(_Scale, 1.0);
    for (int i = 0; i < _NumEntities; ++i) {
        Metaball mb = _Entities[i];
        if (mb.negative) {
            d = soft_max(d, -sdSphere(pg - mb.position, mb.radius), mb.softness);
        }
        else {
            d = soft_min(d, sdSphere(pg - mb.position, mb.radius), mb.softness);
        }
    }
    d = max(d, sdBox(localize(pg), _Scale*0.5));
    return d;
}

void posteffect(inout gbuffer_out O, vs_out I, raymarch_data R)
{
}

#include "Framework.cginc"
ENDCG

SubShader {
    Tags{ "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }

    Pass{
        Tags{ "LightMode" = "ShadowCaster" }
        Cull Front
        ColorMask 0
        CGPROGRAM
#pragma vertex vert_shadow
#pragma fragment frag_shadow
        ENDCG
    }

    Pass {
        Tags { "LightMode" = "Deferred" }
        Stencil {
            Comp Always
            Pass Replace
            Ref 128
        }
        ZTest [_ZTest]
        Cull Back
CGPROGRAM
#pragma target 5.0
#pragma vertex vert
#pragma fragment frag_gbuffer
#pragma multi_compile ___ UNITY_HDR_ON
#pragma multi_compile ___ ENABLE_DEPTH_OUTPUT
ENDCG
    }
}

Fallback Off
}
