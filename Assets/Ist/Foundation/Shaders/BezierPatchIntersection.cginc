#ifndef BezierPatchIntersection_h
#define BezierPatchIntersection_h

#define BPI_MAX_STACK_DEPTH 20
#define BPI_MAX_LOOP 1000
#define BPI_EPS 1e-3f

struct Intersection
{
    float t, u, v;
    int clip_level;
};

struct WorkingBuffer
{
    BezierPatch source;
    BezierPatch aligned;
    BezierPatch crop;
    BezierPatch rotate;
    BezierPatch tmp0;
    float4x4 mat;
    float4x4 mat1;
    Ray ray;
};

struct RangeAABB
{
    float tmin, tmax;
};

struct UVT
{
    float u, v, t;
    int clip_level;
};



// prototypes
bool BPITest(inout WorkingBuffer work, inout Intersection info, float tmin, float tmax);

bool BPITestBezierPatch(inout WorkingBuffer work, inout UVT info, float zmin, float zmax, float eps);


bool BPITest(inout WorkingBuffer work, inout Intersection info, float tmin, float tmax)
{
    UVT uvt;
    uvt.t = tmax;

    work.aligned = work.source;
    BPTransform(work.aligned, work.mat);

    if (BPITestBezierPatch(work, uvt, tmin, tmax, BPI_EPS)) {
        float t = uvt.t;
        float u = uvt.u;
        float v = uvt.v;

        info.t = t;
        info.u = u;
        info.v = v;
        info.clip_level = uvt.clip_level;
        return true;
    }
    return false;
}


void BPICrop_(inout WorkingBuffer work, float u0, float u1, float v0, float v1)
{
    for (int i = 0; i < 4; ++i) {
        BPCropU_(work.aligned, work.tmp0, u0, u1, i * 4);
    }
    for (int i = 0; i < 4; ++i) {
        BPCropV_(work.tmp0, work.crop, v0, v1, i);
    }
}

void BPIRotate_(inout WorkingBuffer work, float3 dx)
{
    dx.z = 0;
    dx = normalize(dx);
    work.mat1 = float4x4(
        dx.x, dx.y, dx.z, 0.0,
       -dx.y, dx.x,  0.0, 0.0,
         0.0,  0.0,  1.0, 0.0,
         0.0,  0.0,  0.0, 1.0
    );
    BPTransform(work.rotate, work.mat1);
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
    float inv_det = 1.0f / det;

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
    BezierPatch patch, inout UVT info, float u0, float u1, float v0, float v1, float zmin, float zmax)
{
    // TODO (NO_DIRECT)
    // DIRECT_BILINEAR
    float3 p0, p1, p2, p3;
    float3 ray_org = float3(0.0, 0.0, 0.0);
    float3 ray_dir = float3(0.0, 0.0, 1.0);
    p0 = patch.cp[0];
    p1 = patch.cp[3];
    p2 = patch.cp[12];
    p3 = patch.cp[15];
    bool ret = false;
    float t = zmax, uu = 0.0, vv = 0.0;
    if (BPITriangleIntersect_(t, uu, vv, p0, p2, p1, ray_org, ray_dir)) {
        float ww = 1.0 - (uu + vv);
        float u = ww*0.0 + uu*0.0 + vv*1.0; //00 - 01 - 10
        float v = ww*0.0 + uu*1.0 + vv*0.0; //00 - 01 - 10
        info.u = lerp(u0,u1,u);
        info.v = lerp(v0,v1,v);
        info.t = t;
        ret = true;
    }
    if (BPITriangleIntersect_(t, uu, vv, p1, p2, p3, ray_org, ray_dir)) {
        float ww = 1.0 - (uu + vv);
        float u = ww*1.0 + uu*0.0 + vv*1.0; //10 - 01 - 11
        float v = ww*0.0 + uu*1.0 + vv*1.0; //10 - 01 - 11
        info.u = lerp(u0,u1,u);
        info.v = lerp(v0,v1,v);
        info.t = t;
        ret = true;
    }
    return ret;
}

bool BPITestBezierPatch(inout WorkingBuffer work, inout UVT info, float zmin, float zmax, float eps)
{
    float3 min, max;
    BPGetMinMax(work.aligned, min, max, eps*1e-3f);

    if (0 < min.x || max.x < 0 || 0 < min.y || max.y < 0 || max.z < zmin || zmax < min.z) {
        return false;
    }


    // non-recursive iteration
    bool ret = false;

    float4 range_stack[BPI_MAX_STACK_DEPTH];
    int stack_index = 0;
    range_stack[0] = float4(0.0, 1.0, 0.0, 1.0);

    for (int i = 0; i < BPI_MAX_LOOP && stack_index >= 0; ++i) {

        // pop a patch range and crop
        float u0 = range_stack[stack_index].x;
        float u1 = range_stack[stack_index].y;
        float v0 = range_stack[stack_index].z;
        float v1 = range_stack[stack_index].w;
        --stack_index;

        BPICrop_(work, u0, u1, v0, v1);
        float3 LU = work.crop.cp[3] - work.crop.cp[0];
        float3 LV = work.crop.cp[12] - work.crop.cp[0];
        bool clipU = length(LU) > length(LV);

        float3 min, max;
        // rotate and min/max
        float3 dx = clipU
            ? work.crop.cp[12] - work.crop.cp[0] + work.crop.cp[15] - work.crop.cp[3]
            : work.crop.cp[3] - work.crop.cp[0] + work.crop.cp[15] - work.crop.cp[12];
        work.rotate = work.crop;
        BPIRotate_(work, dx);
        BPGetMinMax(work.rotate, min, max, eps*1e-3f);

        // out
        if (0 < min.x || max.x < 0 || 0 < min.y || max.y < 0 || max.z < zmin || zmax < min.z) {
            continue;
        }

        // if it's small enough, test bilinear.
        if ((max.x - min.x) < eps || (max.y - min.y) < eps) {
            if (BPITestBezierClipL_(work.crop, info, u0, u1, v0, v1, zmin, zmax)) {
                // info is updated.
                zmax = info.t;
                info.clip_level = i;
                ret = true;
            }
            // find another intersection
            continue;
        }

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


#endif // BezierPatchIntersection_h
