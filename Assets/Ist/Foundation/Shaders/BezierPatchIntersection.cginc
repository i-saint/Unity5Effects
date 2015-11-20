#ifndef BezierPatchIntersection_h
#define BezierPatchIntersection_h

// thanks to @ototoi, @gishicho
// http://jcgt.org/published/0004/01/04/


// prototypes

struct BezierPatchHit
{
    float t, u, v;
    int clip_level;
};

bool BPIRaycast(BezierPatch bp, Ray ray, float zmin, float zmax, float eps, out BezierPatchHit hit);




// implements

#ifndef BPI_MAX_STACK_DEPTH
    #define BPI_MAX_STACK_DEPTH 20
#endif
#ifndef BPI_MAX_LOOP
    #define BPI_MAX_LOOP 1000
#endif

struct BPIWorkingBuffer
{
    BezierPatch source; // input
    BezierPatch crop;
    BezierPatch rotate;
    float4 uv_range; // input
};


float3x3 BPIRotate2D_(float3 dx)
{
    float2 x = normalize(dx.xy);
    float2 y = float2(-x[1], x[0]);
    return float3x3(
        x[0], y[0], 0.0,
        x[1], y[1], 0.0,
         0.0,  0.0, 1.0
    );
}

bool BPITriangleIntersect_(
    inout float tout, out float uout, out float vout,
    float3 p0, float3 p1, float3 p2,
    float3 ray_org, float3 ray_dir)
{
    float3 e1, e2;
    float3 p, s, q;

    e1 = p1 - p0;
    e2 = p2 - p0;
    p = cross(ray_dir, e2);

    float det = dot(e1, p);
    float inv_det = 1.0 / det;

    s = ray_org - p0;
    q = cross(s, e1);

    float u = dot(s, p) * inv_det;
    float v = dot(q, ray_dir) * inv_det;
    float t = dot(e2, q) * inv_det;

    if (u < 0.0 || u > 1.0) return false;
    if (v < 0.0 || u + v > 1.0) return false;
    if (t < 0.0 || t > tout) return false;

    tout = t;
    uout = u;
    vout = v;
    return true;
}

bool BPITestBezierClipL_(
    BezierPatch bp, out float3 uvt, float2 uv0, float2 uv1, float zmin, float zmax)
{
    // TODO (NO_DIRECT)
    // DIRECT_BILINEAR
    float3 p0, p1, p2, p3;
    float3 ray_org = float3(0.0, 0.0, 0.0);
    float3 ray_dir = float3(0.0, 0.0, 1.0);
    p0 = bp.cp[0];
    p1 = bp.cp[3];
    p2 = bp.cp[12];
    p3 = bp.cp[15];
    bool ret = false;
    float t = zmax, uu = 0.0, vv = 0.0;
    if (BPITriangleIntersect_(t, uu, vv, p0, p2, p1, ray_org, ray_dir)) {
        float ww = 1.0 - (uu + vv);
        float u = ww*0.0 + uu*0.0 + vv*1.0; //00 - 01 - 10
        float v = ww*0.0 + uu*1.0 + vv*0.0; //00 - 01 - 10
        uvt.x = lerp(uv0.x, uv1.x, u);
        uvt.y = lerp(uv0.y, uv1.y, v);
        uvt.z = t;
        ret = true;
    }
    if (BPITriangleIntersect_(t, uu, vv, p1, p2, p3, ray_org, ray_dir)) {
        float ww = 1.0 - (uu + vv);
        float u = ww*1.0 + uu*0.0 + vv*1.0; //10 - 01 - 11
        float v = ww*0.0 + uu*1.0 + vv*1.0; //10 - 01 - 11
        uvt.x = lerp(uv0.x, uv1.x, u);
        uvt.y = lerp(uv0.y, uv1.y, v);
        uvt.z = t;
        ret = true;
    }
    return ret;
}

bool BPITestBounds_(inout BPIWorkingBuffer work, inout BezierPatchHit info, float zmin, float zmax, float eps)
{
    float3 bmin, bmax;
    BPGetMinMax(work.source, bmin, bmax, eps*1e-3);

    if (0.0 < bmin.x || bmax.x < 0.0 || 0.0 < bmin.y || bmax.y < 0.0 || bmax.z < zmin || zmax < bmin.z) {
        return false;
    }
    return true;
}

bool BPITestBezierPatch_(inout BPIWorkingBuffer work, inout BezierPatchHit info, float zmin, float zmax, float eps)
{
    info = (BezierPatchHit)0;

    // non-recursive iteration
    float4 range_stack[BPI_MAX_STACK_DEPTH];
    int stack_index = 0;
    range_stack[0] = work.uv_range;

    bool ret = false;
    for (int i = 0; i < BPI_MAX_LOOP && stack_index >= 0; ++i) {

        // pop a patch range and crop
        float u0 = range_stack[stack_index].x;
        float u1 = range_stack[stack_index].y;
        float v0 = range_stack[stack_index].z;
        float v1 = range_stack[stack_index].w;
        --stack_index;

        BPCrop(work.source, work.crop, float2(u0, v0), float2(u1, v1));
        float3 LU = work.crop.cp[3] - work.crop.cp[0];
        float3 LV = work.crop.cp[12] - work.crop.cp[0];
        bool clipU = length(LU) > length(LV);

        float3 bmin, bmax;
        // rotate and bmin/bmax
        float3 dx = clipU
            ? work.crop.cp[12] - work.crop.cp[0] + work.crop.cp[15] - work.crop.cp[3]
            : work.crop.cp[3] - work.crop.cp[0] + work.crop.cp[15] - work.crop.cp[12];
        work.rotate = work.crop;
        BPTransform(work.rotate, BPIRotate2D_(dx));
        BPGetMinMax(work.rotate, bmin, bmax, eps*1e-3);

        // out
        if (0.0 < bmin.x || bmax.x < 0.0 || 0.0 < bmin.y || bmax.y < 0.0 || bmax.z < zmin || zmax < bmin.z) {
            continue;
        }

        // if it's small enough, test bilinear.
        if ((bmax.x - bmin.x) < eps || (bmax.y - bmin.y) < eps) {
            float3 uvt;
            if (BPITestBezierClipL_(work.crop, uvt, float2(u0, v0), float2(u1, v1), zmin, zmax)) {
                info.u = uvt.x;
                info.v = uvt.y;
                info.t = uvt.z;
                zmax = info.t;
                ret = true;
            }
            // find another intersection
            continue;
        }
        info.clip_level = i;

        // push children ranges
        if (clipU) {
            float um = (u0 + u1)*0.5;
            range_stack[++stack_index] = float4(u0, um, v0, v1);
            range_stack[++stack_index] = float4(um, u1, v0, v1);
        }
        else {
            float vm = (v0 + v1)*0.5;
            range_stack[++stack_index] = float4(u0, u1, v0, vm);
            range_stack[++stack_index] = float4(u0, u1, vm, v1);
        }

        if (stack_index >= BPI_MAX_STACK_DEPTH - 1) break;
    }
    return ret;
}


bool BPIRaycast(BezierPatch bp, Ray ray, float zmin, float zmax, float eps, out BezierPatchHit hit)
{
    BPIWorkingBuffer work = (BPIWorkingBuffer)0;

    work.source = bp;
    work.uv_range = float4(0.0, 1.0, 0.0, 1.0);
    BPTransform(work.source, ZAlign(ray.origin, ray.direction));

    //// all pixels pass this test when draw aabb as mesh
    //// (but viable if run on GLSLSandbox etc.)
    //if (!BPITestBounds_(work, hit, zmin, zmax, BPI_EPS)) {
    //    return false;
    //}

    hit.t = zmax;
    if (BPITestBezierPatch_(work, hit, zmin, zmax, eps)) {
        return true;
    }
    return false;
}

#endif // BezierPatchIntersection_h
