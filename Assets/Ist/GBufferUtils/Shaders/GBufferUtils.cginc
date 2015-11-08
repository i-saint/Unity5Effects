#include "UnityCG.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"

// G-Buffers (Unity internals)
sampler2D _CameraGBufferTexture0;   // diffuse color (rgb), occlusion (a)
sampler2D _CameraGBufferTexture1;   // spec color (rgb), smoothness (a)
sampler2D _CameraGBufferTexture2;   // normal (rgb), --unused, very low precision-- (a) 
sampler2D _CameraGBufferTexture3;   // emission (rgb), --unused-- (a)
#ifndef UNITY_DEFERRED_LIBRARY_INCLUDED
sampler2D_float _CameraDepthTexture;
#endif // UNITY_DEFERRED_LIBRARY_INCLUDED
sampler2D _VelocityBuffer;
sampler2D _ContinuityBuffer;

// not Unity internals
sampler2D _PrevCameraGBufferTexture0;   // diffuse color (rgb), occlusion (a)
sampler2D _PrevCameraGBufferTexture1;   // spec color (rgb), smoothness (a)
sampler2D _PrevCameraGBufferTexture2;   // normal (rgb), --unused, very low precision-- (a) 
sampler2D _PrevCameraGBufferTexture3;   // emission (rgb), --unused-- (a)
sampler2D_float _PrevCameraDepthTexture;

sampler2D _FrameBuffer;
sampler2D _PrevFrameBuffer;

float4x4 _InvViewProj;
float4x4 _PrevViewProj;
float4x4 _PrevInvViewProj;
float4x4 _PrevView;
float4x4 _PrevProj;

// casting float4x4 to float3x3 causes compile error on some platforms. this is workaround for it.
float3x3 tofloat3x3(float4x4 v)
{
    return float3x3(v[0].xyz, v[1].xyz, v[2].xyz);
}

half4 GetAlbedo(float2 uv)          { return tex2D(_CameraGBufferTexture0, uv); }
half4 GetSpecular(float2 uv)        { return tex2D(_CameraGBufferTexture1, uv); }
half3 GetNormal(float2 uv)          { return tex2D(_CameraGBufferTexture2, uv).xyz * 2.0 - 1.0; }
half4 GetEmission(float2 uv)        { return tex2D(_CameraGBufferTexture3, uv); }
float GetDepth(float2 uv)           { return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv); }
float GetLinearDepth(float2 uv)     { return LinearEyeDepth(GetDepth(uv)); }
half4 GetFrameBuffer(float2 uv)     { return tex2D(_FrameBuffer, uv); }
half4 GetVelocity(float2 uv)        { return tex2D(_VelocityBuffer, uv); }
half4 GetContinuity(float2 uv)      { return tex2D(_ContinuityBuffer, uv); }

float3 GetPosition(float2 screen_position, float depth)
{
    float4 pos4 = mul(_InvViewProj, float4(screen_position, depth, 1.0));
    return pos4.xyz / pos4.w;
}
float3 GetPosition(float2 uv)
{
    float2 screen_position = uv * 2.0 - 1.0;
    float depth = GetDepth(uv);
    return GetPosition(screen_position, depth);
}

float3 GetPositionByPrevMatrix(float2 screen_position, float depth)
{
    float4 pos4 = mul(_PrevInvViewProj, float4(screen_position, depth, 1.0));
    return pos4.xyz / pos4.w;
}
float3 GetPositionByPrevMatrix(float2 uv)
{
    float2 screen_position = uv * 2.0 - 1.0;
    float depth = GetDepth(uv).x;
    return GetPositionByPrevMatrix(screen_position, depth);
}

float3 GetViewPosition(float2 screen_position, float linear_depth)
{
    float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
    return float3(screen_position / p11_22, 1.0) * linear_depth;

}
float3 GetViewPosition(float2 uv)
{
    float linear_depth = GetLinearDepth(uv);
    return GetViewPosition(uv * 2.0 - 1.0, linear_depth);

}


half4 GetPrevAlbedo(float2 uv)      { return tex2D(_PrevCameraGBufferTexture0, uv); }
half4 GetPrevSpecular(float2 uv)    { return tex2D(_PrevCameraGBufferTexture1, uv); }
half3 GetPrevNormal(float2 uv)      { return tex2D(_PrevCameraGBufferTexture2, uv).xyz * 2.0 - 1.0; }
half4 GetPrevEmission(float2 uv)    { return tex2D(_PrevCameraGBufferTexture3, uv); }
float GetPrevDepth(float2 uv)       { return SAMPLE_DEPTH_TEXTURE(_PrevCameraDepthTexture, uv); }
float GetPrevLinearDepth(float2 uv) { return LinearEyeDepth(GetPrevDepth(uv)); }
half4 GetPrevFrameBuffer(float2 uv) { return tex2D(_PrevFrameBuffer, uv); }

float3 GetPrevPosition(float2 screen_position, float depth)
{
    float4 pos4 = mul(_PrevInvViewProj, float4(screen_position, depth, 1.0));
    return pos4.xyz / pos4.w;
}

float3 GetPrevPosition(float2 uv)
{
    float2 screen_position = uv * 2.0 - 1.0;
    float depth = GetPrevDepth(uv);
    return GetPrevPosition(screen_position, depth);
}
