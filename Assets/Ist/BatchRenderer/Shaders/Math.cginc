#ifndef BRMath_h
#define BRMath_h

#define PI 3.1415926535897932384626433832795

float  modc(float  a, float  b) { return a - b * floor(a/b); }
float2 modc(float2 a, float2 b) { return a - b * floor(a/b); }
float3 modc(float3 a, float3 b) { return a - b * floor(a/b); }
float4 modc(float4 a, float4 b) { return a - b * floor(a/b); }

float3 rotateX(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
}

float3 rotateY(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
}

float3 rotateZ(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
}

// a & b must be normalized
float angle_between(float3 a, float3 b)
{
    return acos(dot(a, b));
}
float angle_between(float3 a, float3 b, float3 center)
{
    return angle_between(
        normalize(a - center),
        normalize(b - center));
}


float4x4 translation_matrix44(float3 t)
{
    return float4x4(
        1.0, 0.0, 0.0, t.x,
        0.0, 1.0, 0.0, t.y,
        0.0, 0.0, 1.0, t.z,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 scale_matrix33(float3 s)
{
    return float3x3(
        s.x, 0.0, 0.0,
        0.0, s.y, 0.0,
        0.0, 0.0, s.x);
}

float4x4 scale_matrix44(float3 s)
{
    return float4x4(
        s.x, 0.0, 0.0, 0.0,
        0.0, s.y, 0.0, 0.0,
        0.0, 0.0, s.x, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float2x2 rotation_matrix22(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float2x2(
        c,-s,
        s, c);
}

float3x3 rotateX_matrix33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
        1.0, 0.0, 0.0,
        0.0,   c,  -s,
        0.0,   s,   c);
}
float4x4 rotateX_matrix44(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float4x4(
        1.0, 0.0, 0.0, 0.0,
        0.0,   c,  -s, 0.0,
        0.0,   s,   c, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 rotateY_matrix33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
          c, 0.0,   s,
        0.0, 1.0, 0.0,
         -s, 0.0,   c);
}
float4x4 rotateY_matrix44(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float4x4(
          c, 0.0,   s, 0.0,
        0.0, 1.0, 0.0, 0.0,
         -s, 0.0,   c, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 rotateZ_matrix33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
          c,  -s, 0.0,
          s,   c, 0.0,
        0.0, 0.0, 1.0);
}
float4x4 rotateZ_matrix44(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float4x4(
          c,  -s, 0.0, 0.0,
          s,   c, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

// dir & up must be normalized
float3x3 look_matrix33(float3 dir, float3 up)
{
    float3 z = dir;
    float3 x = cross(up, z);
    float3 y = cross(z, x);
    return float3x3(
        x.x, y.x, z.x,
        x.y, y.y, z.y,
        x.z, y.z, z.z );
}

// dir & up must be normalized
float4x4 look_matrix44(float3 dir, float3 up)
{
    float3 z = dir;
    float3 x = cross(up, z);
    float3 y = cross(z, x);
    return float4x4(
        x.x, y.x, z.x, 0.0,
        x.y, y.y, z.y, 0.0,
        x.z, y.z, z.z, 0.0,
        0.0, 0.0, 0.0, 1.0 );
}

// axis must be normalized
float3x3 axis_rotation_matrix33(float3 axis, float angle)
{
    float s, c;
    sincos(angle, s, c);
    float ic = 1.0 - c;
    return float3x3(
        ic * axis.x * axis.x + c,           ic * axis.x * axis.y - axis.z * s,  ic * axis.z * axis.x + axis.y * s,
        ic * axis.x * axis.y + axis.z * s,  ic * axis.y * axis.y + c,           ic * axis.y * axis.z - axis.x * s,
        ic * axis.z * axis.x - axis.y * s,  ic * axis.y * axis.z + axis.x * s,  ic * axis.z * axis.z + c          );
}

// axis must be normalized
float4x4 axis_rotation_matrix44(float3 axis, float angle)
{
    float s, c;
    sincos(angle, s, c);
    float ic = 1.0 - c;
    return float4x4(
        ic * axis.x * axis.x + c,           ic * axis.x * axis.y - axis.z * s,  ic * axis.z * axis.x + axis.y * s,  0.0,
        ic * axis.x * axis.y + axis.z * s,  ic * axis.y * axis.y + c,           ic * axis.y * axis.z - axis.x * s,  0.0,
        ic * axis.z * axis.x - axis.y * s,  ic * axis.y * axis.z + axis.x * s,  ic * axis.z * axis.z + c,           0.0,
        0.0,                                0.0,                                0.0,                                1.0);
}

float3x3 quaternion_to_matrix33(float4 q)
{
    return float3x3(
        1.0-2.0*q.y*q.y - 2.0*q.z*q.z,  2.0*q.x*q.y - 2.0*q.z*q.w,          2.0*q.x*q.z + 2.0*q.y*q.w,      
        2.0*q.x*q.y + 2.0*q.z*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z,    2.0*q.y*q.z - 2.0*q.x*q.w,      
        2.0*q.x*q.z - 2.0*q.y*q.w,      2.0*q.y*q.z + 2.0*q.x*q.w,          1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y );
}
float4x4 quaternion_to_matrix44(float4 q)
{
    return float4x4(
        1.0-2.0*q.y*q.y - 2.0*q.z*q.z,  2.0*q.x*q.y - 2.0*q.z*q.w,          2.0*q.x*q.z + 2.0*q.y*q.w,          0.0,
        2.0*q.x*q.y + 2.0*q.z*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z,    2.0*q.y*q.z - 2.0*q.x*q.w,          0.0,
        2.0*q.x*q.z - 2.0*q.y*q.w,      2.0*q.y*q.z + 2.0*q.x*q.w,          1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y,    0.0,
        0.0,                            0.0,                                0.0,                                1.0 );
}

float3 extract_position(float4x4 m)
{
    return float3(m[0][3], m[1][3], m[2][3]);
}

#endif // BRMath_h
