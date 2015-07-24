Shader "IstEffects/StencilShadows/Stencil"
{
SubShader
{
CGINCLUDE
#include "UnityCG.cginc"

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 screen_pos : TEXCOORD0;
};

struct ps_out
{
    float4 color : SV_Target;
};


float4 _StencilParams1;
#define _Center     _StencilParams1.xyz
#define _Direction  _StencilParams1.xyz
#define _Distance   _StencilParams1.w


void Project(inout float3 pos, float3 n)
{
    float3 dir = 0.0;
    float dist = 0.0;
#if PROJECTION_POINT
    dir = normalize(pos - _Center);
    dist = length(pos - _Center);
#endif
#if PROJECTION_DIRECTION
    dir = _Direction;
    dist = _Distance;
#endif
#if ENABLE_INVERSE
    dir *= -1.0;
#endif
    float proj = dot(-dir.xyz, n.xyz)>0.0 ? 1.0 : 0.0;
    pos += dir * (dist * proj);
}


vs_out vert(ia_out v)
{
    float3 pos = mul(_Object2World, v.vertex).xyz;
    float3 n = normalize(mul(_Object2World, float4(v.normal.xyz, 0.0)).xyz);
    Project(pos, n);

    vs_out o;
    o.vertex = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}

vs_out vert_simple(ia_out v)
{
    vs_out o;
    o.vertex = o.screen_pos = v.vertex;
    o.screen_pos.y *= _ProjectionParams.x;
    return o;
}

ps_out frag(vs_out i)
{
    ps_out r;
    r.color = 0.0;
    r.color.r = 0.2;
    return r;
}
ENDCG

    // front
    Pass {
        Stencil{
            Ref [_StencilRef]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp Always
            Pass IncrSat
        }
        Cull Back
        ZTest Less
        ZWrite Off
        //ColorMask 0
        Blend One One

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile PROJECTION_POINT PROJECTION_DIRECTION
        #pragma multi_compile ___ ENABLE_INVERSE
        ENDCG
    }

    // back
    Pass {
        Stencil{
            Ref [_StencilRef]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp Always
            Pass DecrSat
        }
        Cull Front
        ZTest Less
        ZWrite Off
        //ColorMask 0
        Blend One One

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile PROJECTION_POINT PROJECTION_DIRECTION
        #pragma multi_compile ___ ENABLE_INVERSE
        ENDCG
    }

    // clear
    Pass {
        Stencil{
            Ref 0
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp Always
            Pass Replace
        }
        Cull Off
        ZTest Off
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert_simple
        #pragma fragment frag
        ENDCG
    }
}
}
