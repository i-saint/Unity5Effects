#ifdef SHADER_API_PSSL
#	define COLOR  SV_Target
#	define COLOR0 SV_Target0
#	define COLOR1 SV_Target1
#	define COLOR2 SV_Target2
#	define COLOR3 SV_Target3
#	define DEPTH SV_Depth
#endif

float  modc(float  a, float  b) { return a - b * floor(a/b); }
float2 modc(float2 a, float2 b) { return a - b * floor(a/b); }
float3 modc(float3 a, float3 b) { return a - b * floor(a/b); }
float4 modc(float4 a, float4 b) { return a - b * floor(a/b); }

float2 screen_to_texcoord(float2 p)
{
    return p*0.5+0.5;
}
float2 screen_to_texcoord(float4 p)
{
    return (p.xy/p.w)*0.5+0.5;
}
