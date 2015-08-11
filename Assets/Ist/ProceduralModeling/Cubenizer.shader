Shader "Ist/ProceduralModeling/Cubenizer" {
Properties {
    _GridSize("Grid Size", Float) = 0.26
    _CubeSize("Cube Size", Float) = 0.22

    _Color("Albedo", Color) = (0.75, 0.75, 0.8, 1.0)
    _SpecularColor("Specular", Color) = (0.2, 0.2, 0.2, 1.0)
    _Smoothness("Smoothness", Range(0, 1)) = 0.7
    _EmissionColor("Emission", Color) = (0.0, 0.0, 0.0, 1.0)

    _OffsetPosition("OffsetPosition", Vector) = (0, 0, 0, 0)
    _Scale("Scale", Vector) = (1, 1, 1, 0)
    _CutoutDistance("Cutout Distance", Float) = 0.01

    _ZTest("ZTest", Int) = 4
}

CGINCLUDE
#include "UnityStandardCore.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/Math.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/Geometry.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/BuiltinVariablesExt.cginc"
#include "ProceduralModeling.cginc"

#define MAX_MARCH_STEPS 8

#define ENABLE_BOX_CLIPPING 1
//#define ENABLE_SPHERE_CLIPPING 1

#define ENABLE_DEPTH_OUTPUT 1

#define ENABLE_PUNCTURE 1
#define ENABLE_BUMP 1
#define BUMP_DIR y
#define BUMP_PLANE xz
#define BUMP_STRENGTH 0.25

float _GridSize;
float _CubeSize;


float map(float3 pg)
{
    float3 pl = localize(pg);
    float3 p = pl;

#if ENABLE_BUMP
    float bump = BUMP_STRENGTH;
    float r = iq_rand(floor((p.BUMP_PLANE) / _GridSize)).x;
    p.BUMP_DIR -= _GridSize*bump*r + _GridSize*(1.0-bump);
#endif // ENABLE_BUMP

    float3 p1 = modc(p, _GridSize) - _GridSize*0.5;
    float d1 = sdBox(p1, _CubeSize*0.5);
#if ENABLE_PUNCTURE
    d1 = max(d1, -sdBox(p1, float3(_CubeSize.xx*0.25, 1.0)));
    d1 = max(d1, -sdBox(p1, float3(1.0, _CubeSize.xx*0.25)));
    d1 = max(d1, -sdBox(p1, float3(_CubeSize.x*0.25, 1.0, _CubeSize.x*0.25)));
#endif
#if ENABLE_BUMP
    d1 = max(d1, p.BUMP_DIR - _GridSize*0.9);
#endif // ENABLE_BUMP

    return max(d1, 0.0);
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
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag_gbuffer
#pragma multi_compile ___ UNITY_HDR_ON
#pragma multi_compile ___ ENABLE_DEPTH_OUTPUT
ENDCG
    }
}

Fallback Off
}
