#ifndef IstMath_h
#define IstMath_h

#define PI 3.1415926535897932384626433832795
#define INV_PI 0.3183098861837907

// GLSL compatible mod()
float  modc(float  a, float  b) { return a - b * floor(a/b); }
float2 modc(float2 a, float2 b) { return a - b * floor(a/b); }
float3 modc(float3 a, float3 b) { return a - b * floor(a/b); }
float4 modc(float4 a, float4 b) { return a - b * floor(a/b); }


// rotate vector
float3 RotateX(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
}
float3 RotateY(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
}
float3 RotateZ(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
}


// a & b must be normalized
float AngleBetween(float3 a, float3 b)
{
    return acos(dot(a, b));
}
float AngleBetween(float3 pos1, float3 pos2, float3 center)
{
    return AngleBetween(
        normalize(pos1 - center),
        normalize(pos2 - center));
}


// ----------------------------------
// matrix functions


float4x4 Translate44(float3 t)
{
    return float4x4(
        1.0, 0.0, 0.0, t.x,
        0.0, 1.0, 0.0, t.y,
        0.0, 0.0, 1.0, t.z,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 Scale33(float3 s)
{
    return float3x3(
        s.x, 0.0, 0.0,
        0.0, s.y, 0.0,
        0.0, 0.0, s.x);
}

float4x4 Scale44(float3 s)
{
    return float4x4(
        s.x, 0.0, 0.0, 0.0,
        0.0, s.y, 0.0, 0.0,
        0.0, 0.0, s.x, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float2x2 Rotate22(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float2x2(
        c,-s,
        s, c);
}

float3x3 RotateX33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
        1.0, 0.0, 0.0,
        0.0,   c,  -s,
        0.0,   s,   c);
}
float4x4 RotateX44(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float4x4(
        1.0, 0.0, 0.0, 0.0,
        0.0,   c,  -s, 0.0,
        0.0,   s,   c, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 RotateY33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
          c, 0.0,   s,
        0.0, 1.0, 0.0,
         -s, 0.0,   c);
}
float4x4 RotateY44(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float4x4(
          c, 0.0,   s, 0.0,
        0.0, 1.0, 0.0, 0.0,
         -s, 0.0,   c, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

float3x3 RotateZ33(float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3x3(
          c,  -s, 0.0,
          s,   c, 0.0,
        0.0, 0.0, 1.0);
}
float4x4 RotateZ44(float angle)
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
float3x3 Look33(float3 dir, float3 up)
{
    float3 z = dir;
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float3x3(
        x.x, y.x, z.x,
        x.y, y.y, z.y,
        x.z, y.z, z.z );
}
float4x4 Look44(float3 dir, float3 up)
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

float3x3 Look33(float3 from, float3 to, float3 up)
{
    float3 z = normalize(to - from);
    float3 x = normalize(cross(up, z));
    float3 y = cross(z, x);
    return float3x3(
        x.x, y.x, z.x,
        x.y, y.y, z.y,
        x.z, y.z, z.z);
}
float4x4 Look44(float3 from, float3 to, float3 up)
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
float3x3 RotateAxis33(float3 axis, float angle)
{
    float s, c;
    sincos(angle, s, c);
    float ic = 1.0 - c;
    return float3x3(
        ic * axis.x * axis.x + c,           ic * axis.x * axis.y - axis.z * s,  ic * axis.z * axis.x + axis.y * s,
        ic * axis.x * axis.y + axis.z * s,  ic * axis.y * axis.y + c,           ic * axis.y * axis.z - axis.x * s,
        ic * axis.z * axis.x - axis.y * s,  ic * axis.y * axis.z + axis.x * s,  ic * axis.z * axis.z + c          );
}
float4x4 RotateAxis44(float3 axis, float angle)
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

// align to ray
// pos: ray origin, dir: ray direction
float4x4 ZAlign(float3 pos, float3 dir, float3 up)
{
    float3 z = dir;
    float3 y = normalize(cross(dir, up));
    float3 x = cross(y, dir);

    float4x4 rot = float4x4(
        x.x, x.y, x.z, 0.0,
        y.x, y.y, y.z, 0.0,
        z.x, z.y, z.z, 0.0,
        0.0, 0.0, 0.0, 1.0
        );
    float4x4 trs = float4x4(
        1.0, 0.0, 0.0, -pos.x,
        0.0, 1.0, 0.0, -pos.y,
        0.0, 0.0, 1.0, -pos.z,
        0.0, 0.0, 0.0, 1.0
        );
    return mul(rot, trs);
}
float4x4 ZAlign(float3 pos, float3 dir)
{
    float3 z = dir;

    int plane = 0;
    if (abs(z[1]) < abs(z[plane])) plane = 1;
    if (abs(z[2]) < abs(z[plane])) plane = 2;

    float3 up = 0.0;
    if (plane == 0) up.x = 1.0;
    if (plane == 1) up.y = 1.0;
    if (plane == 2) up.z = 1.0;

    return ZAlign(pos, dir, up);
}


float3x3 QuaternionToMatrix33(float4 q)
{
    return float3x3(
        1.0-2.0*q.y*q.y - 2.0*q.z*q.z,  2.0*q.x*q.y - 2.0*q.z*q.w,          2.0*q.x*q.z + 2.0*q.y*q.w,      
        2.0*q.x*q.y + 2.0*q.z*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z,    2.0*q.y*q.z - 2.0*q.x*q.w,      
        2.0*q.x*q.z - 2.0*q.y*q.w,      2.0*q.y*q.z + 2.0*q.x*q.w,          1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y );
}
float4x4 QuaternionToMatrix44(float4 q)
{
    return float4x4(
        1.0-2.0*q.y*q.y - 2.0*q.z*q.z,  2.0*q.x*q.y - 2.0*q.z*q.w,          2.0*q.x*q.z + 2.0*q.y*q.w,          0.0,
        2.0*q.x*q.y + 2.0*q.z*q.w,      1.0 - 2.0*q.x*q.x - 2.0*q.z*q.z,    2.0*q.y*q.z - 2.0*q.x*q.w,          0.0,
        2.0*q.x*q.z - 2.0*q.y*q.w,      2.0*q.y*q.z + 2.0*q.x*q.w,          1.0 - 2.0*q.x*q.x - 2.0*q.y*q.y,    0.0,
        0.0,                            0.0,                                0.0,                                1.0 );
}

float3 ExtractPosition(float4x4 m)
{
    return float3(m[0][3], m[1][3], m[2][3]);
}

#endif // IstMath_h
