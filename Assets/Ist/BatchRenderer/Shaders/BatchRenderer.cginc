#ifndef BatchRenderer_h
#define BatchRenderer_h

#include "Assets/Ist/Foundation/Shaders/Math.cginc"
#include "Assets/Ist/Foundation/Shaders/Geometry.cginc"


#if ENABLE_INSTANCE_BUFFER
#if (defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL))
    #define USE_STRUCTURED_BUFFER
#endif
#endif


int     g_num_instances;
float4  g_scale;
float4  g_texel_size;
int     g_batch_begin;

int     GetNumInstances()       { return g_num_instances; }
float3  GetBaseScale()          { return g_scale.xyz; }
int     GetBatchBegin()         { return g_batch_begin; }
int     GetInstanceID(float2 i) { return i.x + g_batch_begin; }

#ifdef USE_STRUCTURED_BUFFER

StructuredBuffer<float3>        g_instance_buffer_t;
StructuredBuffer<float4>        g_instance_buffer_r;
StructuredBuffer<float3>        g_instance_buffer_s;
StructuredBuffer<float4>        g_instance_buffer_color;
StructuredBuffer<float4>        g_instance_buffer_emission;
StructuredBuffer<float4>        g_instance_buffer_uv;

float3  GetInstanceTranslation(int i)   { return g_instance_buffer_t[i];       }
float4  GetInstanceRotation(int i)      { return g_instance_buffer_r[i];       }
float3  GetInstanceScale(int i)         { return g_instance_buffer_s[i];       }
float4  GetInstanceColor(int i)         { return g_instance_buffer_color[i];   }
float4  GetInstanceEmission(int i)      { return g_instance_buffer_emission[i];}
float4  GetInstanceUVOffset(int i)      { return g_instance_buffer_uv[i];      }

#else 

sampler2D g_instance_texture_t;
sampler2D g_instance_texture_r;
sampler2D g_instance_texture_s;
sampler2D g_instance_texture_color;
sampler2D g_instance_texture_emission;
sampler2D g_instance_texture_uv;

float4  InstanceTexcoord(int i)         { return float4(g_texel_size.xy*float2(fmod(i, g_texel_size.z) + 0.5, floor(i/g_texel_size.z) + 0.5), 0.0, 0.0); }
float3  GetInstanceTranslation(int i)   { return tex2Dlod(g_instance_texture_t, InstanceTexcoord(i)).xyz;    }
float4  GetInstanceRotation(int i)      { return tex2Dlod(g_instance_texture_r, InstanceTexcoord(i));        }
float3  GetInstanceScale(int i)         { return tex2Dlod(g_instance_texture_s, InstanceTexcoord(i)).xyz;    }
float4  GetInstanceColor(int i)         { return tex2Dlod(g_instance_texture_color, InstanceTexcoord(i));    }
float4  GetInstanceEmission(int i)      { return tex2Dlod(g_instance_texture_emission, InstanceTexcoord(i)); }
float4  GetInstanceUVOffset(int i)      { return tex2Dlod(g_instance_texture_uv, InstanceTexcoord(i));       }

#endif // USE_STRUCTURED_BUFFER


#endif // BatchRenderer_h
