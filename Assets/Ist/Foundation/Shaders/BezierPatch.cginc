#ifndef BezierPatch_h
#define BezierPatch_h

// thanks to @ototoi, @gishicho
// http://jcgt.org/published/0004/01/04/



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
void   BPSplit(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, out BezierPatch dst2, out BezierPatch dst3, float uv);
void   BPSplitU(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, float t);
void   BPSplitV(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, float t);
void   BPCrop(BezierPatch bp, out BezierPatch dst, float2 uv0, float2 uv1);
void   BPCropU(BezierPatch bp, out BezierPatch dst, float u0, float u1);
void   BPCropV(BezierPatch bp, out BezierPatch dst, float v0, float v1);
float3 BPGetLv(BezierPatch bp);
float3 BPGetLu(BezierPatch bp);
float3 BPGetRoughNormal(BezierPatch bp);

void   BPTranspose(inout BezierPatch bp);
void   BPTransform(inout BezierPatch bp, float3x3 m);
void   BPTransform(inout BezierPatch bp, float4x4 m);




// --------------------------------------------------------------------
// internal functions

float3 BPEvaluate_(float t, float3 cp[4])
{
    float it = 1.0 - t;
    return cp[0] * (it*it*it)
        + cp[1] * (3.0*(it*it*t))
        + cp[2] * (3.0*(it*t*t))
        + cp[3] * (t*t*t);
}

float3 BPEvaluateD_(float t, float3 cp[4])
{
    float t2 = t * t;
    return cp[0] * (3.0 * t2 *-1.0 + 2.0 * t * 3.0 - 3.0)
        + cp[1] * (3.0 * t2 * 3.0 + 2.0 * t *-6.0 + 3.0)
        + cp[2] * (3.0 * t2 *-3.0 + 2.0 * t * 3.0)
        + cp[3] * (3.0 * t2 * 1.0);
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

void BPSplit(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, out BezierPatch dst2, out BezierPatch dst3, float2 uv)
{
    BezierPatch tmp0, tmp1;

    // split U
    BPSplitU(bp, tmp0, tmp1, uv.x);

    // uv -> vu
    BPTranspose(tmp0); // 00 01
    BPTranspose(tmp1); // 10 11

    // split V
    BPSplitU(tmp0, dst0, dst2, uv.y);
    BPSplitU(tmp1, dst1, dst3, uv.y);

    // vu -> uv
    BPTranspose(dst0); //00
    BPTranspose(dst1); //10
    BPTranspose(dst2); //01
    BPTranspose(dst3); //11
}

void BPSplitU(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, float t)
{
    for (int i = 0; i < 16; i += 4) {
        float S = 1.0 - t;
        float3 p0 = bp.cp[i + 0];
        float3 p1 = bp.cp[i + 1];
        float3 p2 = bp.cp[i + 2];
        float3 p3 = bp.cp[i + 3];
        dst0.cp[i + 0] = p0;
        dst0.cp[i + 1] = p0*S + p1*t;
        dst0.cp[i + 2] = p0*S*S + p1 * 2.0 * S*t + p2*t*t;
        dst0.cp[i + 3] = p0*S*S*S + p1 * 3.0 * S*S*t + p2 * 3.0 * S*t*t + p3*t*t*t;
        dst1.cp[i + 0] = p0*S*S*S + p1 * 3.0 * S*S*t + p2 * 3.0 * S*t*t + p3*t*t*t;
        dst1.cp[i + 1] = p3*t*t + p2 * 2.0 * t*S + p1*S*S;
        dst1.cp[i + 2] = p3*t + p2*S;
        dst1.cp[i + 3] = p3;
    }
}

void BPSplitV(BezierPatch bp, out BezierPatch dst0, out BezierPatch dst1, float t)
{
    for (int i = 0; i < 4; ++i) {
        float S = 1.0 - t;
        float3 p0 = bp.cp[i + 0];
        float3 p1 = bp.cp[i + 4];
        float3 p2 = bp.cp[i + 8];
        float3 p3 = bp.cp[i +12];
        dst0.cp[i + 0] = p0;
        dst0.cp[i + 4] = p0*S + p1*t;
        dst0.cp[i + 8] = p0*S*S + p1 * 2.0 * S*t + p2*t*t;
        dst0.cp[i +12] = p0*S*S*S + p1 * 3.0 * S*S*t + p2 * 3.0 * S*t*t + p3*t*t*t;
        dst1.cp[i + 0] = p0*S*S*S + p1 * 3.0 * S*S*t + p2 * 3.0 * S*t*t + p3*t*t*t;
        dst1.cp[i + 4] = p3*t*t + p2 * 2.0 * t*S + p1*S*S;
        dst1.cp[i + 8] = p3*t + p2*S;
        dst1.cp[i +12] = p3;
    }
}

void BPCrop(BezierPatch bp, out BezierPatch dst, float2 uv0, float2 uv1)
{
    BezierPatch tmp;
    BPCropU(bp, tmp, uv0.x, uv1.x);
    BPCropV(tmp, dst, uv0.y, uv1.y);
}

void BPCropU(BezierPatch bp, out BezierPatch dst, float s, float t)
{
    for (int i = 0; i < 16; i += 4) {
        float3 p0 = bp.cp[i + 0];
        float3 p1 = bp.cp[i + 1];
        float3 p2 = bp.cp[i + 2];
        float3 p3 = bp.cp[i + 3];
        float T = 1.0 - s;
        float S = 1.0 - t;
        s = 1.0 - T;
        t = 1.0 - S;
        dst.cp[i + 0] = (p0*(T*T)*T + p3*(s*s)*s) + (p1*(s*T)*(3.0 * T) + p2*(s*s)*(3.0 * T));
        dst.cp[i + 1] = (p0*(T*T)*S + p3*(s*s)*t) + (p1*T*(2.0 * (S*s) + T*t) + p2*s*(2.0 * (t*T) + (s*S)));
        dst.cp[i + 2] = (p3*(t*t)*s + p0*(S*S)*T) + (p2*t*(2.0 * (s*S) + t*T) + p1*S*(2.0 * (T*t) + (S*s)));
        dst.cp[i + 3] = (p3*(t*t)*t + p0*(S*S)*S) + (p2*(S*t)*(3.0 * t) + p1*(S*S)*(3.0 * t));
    }
}

void BPCropV(BezierPatch bp, out BezierPatch dst, float s, float t)
{
    for (int i = 0; i < 4; ++i) {
        float3 p0 = bp.cp[i + 0];
        float3 p1 = bp.cp[i + 4];
        float3 p2 = bp.cp[i + 8];
        float3 p3 = bp.cp[i +12];
        float T = 1.0 - s;
        float S = 1.0 - t;
        s = 1.0 - T;
        t = 1.0 - S;
        dst.cp[i + 0] = (p0*(T*T)*T + p3*(s*s)*s) + (p1*(s*T)*(3.0 * T) + p2*(s*s)*(3.0 * T));
        dst.cp[i + 4] = (p0*(T*T)*S + p3*(s*s)*t) + (p1*T*(2.0 * (S*s) + T*t) + p2*s*(2.0 * (t*T) + (s*S)));
        dst.cp[i + 8] = (p3*(t*t)*s + p0*(S*S)*T) + (p2*t*(2.0 * (s*S) + t*T) + p1*S*(2.0 * (T*t) + (S*s)));
        dst.cp[i +12] = (p3*(t*t)*t + p0*(S*S)*S) + (p2*(S*t)*(3.0 * t) + p1*(S*S)*(3.0 * t));
    }
}

float3 BPGetLv(BezierPatch bp)
{
    return BPGet(bp, 0, 4 - 1) - BPGet(bp, 0, 0) + BPGet(bp, 4 - 1, 4 - 1) - BPGet(bp, 4 - 1, 0);
}

float3 BPGetLu(BezierPatch bp)
{
    return BPGet(bp, 4 - 1, 0) - BPGet(bp, 0, 0) + BPGet(bp, 4 - 1, 4 - 1) - BPGet(bp, 0, 4 - 1);
}

float3 BPGetRoughNormal(BezierPatch bp)
{
    float3 LU = bp.cp[3] - bp.cp[0];
    float3 LV = bp.cp[12] - bp.cp[0];
    return normalize(cross(LV, LU));
}

void BPSwap_(inout BezierPatch bp, int a, int b)
{
    float3 tmp = bp.cp[a];
    bp.cp[a] = bp.cp[b];
    bp.cp[b] = tmp;
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
