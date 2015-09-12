Shader "Ist/ProceduralModeling/Cubenizer Punctured" {
Properties {
    _GridSize("Grid Size", Float) = 0.26
    _CubeSize("Cube Size", Float) = 0.22
    _BumpHeight("Bump Height", Float) = 0.15
    _AnimationSpeed("Animation Speed", Float) = 1.0
    _PuncturePattern("Puncture Pattern", Int) = 1
    _AnimationPattern("Animation Pattern", Int) = 0
    _Clipping("Clipping", Int) = 1

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
#define MAX_MARCH_STEPS 8

#define BUMP_DIR y
#define BUMP_PLANE xz

#include "Cubenizer.cginc"
ENDCG

SubShader{
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

Pass{
    Tags{ "LightMode" = "Deferred" }
    Stencil{
    Comp Always
    Pass Replace
    Ref 128
}
ZTest[_ZTest]
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
