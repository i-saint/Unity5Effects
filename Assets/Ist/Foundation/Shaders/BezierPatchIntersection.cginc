#ifndef BezierPatchIntersection_h
#define BezierPatchIntersection_h


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
    int clipLevel;
};

#define EPS  (1e-3f)


#endif // BezierPatchIntersection_h
