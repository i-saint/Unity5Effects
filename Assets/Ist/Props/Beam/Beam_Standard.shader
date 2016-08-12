// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Ist/Beam/Standard" {
Properties
{
    _Color("Color", Color) = (1,1,1,1)
    _MainTex("Albedo", 2D) = "white" {}
        
    _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
    [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
    _MetallicGlossMap("Metallic", 2D) = "white" {}

    _BumpScale("Scale", Float) = 1.0
    _BumpMap("Normal Map", 2D) = "bump" {}

    _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
    _ParallaxMap ("Height Map", 2D) = "black" {}

    _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
    _OcclusionMap("Occlusion", 2D) = "white" {}

    _EmissionColor("Color", Color) = (0,0,0)
    _EmissionMap("Emission", 2D) = "white" {}
        
    _DetailMask("Detail Mask", 2D) = "white" {}

    _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
    _DetailNormalMapScale("Scale", Float) = 1.0
    _DetailNormalMap("Normal Map", 2D) = "bump" {}

    [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0


    // Blending state
    [HideInInspector] _Mode ("__mode", Float) = 0.0
    [HideInInspector] _SrcBlend ("__src", Float) = 1.0
    [HideInInspector] _DstBlend ("__dst", Float) = 0.0
    [HideInInspector] _ZWrite ("__zw", Float) = 1.0

    _BeamDirection("Beam Direction", Vector) = (0, 0, 1, 1)
}

CGINCLUDE
#define UNITY_SETUP_BRDF_INPUT MetallicSetup

float4 _BeamDirection; // xyz: direction w: length

void BeamTransform(inout float4 vertex, half3 normal)
{
    float3 pos1 = mul(unity_ObjectToWorld, vertex).xyz;
    float3 pos2 = pos1 + normalize(_BeamDirection.xyz) * _BeamDirection.w;
    float3 n = normalize(mul(unity_ObjectToWorld, float4(normal, 0.0)).xyz);
    float t = saturate(dot(-_BeamDirection.xyz, n.xyz) * 1000000);
    float3 pos = lerp(pos2, pos1, t);

    vertex.xyz = mul(unity_WorldToObject, float4(pos,1)).xyz;
}
ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" "DisableBatching"="True" }

        
        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD" 
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 3.0
            // TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
            #pragma exclude_renderers gles
            
            // -------------------------------------
                    
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP 
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP
            
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
                
            #pragma vertex vertForwardBase2
            #pragma fragment fragForwardBase

            #include "UnityStandardCore.cginc"


            VertexOutputForwardBase vertForwardBase2(VertexInput v)
            {
                BeamTransform(v.vertex, v.normal.xyz);
                return vertForwardBase(v);
            }

            ENDCG
        }

        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            // GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
            #pragma exclude_renderers gles

            // -------------------------------------

            
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP
            
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            
            #pragma vertex vertForwardAdd2
            #pragma fragment fragForwardAdd

            #include "UnityStandardCore.cginc"


            VertexOutputForwardAdd vertForwardAdd2(VertexInput v)
            {
                BeamTransform(v.vertex, v.normal.xyz);
                return vertForwardAdd(v);
            }
            ENDCG
        }

        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            Cull Front
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            // TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
            #pragma exclude_renderers gles
            
            // -------------------------------------


            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_shadowcaster

            #pragma vertex vertShadowCaster2
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"


            void vertShadowCaster2(VertexInput v,
            #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                out VertexOutputShadowCaster o,
            #endif
                out float4 opos : SV_POSITION)
            {
                BeamTransform(v.vertex, v.normal.xyz);
                vertShadowCaster(v,
            #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
                    o,
            #endif
                    opos);
            }

            ENDCG
        }

        // ------------------------------------------------------------------
        //  Deferred pass
        Pass
        {
            Name "DEFERRED"
            Tags { "LightMode" = "Deferred" }

            CGPROGRAM
            #pragma target 3.0
            // TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
            #pragma exclude_renderers nomrt gles
            

            // -------------------------------------

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP

            #pragma multi_compile ___ UNITY_HDR_ON
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            
            #pragma vertex vertDeferred2
            #pragma fragment fragDeferred

            #include "UnityStandardCore.cginc"


            VertexOutputDeferred vertDeferred2(VertexInput v)
            {
                BeamTransform(v.vertex, v.normal.xyz);
                return vertDeferred(v);
            }

            ENDCG
        }

        // no Meta pass
    }

    CustomEditor "StandardShaderGUI"
}
