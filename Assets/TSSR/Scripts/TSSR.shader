Shader "Mosaic/Mosaic" {

Properties {
}

CGINCLUDE
#include "UnityCG.cginc"
    
struct v2f {
    float4 pos : POSITION;
    float4 spos : TEXCOORD0;
};    
sampler2D _ScreenCopyTexture;
float2 _BlockSize;
    
v2f vert (appdata_img v)
{
    v2f o;
    o.pos = o.spos = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}
    
half4 frag (v2f i) : SV_Target
{
    float2 t = i.spos.xy / i.spos.w * 0.5 + 0.5;
    float2 b = (_ScreenParams.zw-1.0) * _BlockSize;
    t = t - fmod(t, b) + b*0.5;
#if UNITY_UV_STARTS_AT_TOP
    t.y = 1.0 - t.y;
#endif // UNITY_UV_STARTS_AT_TOP
    return tex2D(_ScreenCopyTexture, t);
}
ENDCG
    
Subshader {
    Tags { "Queue" = "Overlay" }
    Pass {
        ZTest Less Cull Back ZWrite Off
        Fog { Mode off }

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}

Fallback off
}
