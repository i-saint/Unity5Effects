#ifndef IstMath_h
#define IstMath_h

#define PI 3.1415926535897932384626433832795
#define INV_PI 0.3183098861837907

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

// dir must be normalized
float3x3 look_matrix33(float3 dir, float3 up)
{
    float3 z = dir;
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float3x3(
        x.x, y.x, z.x,
        x.y, y.y, z.y,
        x.z, y.z, z.z );
}
// dir must be normalized
float4x4 look_matrix44(float3 dir, float3 up)
{
    float3 z = dir;
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float4x4(
        x.x, y.x, z.x, 0.0,
        x.y, y.y, z.y, 0.0,
        x.z, y.z, z.z, 0.0,
        0.0, 0.0, 0.0, 1.0 );
}

float3x3 look_matrix33(float3 from, float3 to, float3 up)
{
    float3 z = normalize(to - from);
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float3x3(
        x.x, y.x, z.x,
        x.y, y.y, z.y,
        x.z, y.z, z.z);
}
float4x4 look_matrix44(float3 from, float3 to, float3 up)
{
    float3 z = normalize(to - from);
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float4x4(
                 x.x,          y.x,          z.x, 0.0,
                 x.y,          y.y,          z.y, 0.0,
                 x.z,          y.z,          z.z, 0.0,
        -dot(x,from), -dot(y,from), -dot(z,from), 1.0);
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


/*
example:

float4 g_state;
float MyRnd()
{
    return GPURnd(g_state);
}

// ...
// initialize state
g_state = float4(I.uvuv*_Time.y);
for(int i=0; i<N; ++i) {
    float r = MyRnd();
    // ...
}
// ... 
*/
float GPURnd(float4 state)
{
    const float4 q = float4(1225.0, 1585.0, 2457.0, 2098.0);
    const float4 r = float4(1112.0, 367.0, 92.0, 265.0);
    const float4 a = float4(3423.0, 2646.0, 1707.0, 1999.0);
    const float4 m = float4(4194287.0, 4194277.0, 4194191.0, 4194167.0);
    float4 beta = floor(state / q);
    float4 p = a * (state - beta * q) - beta * r;
    beta = (sign(-p) + 1.0) * 0.5 * m;
    state = (p + beta);
    return frac(dot(state / m, float4(1.0, -1.0, 1.0, -1.0)));
}

#endif // IstMath_h
