float4 _Position;
float4 _Rotation;
float4 _Scale;
float4 _OffsetPosition;


float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}
float sdSphere(float3 p, float radius)
{
    return length(p) - radius;
}

float2 iq_rand(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*43758.5453);
}



float3 localize(float3 p)
{
    return mul(_World2Object, float4(p, 1)).xyz * _Scale.xyz + _OffsetPosition.xyz;
}
