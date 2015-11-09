#ifndef BezierPatch_h
#define BezierPatch_h

// thanks to @ototoi, @gishicho
// http://jcgt.org/published/0004/01/04/


/*
// HLSL to GLSL
#define float2 vec2
#define float3 vec3
#define float3 vec3
#define lerp mix
#define frac fract
*/


struct BezierPatch
{
    float3 cp[16];
};

// --------------------------------------------------------------------
// prototypes

float3 BPGet(BezierPatch bp, int x, int y);
void   BPGetMinMax(BezierPatch bp, out float3 o_min, out float3 o_max, float epsilon);
float3 BPEvaluate(BezierPatch bp, float2 uv);
float3 BPEvaluateDu(BezierPatch bp, float2 uv);
float3 BPEvaluateDv(BezierPatch bp, float2 uv);
float3 BPEvaluateNormal(BezierPatch bp, float2 uv);
void   BPSplit(BezierPatch bp, out BezierPatch dst[4], float u, float v);
void   BPSplitU(BezierPatch bp, out BezierPatch dst[2], float u);
void   BPSplitV(BezierPatch bp, out BezierPatch dst[2], float v);
void   BPCropU(BezierPatch bp, out BezierPatch dst, float u0, float u1);
void   BPCropV(BezierPatch bp, out BezierPatch dst, float v0, float v1);
bool   BPCrop(BezierPatch bp, out BezierPatch dst, float u0, float u1, float v0, float v1);
float3 BPGetLv(BezierPatch bp);
float3 BPGetLu(BezierPatch bp);

void   BPTranspose(inout BezierPatch bp);
void   BPTransform(inout BezierPatch bp, float3x3 m);
void   BPTransform(inout BezierPatch bp, float4x4 m);




// --------------------------------------------------------------------
// internal functions

void BPSplitU_(inout BezierPatch a, inout BezierPatch b, BezierPatch p, float t, int i)
{
    float S = 1.0f - t;
    float3 p0 = p.cp[i + 0];
    float3 p1 = p.cp[i + 1];
    float3 p2 = p.cp[i + 2];
    float3 p3 = p.cp[i + 3];
    a.cp[i + 0] = p0;
    a.cp[i + 1] = p0*S + p1*t;
    a.cp[i + 2] = p0*S*S + p1 * 2.0f * S*t + p2*t*t;
    a.cp[i + 3] = p0*S*S*S + p1 * 3.0f * S*S*t + p2 * 3.0f * S*t*t + p3*t*t*t;

    b.cp[i + 0] = p0*S*S*S + p1 * 3.0f * S*S*t + p2 * 3.0f * S*t*t + p3*t*t*t;
    b.cp[i + 1] = p3*t*t + p2 * 2.0f * t*S + p1*S*S;
    b.cp[i + 2] = p3*t + p2*S;
    b.cp[i + 3] = p3;
}

void BPSplitV_(inout BezierPatch a, inout BezierPatch b, BezierPatch p, float t, int i)
{
    float S = 1.0f - t;
    float3 p0 = p.cp[i + 0];
    float3 p1 = p.cp[i + 4];
    float3 p2 = p.cp[i + 8];
    float3 p3 = p.cp[i + 12];
    a.cp[i + 0] = p0;
    a.cp[i + 4] = p0*S + p1*t;
    a.cp[i + 8] = p0*S*S + p1 * 2.0f * S*t + p2*t*t;
    a.cp[i + 12] = p0*S*S*S + p1 * 3.0f * S*S*t + p2 * 3.0f * S*t*t + p3*t*t*t;

    b.cp[i + 0] = p0*S*S*S + p1 * 3.0f * S*S*t + p2 * 3.0f * S*t*t + p3*t*t*t;
    b.cp[i + 4] = p3*t*t + p2 * 2.0f * t*S + p1*S*S;
    b.cp[i + 8] = p3*t + p2*S;
    b.cp[i + 12] = p3;
}

void BPCropU_(inout BezierPatch dst, BezierPatch src, float s, float t, int i)
{
    float3 p0 = src.cp[i + 0];
    float3 p1 = src.cp[i + 1];
    float3 p2 = src.cp[i + 2];
    float3 p3 = src.cp[i + 3];
    float T = 1.0f - s;
    float S = 1.0f - t;
    s = 1.0f - T;
    t = 1.0f - S;
    dst.cp[i + 0] = (p0*(T*T)*T + p3*(s*s)*s) + (p1*(s*T)*(3.0f * T) + p2*(s*s)*(3.0f * T));
    dst.cp[i + 1] = (p0*(T*T)*S + p3*(s*s)*t) + (p1*T*(2.0f * (S*s) + T*t) + p2*s*(2.0f * (t*T) + (s*S)));
    dst.cp[i + 2] = (p3*(t*t)*s + p0*(S*S)*T) + (p2*t*(2.0f * (s*S) + t*T) + p1*S*(2.0f * (T*t) + (S*s)));
    dst.cp[i + 3] = (p3*(t*t)*t + p0*(S*S)*S) + (p2*(S*t)*(3.0f * t) + p1*(S*S)*(3.0f * t));
}

void BPCropV_(inout BezierPatch dst, BezierPatch src, float s, float t, int i)
{
    float3 p0 = src.cp[i + 0];
    float3 p1 = src.cp[i + 4];
    float3 p2 = src.cp[i + 8];
    float3 p3 = src.cp[i + 12];
    float T = 1.0f - s;
    float S = 1.0f - t;
    s = 1.0f - T;
    t = 1.0f - S;
    dst.cp[i + 0] = (p0*(T*T)*T + p3*(s*s)*s) + (p1*(s*T)*(3.0f * T) + p2*(s*s)*(3.0f * T));
    dst.cp[i + 4] = (p0*(T*T)*S + p3*(s*s)*t) + (p1*T*(2.0f * (S*s) + T*t) + p2*s*(2.0f * (t*T) + (s*S)));
    dst.cp[i + 8] = (p3*(t*t)*s + p0*(S*S)*T) + (p2*t*(2.0f * (s*S) + t*T) + p1*S*(2.0f * (T*t) + (S*s)));
    dst.cp[i + 12] = (p3*(t*t)*t + p0*(S*S)*S) + (p2*(S*t)*(3.0f * t) + p1*(S*S)*(3.0f * t));
}

float3 BPEvaluate_(float t, float3 cp[4])
{
    float it = 1.0f - t;
    return cp[0] * (it*it*it)
        + cp[1] * (3.0f*(it*it*t))
        + cp[2] * (3.0f*(it*t*t))
        + cp[3] * (t*t*t);
}

float3 BPEvaluateD_(float t, float3 cp[4])
{
    float t2 = t * t;
    return cp[0] * (3.0f * t2 *-1.0f + 2.0f * t * 3.0f - 3.0f)
        + cp[1] * (3.0f * t2 * 3.0f + 2.0f * t *-6.0f + 3.0f)
        + cp[2] * (3.0f * t2 *-3.0f + 2.0f * t * 3.0f)
        + cp[3] * (3.0f * t2 * 1.0f);
}



// --------------------------------------------------------------------
// public functions

float3 BPGet(BezierPatch bp, int x, int y)
{
    return bp.cp[4 * y + x];
}

void BPGetMinMax(BezierPatch bp, out float3 o_min, out float3 o_max, float epsilon)
{
    o_min = o_max = bp.cp[0];
    for (int i = 1; i < 16; ++i)
    {
        o_min = min(o_min, bp.cp[i]);
        o_max = max(o_max, bp.cp[i]);
    }
    o_min -= epsilon;
    o_max += epsilon;
}

float3 BPEvaluate(BezierPatch bp, float2 uv)
{
    float3 b[4];
    for (int i = 0; i < 4; ++i) {
        float3 cp[4] = {
            bp.cp[i * 4 + 0],
            bp.cp[i * 4 + 1],
            bp.cp[i * 4 + 2],
            bp.cp[i * 4 + 3]
        };
        b[i] = BPEvaluate_(uv.x, cp);
    }
    return BPEvaluate_(uv.y, b);
}

float3 BPEvaluateDu(BezierPatch bp, float2 uv)
{
    float3 b[4];
    for (int i = 0; i < 4; ++i) {
        float3 cp[4] = {
            bp.cp[i * 4 + 0],
            bp.cp[i * 4 + 1],
            bp.cp[i * 4 + 2],
            bp.cp[i * 4 + 3]
        };
        b[i] = BPEvaluateD_(uv.x, cp);
    }
    return BPEvaluate_(uv.y, b);
}

float3 BPEvaluateDv(BezierPatch bp, float2 uv)
{
    float3 b[4];
    for (int i = 0; i < 4; ++i) {
        float3 cp[4] = {
            bp.cp[i * 4 + 0],
            bp.cp[i * 4 + 1],
            bp.cp[i * 4 + 2],
            bp.cp[i * 4 + 3]
        };
        b[i] = BPEvaluate_(uv.x, cp);
    }
    return BPEvaluateD_(uv.y, b);
}

float3 BPEvaluateNormal(BezierPatch bp, float2 uv)
{
    float3 du = BPEvaluateDu(bp, uv);
    float3 dv = BPEvaluateDv(bp, uv);
    return normalize(cross(dv, du));
}

void BPSplit(BezierPatch bp, out BezierPatch dst[4], float u, float v)
{
    BezierPatch tmp0, tmp1;
    int i;

    // split U
    for (i = 0; i < 4; ++i) {
        BPSplitU_(tmp0, tmp1, bp, u, i * 4);
    }

    // uv -> vu
    BPTranspose(tmp0); // 00 01
    BPTranspose(tmp1); // 10 11

                      // split V
    for (i = 0; i < 4; ++i) {
        BPSplitU_(dst[0], dst[2], tmp0, v, i * 4);
        BPSplitU_(dst[1], dst[3], tmp1, v, i * 4);
    }

    // vu -> uv
    BPTranspose(dst[0]); //00
    BPTranspose(dst[1]); //10
    BPTranspose(dst[2]); //01
    BPTranspose(dst[3]); //11
}

void BPSplitU(BezierPatch bp, out BezierPatch dst[2], float u)
{
    for (int i = 0; i < 4; ++i) {
        BPSplitU_(dst[0], dst[1], bp, u, i * 4);
    }
}

void BPSplitV(BezierPatch bp, out BezierPatch dst[2], float v)
{
    for (int i = 0; i < 4; ++i) {
        BPSplitV_(dst[0], dst[1], bp, v, i);
    }
}

void BPCropU(BezierPatch bp, out BezierPatch dst, float u0, float u1)
{
    for (int i = 0; i < 4; ++i) {
        BPCropU_(dst, bp, u0, u1, i*4);
    }
}

void BPCropV(BezierPatch bp, out BezierPatch dst, float v0, float v1)
{
    for (int i = 0; i < 4; ++i) {
        BPCropV_(dst, bp, v0, v1, i);
    }
}

bool BPCrop(BezierPatch bp, out BezierPatch dst, float u0, float u1, float v0, float v1)
{
    BezierPatch tmp;
    int i;
    for (i = 0; i < 4; ++i) BPCropU_(tmp, bp, u0, u1, i * 4);
    for (i = 0; i < 4; ++i) BPCropV_(dst, tmp, v0, v1, i);
    return true;
}

float3 BPGetLv(BezierPatch bp)
{
    return BPGet(bp, 0, 4 - 1) - BPGet(bp, 0, 0) + BPGet(bp, 4 - 1, 4 - 1) - BPGet(bp, 4 - 1, 0);
}

float3 BPGetLu(BezierPatch bp)
{
    return BPGet(bp, 4 - 1, 0) - BPGet(bp, 0, 0) + BPGet(bp, 4 - 1, 4 - 1) - BPGet(bp, 0, 4 - 1);
}


void BPSwap_(inout BezierPatch bp, int i0, int i1)
{
    float3 tmp = bp.cp[i0];
    bp.cp[i0] = bp.cp[i1];
    bp.cp[i1] = tmp;
}

void BPTranspose(inout BezierPatch bp)
{
    BPSwap_(bp, 1 * 4 + 0, 0 * 4 + 1);
    BPSwap_(bp, 2 * 4 + 0, 0 * 4 + 2);
    BPSwap_(bp, 3 * 4 + 0, 0 * 4 + 3);
    BPSwap_(bp, 2 * 4 + 1, 1 * 4 + 2);
    BPSwap_(bp, 3 * 4 + 1, 1 * 4 + 3);
    BPSwap_(bp, 3 * 4 + 2, 2 * 4 + 3);
}

void BPTransform(inout BezierPatch bp, float3x3 m)
{
    for (int i = 0; i < 16; ++i) {
        bp.cp[i] = mul(m, bp.cp[i]).xyz;
    }
}

void BPTransform(inout BezierPatch bp, float4x4 m)
{
    for (int i = 0; i < 16; ++i) {
        bp.cp[i] = mul(m, float4(bp.cp[i], 1.0)).xyz;
    }
}

#endif // BezierPatch_h
