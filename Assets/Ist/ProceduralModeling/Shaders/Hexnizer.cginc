#include "ProceduralModeling.cginc"

float _GridSize;
float _HexRadius;
float _BumpHeight;
float _EdgeWidth;
float _EdgeHeight;
int _EdgeChopping;
float _AnimationSpeed;
float _Fade;


float2 grid;
float2 grid_rcp;
float2 grid_half;
float radius;

void initialize(inout raymarch_data R)
{
    grid = float2(0.692, 0.4) * _GridSize;
    grid_rcp = 1.0 / grid;
    grid_half = grid*0.5;
    radius = 0.22 * _HexRadius;
}

float map(float3 pg)
{
    float3 p = localize(pg);

    float2 p1 = modc(p.HEX_PLANE, grid) - grid_half;
    float2 p2 = modc(p.HEX_PLANE + grid_half, grid) - grid_half;
    float d1 = sdHex(p1, radius);
    float d2 = sdHex(p2, radius);

    // todo
    //float sel = step(d2, d1);

    float2 pi1 = float2(floor(p.HEX_PLANE * grid_rcp));
    float2 pi2 = float2(floor((p.HEX_PLANE + grid_half) * grid_rcp));
    float pr1 = frac(dot(pi1, float2(0.9, 50.4))); // fast pseudo-random
    float pr2 = frac(dot(pi2, float2(1.2, 60.3))); // 

    float dz1 = max(abs(d1), 0.1); // fix me!
    float dz2 = max(abs(d2), 0.1); // 

    if (_Fade > 0.0) {
        float pf1 = saturate((pr1 - _Fade) * 20.0f);
        float pf2 = saturate((pr2 - _Fade) * 20.0f);
        d1 = lerp(dz1, d1, pf1);
        d2 = lerp(dz2, d2, pf2);
    }

    if(_EdgeChopping == 1) {
        float2 s = _Scale.HEX_PLANE;
        float2 f1 = (abs(pi1) + step(0.0, pi1)) * grid;
        float2 f2 = abs(pi2) * grid + grid_half;
        if (f1.x > s.x*0.5 || f1.y > s.y*0.5) { d1 = dz1; }
        if (f2.x > s.x*0.5 || f2.y > s.y*0.5) { d2 = dz2; }
    }
    else if (_EdgeChopping == 2) {
        float2 s = _Scale.HEX_PLANE;
        float2 f1 = (abs(pi1) + step(0.0, pi1)) * grid;
        float2 f2 = abs(pi2) * grid + grid_half;
        if (length(f1) > s.x*0.5) { d1 = dz1; }
        if (length(f2) > s.x*0.5) { d2 = dz2; }
    }

    float e1 = max(min(d1, 0.0) + _EdgeWidth, 0.0)*_EdgeHeight;
    float e2 = max(min(d2, 0.0) + _EdgeWidth, 0.0)*_EdgeHeight;
    if (_BumpHeight > 0.0) {
        float t1 = cos(pr1*PI + _LocalTime*pr1*_AnimationSpeed) * 0.5 + 0.5;
        float t2 = cos(pr2*PI + _LocalTime*pr2*_AnimationSpeed) * 0.5 + 0.5;
        e1 += _BumpHeight * t1;
        e2 += _BumpHeight * t2;
    }

    d1 = max(d1, p.HEX_DIR - _Scale.HEX_DIR*0.5 + e1);
    d2 = max(d2, p.HEX_DIR - _Scale.HEX_DIR*0.5 + e2);
    d1 = min(d1, d2);
    return max(d1, 0.0);
}

void posteffect(inout gbuffer_out O, vs_out I, raymarch_data R)
{
}

#include "Framework.cginc"
