Shader "Ist/ProceduralModeling/Hexnizer" {
Properties {
    _GridSize("Grid Size", Float) = 1.2
    _HexRadius("Hex Radius", Float) = 0.35

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

//#define ENABLE_TRACEBACK 1
//#define MAX_TRACEBACK_STEPS 16

#define ENABLE_BOX_CLIPPING 1
//#define ENABLE_SPHERE_CLIPPING 1

#define ENABLE_DEPTH_OUTPUT 1

#define HEX_PLANE xz
#define HEX_DIR y

#define ENABLE_BUMP 1
#define BUMP_STRENGTH 0.5

float _GridSize;
float _HexRadius;


float map(float3 pg)
{
    float3 pl = localize(pg);
    float3 p = pl;

    float2 grid = float2(0.692, 0.4) * _GridSize;
    float2 grid_half = grid*0.5;
    float radius = 0.22 * _HexRadius;

    float2 p1 = modc(p.HEX_PLANE, grid) - grid_half;
    float2 p2 = modc(p.HEX_PLANE +grid_half, grid) - float2(grid_half);
    float h1 = sdHex(float2(p1.x,p1.y), radius);
    float h2 = sdHex(float2(p2.x,p2.y), radius);

#if ENABLE_BUMP
    float2 g1 = float2(ceil(p.HEX_PLANE / grid));
    float2 g2 = float2(ceil((p.HEX_PLANE + grid_half) / grid));
    float rxz = iq_rand(g1).x;
    float ryz = iq_rand(g2).x;
    float d1 = p.HEX_DIR - _Scale.HEX_DIR*0.5 + rxz*BUMP_STRENGTH;
    float d2 = p.HEX_DIR - _Scale.HEX_DIR*0.5 + ryz*BUMP_STRENGTH;
    h1 = max(h1, d1);
    h2 = max(h2, d2);
#endif // ENABLE_BUMP

    return max(min(h1, h2), 0.0);
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
