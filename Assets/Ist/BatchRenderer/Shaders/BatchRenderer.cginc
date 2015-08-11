#ifndef BatchRenderer_h
#define BatchRenderer_h

#include "Assets/Ist/BatchRenderer/Shaders/Math.cginc"
#include "Assets/Ist/BatchRenderer/Shaders/Geometry.cginc"



#ifdef SHADER_API_PSSL
#   define COLOR  SV_Target
#   define COLOR0 SV_Target0
#   define COLOR1 SV_Target1
#   define COLOR2 SV_Target2
#   define COLOR3 SV_Target3
#   define DEPTH SV_Depth
#endif

#if (defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL)) && !defined(FORCE_INSTANCE_TEXTURE)
#ifdef ENABLE_INSTANCE_BUFFER
    #define USE_STRUCTURED_BUFFER
#endif
#endif



int     g_num_instances;
float4  g_scale;
float4  g_texel_size;
int     g_flag_rotation;
int     g_flag_scale;
int     g_flag_color;
int     g_flag_emission;
int     g_flag_uvoffset;
int     g_batch_begin;

int     GetNumInstances()       { return g_num_instances; }
float3  GetBaseScale()          { return g_scale.xyz; }
int     GetBatchBegin()         { return g_batch_begin; }
int     GetInstanceID(float2 i) { return i.x + g_batch_begin; }

bool    GetFlag_Rotation()  { return g_flag_rotation!=0; }
bool    GetFlag_Scale()     { return g_flag_scale!=0; }
bool    GetFlag_Color()     { return g_flag_color!=0; }
bool    GetFlag_Emission()  { return g_flag_emission!=0; }
bool    GetFlag_UVOffset()  { return g_flag_uvoffset!=0; }

sampler2D g_instance_texture_t;
sampler2D g_instance_texture_r;
sampler2D g_instance_texture_s;
sampler2D g_instance_texture_color;
sampler2D g_instance_texture_emission;
sampler2D g_instance_texture_uv;

float4  InstanceTexcoord(int i)         { return float4(g_texel_size.xy*float2(fmod(i, g_texel_size.z) + 0.5, floor(i/g_texel_size.z) + 0.5), 0.0, 0.0); }
float3  GetInstanceTranslationT(int i)  { return tex2Dlod(g_instance_texture_t, InstanceTexcoord(i)).xyz;    }
float4  GetInstanceRotationT(int i)     { return tex2Dlod(g_instance_texture_r, InstanceTexcoord(i));        }
float3  GetInstanceScaleT(int i)        { return tex2Dlod(g_instance_texture_s, InstanceTexcoord(i)).xyz;    }
float4  GetInstanceColorT(int i)        { return tex2Dlod(g_instance_texture_color, InstanceTexcoord(i));    }
float4  GetInstanceEmissionT(int i)     { return tex2Dlod(g_instance_texture_emission, InstanceTexcoord(i)); }
float4  GetInstanceUVOffsetT(int i)     { return tex2Dlod(g_instance_texture_uv, InstanceTexcoord(i));       }

#ifdef USE_STRUCTURED_BUFFER

StructuredBuffer<float3>        g_instance_buffer_t;
StructuredBuffer<float4>        g_instance_buffer_r;
StructuredBuffer<float3>        g_instance_buffer_s;
StructuredBuffer<float4>        g_instance_buffer_color;
StructuredBuffer<float4>        g_instance_buffer_emission;
StructuredBuffer<float4>        g_instance_buffer_uv;

float3  GetInstanceTranslationB(int i)   { return g_instance_buffer_t[i];       }
float4  GetInstanceRotationB(int i)      { return g_instance_buffer_r[i];       }
float3  GetInstanceScaleB(int i)         { return g_instance_buffer_s[i];       }
float4  GetInstanceColorB(int i)         { return g_instance_buffer_color[i];   }
float4  GetInstanceEmissionB(int i)      { return g_instance_buffer_emission[i];}
float4  GetInstanceUVOffsetB(int i)      { return g_instance_buffer_uv[i];      }

#endif // USE_STRUCTURED_BUFFER



#ifdef USE_STRUCTURED_BUFFER

float3  GetInstanceTranslation(int i)   { return GetInstanceTranslationB(i); }
float4  GetInstanceRotation(int i)      { return GetInstanceRotationB(i);    }
float3  GetInstanceScale(int i)         { return GetInstanceScaleB(i);       }
float4  GetInstanceColor(int i)         { return GetInstanceColorB(i);       }
float4  GetInstanceEmission(int i)      { return GetInstanceEmissionB(i);    }
float4  GetInstanceUVOffset(int i)      { return GetInstanceUVOffsetB(i);    }

#else

float3  GetInstanceTranslation(int i)   { return GetInstanceTranslationT(i); }
float4  GetInstanceRotation(int i)      { return GetInstanceRotationT(i);    }
float3  GetInstanceScale(int i)         { return GetInstanceScaleT(i);       }
float4  GetInstanceColor(int i)         { return GetInstanceColorT(i);       }
float4  GetInstanceEmission(int i)      { return GetInstanceEmissionT(i);    }
float4  GetInstanceUVOffset(int i)      { return GetInstanceUVOffsetT(i);    }

#endif

#endif // BatchRenderer_h
