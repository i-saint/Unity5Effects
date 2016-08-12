// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Ist/Beam/Transparent" {
Properties {
    _SrcBlend("SrcBlend", Int) = 1
    _DstBlend("DstBlend", Int) = 1
    _ZWrite("ZWrite", Int) = 0

    _Color("Color", Color) = (0.5, 0.5, 0.5, 1)
    _BeamDirection("Beam Direction", Vector) = (0, 0, 1, 1)
}

SubShader
{
    Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching" = "True" }

CGINCLUDE

float4 _Color;
float4 _BeamDirection; // xyz: direction w: length

struct ia_out
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
};

struct vs_out
{
    float4 vertex : SV_POSITION;
    float4 world_pos : TEXCOORD1;
    float4 normal : TEXCOORD2;
};

struct ps_out
{
    half4 color : SV_Target;
};


vs_out vert(ia_out v)
{
    float3 pos1 = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 pos2 = pos1 + normalize(_BeamDirection.xyz) * _BeamDirection.w;
    float3 n = normalize(mul(unity_ObjectToWorld, float4(v.normal.xyz,0.0)).xyz);
    float t = saturate(dot(-_BeamDirection.xyz, n.xyz) * 1000000);
    float3 pos = lerp(pos2, pos1, t);

    vs_out o;
    o.vertex = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
    o.world_pos = float4(pos, 1.0);
    o.normal = float4(n, 0.0);
    return o;
}

ps_out frag(vs_out i)
{
    float3 cam_dir = normalize(_WorldSpaceCameraPos.xyz - i.world_pos.xyz);
    float s = pow(abs(dot(cam_dir, i.normal.xyz)), 2.);

    ps_out r;
    r.color = _Color * s;
    return r;
}
ENDCG

    Pass {
        Blend[_SrcBlend][_DstBlend]
        ZWrite [_ZWrite]

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
