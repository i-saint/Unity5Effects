Shader "DeferredShading/PostEffect/Reflection" {
Properties {
    g_intensity ("Intensity", Float) = 1.0
    _RayMarchDistance ("Ray March Distance", Float) = 0.2
    _RayDiffusion  ("Ray Diffusion", Float) = 0.01
    _FalloffDistance  ("Falloff Distance", Float) = 10.0
    _MaxAccumulation  ("Max Accumulation", Float) = 50.0
}
SubShader {
    Tags { "RenderType"="Opaque" }
    Blend Off
    ZTest Always
    ZWrite Off
    Cull Back

    CGINCLUDE
    #include "Compat.cginc"

    sampler2D g_frame_buffer;
    sampler2D g_position_buffer;
    sampler2D g_prev_position_buffer;
    sampler2D g_normal_buffer;
    sampler2D _PrevResult;
    float g_intensity;
    float _RayMarchDistance;
    float _RayDiffusion;
    float _FalloffDistance;
    float _MaxAccumulation;
    float4x4 _ViewProjInv;
    float4x4 _PrevViewProj;

    struct ia_out
    {
        float4 vertex : POSITION;
    };

    struct vs_out
    {
        float4 vertex : SV_POSITION;
        float4 screen_pos : TEXCOORD0;
    };

    struct ps_out
    {
        float4 color : COLOR0;
    };


    vs_out vert (ia_out v)
    {
        vs_out o;
        o.vertex = v.vertex;
        o.screen_pos = v.vertex;
        return o;
    }

    ps_out frag_dumb(vs_out i)
    {
        float2 coord = (i.screen_pos.xy / i.screen_pos.w + 1.0) * 0.5;
        // see: http://docs.unity3d.com/Manual/SL-PlatformDifferences.html
        #if UNITY_UV_STARTS_AT_TOP
            coord.y = 1.0-coord.y;
        #endif

        float4 p = tex2D(g_position_buffer, coord);
        if(p.w==0.0) { discard; }

        float4 n = tex2D(g_normal_buffer, coord);
        float3 camDir = normalize(p.xyz - _WorldSpaceCameraPos);


        ps_out r;
        r.color = 0.0;

        int NumRays = 4;
        float3 refdir = reflect(camDir, n.xyz);
        float s = g_intensity / NumRays;
        float3 noises[9] = {
            float3(0.0, 0.0, 0.0),
            float3(0.1080925165271518, -0.9546740999616308, -0.5485116160762447),
            float3(-0.4753686437884934, -0.8417212473681748, 0.04781893710693619),
            float3(0.7242715177221273, -0.6574584801064549, -0.7170447827462747),
            float3(-0.023355087558461607, 0.7964400038854089, 0.35384090347421204),
            float3(-0.8308210026544296, -0.7015103725420933, 0.7781031130099072),
            float3(0.3243705688309195, 0.2577797517167695, 0.012345938868925543),
            float3(0.31851240326305463, -0.22207894547397555, 0.42542751740434204),
            float3(-0.36307729185097637, -0.7307245945773899, 0.6834118993358385)
        };
        for(int j=0; j<NumRays; ++j) {
            float4 tpos = mul(UNITY_MATRIX_MVP, float4(p.xyz+(refdir+noises[j]*0.04)*_RayMarchDistance, 1.0) );
            float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
            #if UNITY_UV_STARTS_AT_TOP
                tcoord.y = 1.0-tcoord.y;
            #endif
            float4 reffragpos = tex2D(g_position_buffer, tcoord);
            r.color.xyz += tex2D(g_frame_buffer, tcoord).xyz * s;
        }
        r.color *= n.w;
        return r;
    }


    float jitter(float3 p)
    {
        float v = dot(p,1.0)+_Time.y;
        return frac(sin(v)*43758.5453);
    }
    float3 diverge(float3 p, float d)
    {
        p *= _Time.y;
        return (float3(frac(sin(p)*43758.5453))*2.0-1.0) * d;
    }

    ps_out frag_precise(vs_out i)
    {
        float2 coord = (i.screen_pos.xy / i.screen_pos.w + 1.0) * 0.5;
        // see: http://docs.unity3d.com/Manual/SL-PlatformDifferences.html
        #if UNITY_UV_STARTS_AT_TOP
            coord.y = 1.0-coord.y;
        #endif

        ps_out r;
        r.color = 0.0;

        float4 p = tex2D(g_position_buffer, coord);
        if(p.w==0.0) { return r; }

        float4 n = tex2D(g_normal_buffer, coord);
        float3 camDir = normalize(p.xyz - _WorldSpaceCameraPos);

        float4 prev_result;
        float4 prev_pos;
        {
            //float4 tpos = mul(UNITY_MATRIX_VP, float4(p.xyz, 1.0) );
            float4 tpos = mul(_PrevViewProj, float4(p.xyz, 1.0) );
            float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
        #if UNITY_UV_STARTS_AT_TOP
        //	tcoord.y = 1.0-tcoord.y;
        #endif
            prev_result = tex2D(_PrevResult, tcoord);
            prev_pos = tex2D(g_prev_position_buffer, tcoord);
        }

        float diff = length(p.xyz-prev_pos.xyz);


        float2 hit_coord;
        int MaxMarch = 24;
        float MaxDistance = _RayMarchDistance*(MaxMarch);
        float3 refdir = reflect(camDir, n.xyz) + diverge(p, _RayDiffusion);
        float adv = _RayMarchDistance * jitter(p);

        for(int k=0; k<MaxMarch; ++k) {
            adv = adv + _RayMarchDistance;
            float4 tpos = mul(UNITY_MATRIX_MVP, float4((p.xyz+refdir*adv), 1.0) );
            float2 tcoord = (tpos.xy / tpos.w + 1.0) * 0.5;
            #if UNITY_UV_STARTS_AT_TOP
                tcoord.y = 1.0-tcoord.y;
            #endif
            float4 reffragpos = tex2D(g_position_buffer, tcoord);
            if(reffragpos.w!=0 && reffragpos.w<tpos.z && reffragpos.w>tpos.z-_RayMarchDistance*1.0) {
                hit_coord = tcoord;
                break;
            }
            if(tcoord.x>1.0 || tcoord.x<0.0 || tcoord.y>1.0 || tcoord.y<0.0) {
                adv = MaxDistance;
                break;
            }
        }

        prev_result.w *= max(1.0-(0.01+diff*50.0), 0.0);
        float3 base_color = prev_result.rgb * prev_result.w;
        float3 blend_color = 0.0;
        if(adv<MaxDistance && dot(refdir, tex2D(g_normal_buffer, hit_coord).xyz)<0.0) {
            blend_color = tex2D(g_frame_buffer, hit_coord).rgb * g_intensity * max(1.0 - (1.0/_FalloffDistance * adv), 0.0);
        }
        r.color.w = prev_result.w+1.0;
        r.color.rgb = (base_color+blend_color)/r.color.w;
        r.color.w = min(r.color.w, _MaxAccumulation);
        return r;
    }
    ENDCG

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_dumb
        #pragma target 3.0
        #ifdef SHADER_API_OPENGL 
            #pragma glsl
        #endif
        ENDCG
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag_precise
        #pragma target 3.0
        #ifdef SHADER_API_OPENGL 
            #pragma glsl
        #endif
        ENDCG
    }
}
}
