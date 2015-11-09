#ifndef IstRandom_h
#define IstRandom_h

float  iq_rand(float  p)
{
    return frac(sin(p)*43758.5453);
}
float2 iq_rand(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*43758.5453);
}
float3 iq_rand(float3 p)
{
    p = float3(dot(p, float3(127.1, 311.7, 311.7)), dot(p, float3(269.5, 183.3, 183.3)), dot(p, float3(269.5, 183.3, 183.3)));
    return frac(sin(p)*43758.5453);
}


/*
thanks to T.Hachisuka:
http://www.ci.i.u-tokyo.ac.jp/~hachisuka/tdf2015.pdf

example:

void Test()
{
    float4 state = _Time.y; // initialize state
    for(int i=0; i<N; ++i) {
        float r = GPURand(state);
        // ...
    }
}
*/
//float GPURand(float4 state)
//{
//    const float4 q = float4(1225.0, 1585.0, 2457.0, 2098.0);
//    const float4 r = float4(1112.0, 367.0, 92.0, 265.0);
//    const float4 a = float4(3423.0, 2646.0, 1707.0, 1999.0);
//    const float4 m = float4(4194287.0, 4194277.0, 4194191.0, 4194167.0);
//    float4 beta = floor(state / q);
//    float4 p = a * (state - beta * q) - beta * r;
//    beta = (sign(-p) + 1.0) * 0.5 * m;
//    state = (p + beta);
//    return frac(dot(state / m, float4(1.0, -1.0, 1.0, -1.0)));
//}

#endif // IstRandom_h
