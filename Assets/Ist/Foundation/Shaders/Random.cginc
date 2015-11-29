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


// iq noise

float hash(float2 p)
{
    float h = dot(p, float2(127.1, 311.7));
    return frac(sin(h)*43758.5453123);
}
float hash(float3 p)
{
    float h = dot(p, float3(127.1, 311.7, 496.3));
    return frac(sin(h)*43758.5453123);
}

float iqnoise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f*f*(3.0 - 2.0*f);
    return -1.0 + 2.0*lerp(lerp(hash(i + float2(0.0, 0.0)),
        hash(i + float2(1.0, 0.0)), u.x),
        lerp(hash(i + float2(0.0, 1.0)),
        hash(i + float2(1.0, 1.0)), u.x), u.y);
}

float iqnoise(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    float3 u = f*f*(3.0 - 2.0*f);
    return -1.0 + 2.0*lerp(lerp(hash(i + float2(0.0, 0.0)),
        hash(i + float2(1.0, 0.0)), u.x),
        lerp(hash(i + float2(0.0, 1.0)),
        hash(i + float2(1.0, 1.0)), u.x), u.y);
}


// trinoise

float tri(float x)
{
    return abs(frac(x) - .5);
}

float3 tri3(float3 p)
{
    return float3(
        tri(p.z + tri(p.y * 1.)),
        tri(p.z + tri(p.x * 1.)),
        tri(p.y + tri(p.x * 1.)) );
}

float trinoise(float3 p, float spd, float time)
{
    float z = 1.4;
    float rz = 0.;
    float3  bp = p;
    for (float i = 0.; i <= 3.; i++) {
        float3 dg = tri3(bp * 2.);
        p += (dg + time * .1 * spd);
        bp *= 1.8;
        z *= 1.5;
        p *= 1.2;
        float t = tri(p.z + tri(p.x + tri(p.y)));
        rz += t / z;
        bp += 0.14;
    }
    return rz;
}

float trinoise(float3 p)
{
    return trinoise(p, 0.0, 0.0);
}



// curl variants

#define DefCurlNoise2D(Name, NoiseFunc)\
    float3 Name(float2 p, float epsilon)\
    {\
        float nx1 = NoiseFunc(float3(p.x + epsilon, p.y, p.z));\
        float nx2 = NoiseFunc(float3(p.x - epsilon, p.y, p.z));\
        float ny1 = NoiseFunc(float3(p.x, p.y + epsilon, p.z));\
        float ny2 = NoiseFunc(float3(p.x, p.y - epsilon, p.z));\
        float re = 1.0 / (2.0 * epsilon);\
        return float3(\
            (ny1 - ny2),\
           -(nx1 - nx2)) re;\
    }

#define DefCurlNoise3D(Name, NoiseFunc)\
    float3 Name(float3 p, float epsilon)\
    {\
        float nx1 = NoiseFunc(float3(p.x + epsilon, p.y, p.z));\
        float nx2 = NoiseFunc(float3(p.x - epsilon, p.y, p.z));\
        float ny1 = NoiseFunc(float3(p.x, p.y + epsilon, p.z));\
        float ny2 = NoiseFunc(float3(p.x, p.y - epsilon, p.z));\
        float nz1 = NoiseFunc(float3(p.x, p.y, p.z + epsilon));\
        float nz2 = NoiseFunc(float3(p.x, p.y, p.z - epsilon));\
        float re = 1.0 / (2.0 * epsilon);\
        return float3(\
            (ny1 - ny2) - (nz1 - nz2),\
            (nz1 - nz2) - (nx1 - nx2),\
            (nx1 - nx2) - (ny1 - ny2)) * re;\
    }

DefCurlNoise3D(curl_iqnoise, iqnoise)
DefCurlNoise3D(curl_trinoise, trinoise)

#endif // IstRandom_h
