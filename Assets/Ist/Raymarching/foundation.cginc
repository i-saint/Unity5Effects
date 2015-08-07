#ifndef foundation_h
#define foundation_h

#include "UnityCG.cginc"

#define PI      3.1415926535897932384626433832795

float DegToRad(float  deg) { return deg*PI/180.0; }
float2 DegToRad(float2 deg) { return deg*PI/180.0; }
float3 DegToRad(float3 deg) { return deg*PI/180.0; }
float4 DegToRad(float4 deg) { return deg*PI/180.0; }

float  modc(float  a, float  b) { return a - b * floor(a/b); }
float2 modc(float2 a, float2 b) { return a - b * floor(a/b); }
float3 modc(float3 a, float3 b) { return a - b * floor(a/b); }
float4 modc(float4 a, float4 b) { return a - b * floor(a/b); }

float3 GetCameraPosition()    { return _WorldSpaceCameraPos; }
float3 GetCameraForward()     { return -UNITY_MATRIX_V[2].xyz; }
float3 GetCameraUp()          { return UNITY_MATRIX_V[1].xyz; }
float3 GetCameraRight()       { return UNITY_MATRIX_V[0].xyz; }
float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }

float ComputeDepth(float4 clippos)
{
#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    return ((clippos.z / clippos.w) + 1.0) * 0.5;
#else
    return clippos.z / clippos.w;
#endif
}

sampler2D g_depth_prev;
sampler2D g_depth;
sampler2D g_velocity;

float cross_depth_sample(float2 t, sampler2D s, float o)
{
    float2 p = (_ScreenParams.zw - 1.0)*o;
    float d1 = tex2D(s, t).x;
    float d2 = min(
        min(tex2D(s, t+float2( p.x, 0.0)).x, tex2D(s, t+float2(-p.x, 0.0))).x,
        min(tex2D(s, t+float2( 0.0, p.y)).x, tex2D(s, t+float2( 0.0,-p.y))).x );
    return min(d1, d2);
}

float sample_prev_depth(float2 t)
{
    return max(tex2D(g_depth_prev, t).x-0.001, _ProjectionParams.y);
}

float sample_upper_depth(float2 t)
{
    return max(cross_depth_sample(t, g_depth, 2.0)*0.995, _ProjectionParams.y);
}


float3 rotateX(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(p.x, c*p.y+s*p.z, -s*p.y+c*p.z);
}

float3 rotateY(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x-s*p.z, p.y, s*p.x+c*p.z);
}

float3 rotateZ(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x+s*p.y, -s*p.x+c*p.y, p.z);
}

float4x4 translation_matrix(float3 t)
{
    return float4x4(
        1.0, 0.0, 0.0, t.x,
        0.0, 1.0, 0.0, t.y,
        0.0, 0.0, 1.0, t.z,
        0.0, 0.0, 0.0, 1.0 );
}

float3x3 axis_rotation_matrix33(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return float3x3(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}
float4x4 axis_rotation_matrix44(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return float4x4(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
        0.0,                                0.0,                                0.0,                                1.0);
}

float3x3 quaternion_to_matrix33(float4 q)
{
    return float3x3(
        1.0 - 2.0*q.y*q.y - 2.0*q.z*q.z, 2.0*q.x*q.y - 2.0*q.z*q.w,       2.0*q.x*q.z + 2.0*q.y*q.w,
        2.0*q.x*q.y + 2.0*q.z*q.w,       1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z, 2.0*q.y*q.z - 2.0*q.x*q.w,
        2.0*q.x*q.z - 2.0*q.y*q.w,       2.0*q.y*q.z + 2.0*q.x*q.w,       1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y );
}

float4x4 quaternion_to_matrix44(float4 q)
{
    return float4x4(
        1.0 - 2.0*q.y*q.y - 2.0*q.z*q.z, 2.0*q.x*q.y - 2.0*q.z*q.w,       2.0*q.x*q.z + 2.0*q.y*q.w,       0.0,
        2.0*q.x*q.y + 2.0*q.z*q.w,       1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z, 2.0*q.y*q.z - 2.0*q.x*q.w,       0.0,
        2.0*q.x*q.z - 2.0*q.y*q.w,       2.0*q.y*q.z + 2.0*q.x*q.w,       1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

#endif // foundation_h
