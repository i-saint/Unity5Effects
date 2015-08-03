Shader "Ist/MosaicField" {
Properties {
    _BlockSize ("Block Size", Float) = 15.0
}

CGINCLUDE
#include "UnityCG.cginc"

sampler2D _FrameBuffer1;
float _BlockSize;

struct v2f {
    float4 vertex : POSITION;
    float4 screen_pos : TEXCOORD0;
};  

v2f vert (appdata_img v)
{
    v2f o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screen_pos = ComputeScreenPos(o.vertex);
    return o;
}
    
half4 frag (v2f i) : SV_Target
{
    float2 t = i.screen_pos.xy / i.screen_pos.w;
    float2 b = (_ScreenParams.zw-1.0) * _BlockSize;
    t = t - fmod(t, b) + b*0.5;
    return tex2D(_FrameBuffer1, t);
}
ENDCG

Subshader {
    Tags { "Queue"="Transparent+90" "RenderType"="Opaque" }
    ZTest Less Cull Back ZWrite Off
    Fog { Mode off }

    GrabPass {
        "_FrameBuffer1"
    }
    Pass {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}
}
