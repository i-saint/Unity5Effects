#include "ProceduralModeling.cginc"

float _GridSize;
float _CubeSize;
float _BumpHeight;


float map(float3 pg)
{
    float3 pl = localize(pg);
    float3 p = pl;

#if ENABLE_BUMP
    float r = iq_rand(floor((p.BUMP_PLANE) / _GridSize)).x;
    p.BUMP_DIR -= _GridSize*_BumpHeight*r + _GridSize*(1.0- _BumpHeight);
#endif // ENABLE_BUMP

    float3 p1 = modc(p, _GridSize) - _GridSize*0.5;
    float d1 = sdBox(p1, _CubeSize*0.5);
#if ENABLE_PUNCTURE
    d1 = max(d1, -sdBox(p1, float3(_CubeSize.xx*0.25, 1.0)));
    d1 = max(d1, -sdBox(p1, float3(1.0, _CubeSize.xx*0.25)));
    d1 = max(d1, -sdBox(p1, float3(_CubeSize.x*0.25, 1.0, _CubeSize.x*0.25)));
#endif
#if ENABLE_BUMP
    d1 = max(d1, p.BUMP_DIR - _Scale.BUMP_DIR*0.5 + _GridSize*0.9);
#endif // ENABLE_BUMP

    return max(d1, 0.0);
}

#include "Framework.cginc"
