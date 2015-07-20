Shader "DeferredShading/MPGBuffer" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BaseColor ("BaseColor", Vector) = (0.15, 0.15, 0.2, 1.0)
        _GlowColor ("GlowColor", Vector) = (0.75, 0.75, 1.0, 1.0)
        _FadeTime ("Fade Time", Float) = 0.3
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        Cull Back

        CGINCLUDE

        sampler2D _MainTex;
        sampler2D _DataTex;
        float _ParticleSize;
        float _DataTexPitch;
        float4 _BaseColor;
        float4 _GlowColor;
        float _FadeTime;


        struct vs_in
        {
            float4 vertex : POSITION;
            float4 normal : NORMAL;
            float4 texcoord : TEXCOORD0;
        };

        struct ps_in {
            float4 vertex : SV_POSITION;
            float4 screen_pos : TEXCOORD0;
            float4 position : TEXCOORD1;
            float4 normal : TEXCOORD2;
            float4 emission : TEXCOORD3;
            float4 params : TEXCOORD4;
        };

        struct ps_out
        {
            float4 normal : COLOR0;
            float4 position : COLOR1;
            float4 color : COLOR2;
            float4 glow : COLOR3;
        };


        ps_in vert (vs_in v)
        {
            float4 pitch = float4(_DataTexPitch, 0.0, 0.0, 0.0);
            float4 position = tex2Dlod(_DataTex, v.texcoord);
            float4 velocity = tex2Dlod(_DataTex, v.texcoord+pitch);
            float4 params = tex2Dlod(_DataTex, v.texcoord+pitch*2.0);
            float lifetime = params.y;
            v.vertex.xyz *= _ParticleSize * 100.0;
            v.vertex.xyz *= min(1.0, lifetime/_FadeTime);
            v.vertex.xyz += position.xyz;

            ps_in o;
            float4 vmvp = mul(UNITY_MATRIX_MVP, v.vertex);
            o.vertex = vmvp;
            o.screen_pos = vmvp;
            o.position = v.vertex;
            o.normal = v.normal;
            o.params = params;
            float ei = max(velocity.w-2.5, 0.0) * 1.0;
            o.emission = float4(ei,ei,ei,ei) * float4(0.25, 0.05, 0.025, 0.0);
            return o;
        }

        ps_out frag (ps_in i)
        {
            if(i.params.w<=0.0f) {
                discard;
            }
            ps_out o;
            o.normal = i.normal;
            o.position = float4(i.position.xyz, i.screen_pos.z);
            o.color = _BaseColor;
            o.glow = i.emission;
            return o;
        }
        ENDCG


        Pass {
            Name "DepthPrePass"
            Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
            Cull Back
            ColorMask 0
            ZWrite On
            ZTest Less

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma glsl
            ENDCG
        }

        Pass {
            Name "GBuffer"
            Tags { "RenderType"="Opaque" "Queue"="Geometry" }
            Cull Back
            ZWrite Off
            ZTest Equal

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma glsl
            ENDCG
        }
    }
}
