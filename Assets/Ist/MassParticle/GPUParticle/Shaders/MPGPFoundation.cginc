#ifndef MPGPFoundation_h
#define MPGPFoundation_h

#include "../../../Foundation/Shaders/Math.cginc"
#include "../../../Foundation/Shaders/Geometry.cginc"
#include "../../../Foundation/Shaders/Random.cginc"

// surface shader + BezierPatch.cginc cause compile error...
#ifndef MPGP_FOR_DRAW
    #include "../../../Foundation/Shaders/BezierPatch.cginc"
    #include "../../../Foundation/Shaders/BezierPatchIntersection.cginc"
#endif

struct WorldIData
{
    int num_active_particles;
    uint id_seed;
    int dummy[2];
};

struct WorldData
{
    float timestep;
    float particle_size;
    float particle_lifetime;
    float pressure_stiffness;
    float wall_stiffness;
    float gbuffer_stiffness;
    float gbuffer_thickness;
    float damping;
    float advection;
    int num_max_particles;
    int num_additional_particles;
    int num_sphere_colliders;
    int num_capsule_colliders;
    int num_box_colliders;
    int num_bp_colliders;
    int num_forces;
    float3 world_center;
    float3 world_extents;
    int3 world_div;
    int3 world_div_bits;
    uint3 world_div_shift;
    float3 world_cellsize;
    float3 rcp_world_cellsize;
    float2 rt_size;
    float4x4 view_proj;
    float4x4 inv_view_proj;
    float rcp_particle_size2;
    float3 coord_scaler;
};

struct SPHParams
{
    float smooth_len;
    float particle_mass;
    float pressure_stiffness;
    float rest_density;
    float viscosity;
    float density_coef;
    float pressure_coef;
    float viscosity_coef;
};

struct Particle
{
    float3 position;
    float3 velocity;
    float speed;
    float lifetime;
    float density;
    int hit_objid;
    uint id;
    float pad0;
};

#ifndef MPGP_FOR_DRAW

struct Cell
{
    int begin;
    int end;
};

struct ParticleIData
{
    float3 accel;
    float affection;
};


struct ColliderInfo
{
    int owner_objid;
    AABB aabb;
};


struct SphereCollider
{
    ColliderInfo info;
    Sphere shape;
};

struct CapsuleCollider
{
    ColliderInfo info;
    Capsule shape;
};

struct BoxCollider
{
    ColliderInfo info;
    Box shape;
};

struct BezierPatchCollider
{
    ColliderInfo info;
    BezierPatch shape;
};


struct ForceInfo
{
    int shape_type; // 0: affect all, 1: sphere, 2: capsule, 3: box
    int dir_type; // 0: directional, 1: radial, 2: vector field
    float strength;
    float random_seed;
    float random_diffuse;
    float3 direction;    // dir_type: directional
    float3 center;       // dir_type: radial
    float3 rcp_cellsize; // dir_type: vector field
};

struct Force
{
    ForceInfo info;
    Sphere sphere;
    Capsule capsule;
    Box box;
};

#endif // MPGP_FOR_DRAW



struct TrailParams
{
    float delta_time;
    uint max_entities;
    uint max_history;
    float interval;
};

struct TrailEntity
{
    uint id;
    float time;
    uint frame;
};

struct TrailHistory
{
    float3 position;
};

struct TrailVertex
{
    float3 position;
    float3 tangent;
    float2 texcoord;
};


struct Vertex
{
    float3 position;
    float3 normal;
    float4 tangent;
    float2 texcoord;
};


float2 screen_to_texcoord(float2 p)
{
    return p*0.5+0.5;
}
float2 screen_to_texcoord(float4 p)
{
    return (p.xy/p.w)*0.5+0.5;
}


#endif // MPGPFoundation_h
