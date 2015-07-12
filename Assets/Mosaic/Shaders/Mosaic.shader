Shader "Mosaic/Mosaic" {
Properties {
    _BlockSize ("Block Size", Float) = 15.0
}

CGINCLUDE
#include "UnityCG.cginc"
#include "Assets/FrameBufferUtils/Shaders/GBufferUtils.cginc"

float _BlockSize;

struct v2f {
    float4 pos : POSITION;
    float4 spos : TEXCOORD0;
};  

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
    return GetFrameBuffer(t);
}
ENDCG

Subshader {
    Tags { "Queue"="Transparent+90" "RenderType"="Opaque" }
    ZTest Less Cull Back ZWrite Off
    Fog { Mode off }

    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
