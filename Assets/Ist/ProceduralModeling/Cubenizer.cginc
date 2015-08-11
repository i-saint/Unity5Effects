#include "ProceduralModeling.cginc"

float _GridSize;
float _CubeSize;
float _BumpHeight;
float _AnimationSpeed;


float map(float3 pg)
{
    float3 p = localize(pg);

#if ENABLE_BUMP
    float r = iq_rand(floor((p.BUMP_PLANE) / _GridSize)).x;
    float t = cos(r*PI + _LocalTime*r*_AnimationSpeed) * 0.5 + 0.5;
    p.BUMP_DIR += _BumpHeight * t;
#endif // ENABLE_BUMP

    float3 p1 = modc(p, _GridSize) - _GridSize*0.5;
    float d1 = sdBox(p1, _CubeSize*0.5);
#if ENABLE_PUNCTURE==1
    {
        float2 sub = float2(_CubeSize*0.25, 1.0);
        d1 = max(d1, -sdBox(p1, sub.xxy));
        d1 = max(d1, -sdBox(p1, sub.xyx));
        d1 = max(d1, -sdBox(p1, sub.yxx));
    }
#elif ENABLE_PUNCTURE==2
    {
        float3 p2 = modc(p + _GridSize*0.5, _GridSize) - _GridSize*0.5;
        float2 sub = float2(_CubeSize*0.4, 1.0);
        d1 = max(d1, -sdBox(p2, sub.xxy));
        d1 = max(d1, -sdBox(p2, sub.xyx));
        d1 = max(d1, -sdBox(p2, sub.yxx));
    }
#endif
#if ENABLE_BUMP
    d1 = max(d1, p.BUMP_DIR - _Scale.BUMP_DIR*0.5);
#endif // ENABLE_BUMP

    return max(d1, 0.0);
}

#include "Framework.cginc"
