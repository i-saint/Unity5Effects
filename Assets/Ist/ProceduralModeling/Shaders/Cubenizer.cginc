#include "ProceduralModeling.cginc"

float _GridSize;
float _CubeSize;
float _BumpHeight;
float _AnimationSpeed;
int _PuncturePattern;
int _AnimationPattern;


void initialize(inout raymarch_data R)
{
}

float map(float3 pg)
{
    float3 p = localize(pg);

    float bump = 0.0;
    if (_BumpHeight != 0.0) {
        float r = iq_rand(floor((p.BUMP_PLANE) / _GridSize + _ObjectID*0.057234)).x;
        if (_AnimationPattern == 0) {
            float t = cos(r*PI + _LocalTime*r*_AnimationSpeed) * 0.5 + 0.5;
            p.BUMP_DIR += _BumpHeight * t;
        }
        else if (_AnimationPattern == 1) {
            float t = r + _LocalTime*r*_AnimationSpeed;
            p.BUMP_DIR -= _BumpHeight * t*3.0;
        }
        bump = p.BUMP_DIR - _Scale.BUMP_DIR*0.5;
    }

    float3 p1 = modc(p, _GridSize) - _GridSize*0.5;
    float d1 = sdBox(p1, _CubeSize*0.5);
    if(_PuncturePattern==1) {
        float2 sub = float2(_CubeSize*0.25, 1.0);
        d1 = max(d1, -sdBox(p1, sub.xxy));
        d1 = max(d1, -sdBox(p1, sub.xyx));
        d1 = max(d1, -sdBox(p1, sub.yxx));
    }
    else if (_PuncturePattern == 2) {
        float3 p2 = modc(p + _GridSize*0.5, _GridSize) - _GridSize*0.5;
        float2 sub = float2(_CubeSize*0.4, 1.0);
        d1 = max(d1, -sdBox(p2, sub.xxy));
        d1 = max(d1, -sdBox(p2, sub.xyx));
        d1 = max(d1, -sdBox(p2, sub.yxx));
    }
    d1 = max(d1, bump);
    return max(d1, 0.0);
}

void posteffect(inout gbuffer_out O, vs_out I, raymarch_data R)
{
}

#include "Framework.cginc"
