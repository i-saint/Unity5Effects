#ifndef foundation_h
#define foundation_h

#include "UnityCG.cginc"
#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"
#include "Assets/Ist/Foundation/Shaders/BuiltinVariablesExt.cginc"



sampler2D g_depth_prev;
sampler2D g_depth;
sampler2D g_velocity;

float cross_depth_sample(float2 t, sampler2D s, float o)
{
    float2 p = (_ScreenParams.zw - 1.0)*o;
    float d1 = tex2D(s, t).x;
    float d2 = min(
        min(tex2D(s, t+float2( p.x, 0.0)).x, tex2D(s, t+float2(-p.x, 0.0))).x,
        min(tex2D(s, t+float2( 0.0, p.y)).x, tex2D(s, t+float2( 0.0,-p.y))).x );
    return min(d1, d2);
}

float sample_prev_depth(float2 t)
{
    return max(tex2D(g_depth_prev, t).x-0.001, _ProjectionParams.y);
}

float sample_upper_depth(float2 t)
{
    return max(cross_depth_sample(t, g_depth, 2.0)*0.995, _ProjectionParams.y);
}


#endif // foundation_h
