Shader "Mosaic/Dummy" {

CGINCLUDE
#include "UnityCG.cginc"
    
struct v2f {
    float4 pos : POSITION;
};    
sampler2D _ScreenCopyTexture;
    
v2f vert(appdata_img v)
{
    v2f o;
    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    return o;
}
    
half4 frag(v2f i) : SV_Target
{
    return 0.0;
}
ENDCG
    
Subshader {
    Pass {
        ZWrite Off
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        ENDCG
    }
}

Fallback off
}
