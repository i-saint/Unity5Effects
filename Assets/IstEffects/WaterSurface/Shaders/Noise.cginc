

float hash(float2 p)
{
    float h = dot(p,float2(127.1, 311.7));
    return frac(sin(h)*43758.5453123);
}
float hash(float3 p)
{
    float h = dot(p,float3(127.1, 311.7, 496.3));
    return frac(sin(h)*43758.5453123);
}

float noise( float2 p )
{
    float2 i = floor( p );
    float2 f = frac( p );
    float2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*lerp( lerp( hash( i + float2(0.0,0.0) ), 
                     hash( i + float2(1.0,0.0) ), u.x),
                lerp( hash( i + float2(0.0,1.0) ), 
                     hash( i + float2(1.0,1.0) ), u.x), u.y);
}

float noise( float3 p )
{
    float3 i = floor( p );
    float3 f = frac( p );
    float3 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*lerp( lerp( hash( i + float2(0.0,0.0) ), 
                     hash( i + float2(1.0,0.0) ), u.x),
                lerp( hash( i + float2(0.0,1.0) ), 
                     hash( i + float2(1.0,1.0) ), u.x), u.y);
}

float sea_octave(float2 uv, float choppy)
{
    uv += noise(uv);
    float2 wv = 1.0-abs(sin(uv));
    float2 swv = abs(cos(uv));
    wv = lerp(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

float sea_octave(float3 uv, float choppy)
{
    uv += noise(uv);
    float3 wv = 1.0-abs(sin(uv));
    float3 swv = abs(cos(uv));
    wv = lerp(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y * wv.z,0.65),choppy);
}
