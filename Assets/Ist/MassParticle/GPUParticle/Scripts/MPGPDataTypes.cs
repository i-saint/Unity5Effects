using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Ist
{
    public struct MPGPParticle
    {
        public const int size = 48;
    
        public Vector3 position;
        public Vector3 velocity;
        public float speed;
        public float lifetime;
        public float density;
        public int hit_objid;
        public uint id;
        public float pad0;
    };

    public struct MPGPSortData
    {
        public const int size = 8;
    
        public uint key;
        public uint index;
    }

    public struct MPGPCell
    {
        public const int size = 8;
    
        public int begin;
        public int end;
    }

    public struct MPGPParticleIData
    {
        public const int size = 16;
    
        public int begin;
        public int end;
    }

    public struct MPGPAABB
    {
        public Vector3 center;
        public Vector3 extents;
    }

    // 28 byte
    public struct MPGPColliderInfo
    {
        public int owner_objid;
        public MPGPAABB aabb;
    }

    public struct MPGPSphere
    {
        public Vector3 center;
        public float radius;
    }

    public struct MPGPCapsule
    {
        public Vector3 pos1;
        public Vector3 pos2;
        public float radius;
    }

    public struct MPGPPlane
    {
        public Vector3 normal;
        public float distance;
    }

    public struct MPGPBox
    {
        public Vector3 center;
        public MPGPPlane plane0;
        public MPGPPlane plane1;
        public MPGPPlane plane2;
        public MPGPPlane plane3;
        public MPGPPlane plane4;
        public MPGPPlane plane5;
    }

    public struct MPGPSphereColliderData
    {
        public const int size = 44;
    
        public MPGPColliderInfo info;
        public MPGPSphere shape;
    }

    public struct MPGPCapsuleColliderData
    {
        public const int size = 56;
    
        public MPGPColliderInfo info;
        public MPGPCapsule shape;
    }

    public struct MPGPBoxColliderData
    {
        public const int size = 136;
    
        public MPGPColliderInfo info;
        public MPGPBox shape;
    }

    public struct MPGPBezierPatchColliderData
    {
        public const int size = 220;

        public MPGPColliderInfo info;
        // raw bezier patch (control points) data
        public Vector3
            cp00, cp01, cp02, cp03,
            cp10, cp11, cp12, cp13,
            cp20, cp21, cp22, cp23,
            cp30, cp31, cp32, cp33;

        public void AssignControlPoints(Vector3[] src)
        {
            // I hate C# :(
            cp00 = src[0]; cp01 = src[1]; cp02 = src[2]; cp03 = src[3];
            cp10 = src[4]; cp11 = src[5]; cp12 = src[6]; cp13 = src[7];
            cp20 = src[8]; cp21 = src[9]; cp22 = src[10]; cp23 = src[11];
            cp30 = src[12]; cp31 = src[13]; cp32 = src[14]; cp33 = src[15];
        }
    }



    public struct MPGPWorldIData
    {
        public const int size = 16;
    
        public int num_active_particles;
        public uint id_seed;
        public int dummy2;
        public int dummy3;
    }
    
    public struct MPGPWorldData
    {
        public const int size = 300;
    
        public float timestep;
        public float particle_size;
        public float particle_lifetime;
        public float pressure_stiffness;
        public float wall_stiffness;
        public float gbuffer_stiffness;
        public float gbuffer_thickness;
        public float damping;
        public float advection;
        public int num_max_particles;
        public int num_additional_particles;
        public int num_sphere_colliders;
        public int num_capsule_colliders;
        public int num_box_colliders;
        public int num_bp_colliders;
        public int num_forces;
        public Vector3 world_center;
        public Vector3 world_extents;
        public int world_div_x;
        public int world_div_y;
        public int world_div_z;
        public int world_div_bits_x;
        public int world_div_bits_y;
        public int world_div_bits_z;
        public uint world_div_shift_x;
        public uint world_div_shift_y;
        public uint world_div_shift_z;
        public Vector3 world_cellsize;
        public Vector3 rcp_world_cellsize;
        public Vector2 rt_size;
        public Matrix4x4 view_proj;
        public Matrix4x4 inv_view_proj;
        public float rcp_particle_size2;
        public Vector3 coord_scaler;
    
        public void SetDefaultValues()
        {
            timestep = 0.01f;
            particle_size = 0.1f;
            particle_lifetime = 20.0f;
            wall_stiffness = 3000.0f;
            pressure_stiffness = 500.0f;
            damping = 0.6f;
            advection = 0.5f;
    
            num_max_particles = 0;
            num_sphere_colliders = 0;
            num_capsule_colliders = 0;
            num_box_colliders = 0;
            num_bp_colliders = 0;
            rcp_particle_size2 = 1.0f / (particle_size * 2.0f);
            coord_scaler = Vector3.one;
        }
    
        public static uint MSB(uint x)
        {
            for (int i = 31; i >= 0; --i)
            {
                if ((x & (1 << i)) != 0) { return (uint)i; }
            }
            return 0;
        }
    
        public void SetWorldSize(Vector3 center, Vector3 extents, uint div_x, uint div_y, uint div_z)
        {
            world_center = center;
            world_extents = extents;
            div_x = MSB(div_x);
            div_y = MSB(div_y);
            div_z = MSB(div_z);
            world_div_bits_x = (int)div_x;
            world_div_bits_y = (int)div_y;
            world_div_bits_z = (int)div_z;
            world_div_x = (int)(1U << (int)div_x);
            world_div_y = (int)(1U << (int)div_y);
            world_div_z = (int)(1U << (int)div_z);
            world_div_shift_x = 1U;
            world_div_shift_y = 1U << (int)(div_x);
            world_div_shift_z = 1U << (int)(div_x + div_y);
            world_cellsize = new Vector3(
                world_extents.x * 2.0f / world_div_x,
                world_extents.y * 2.0f / world_div_y,
                world_extents.z * 2.0f / world_div_z);
            rcp_world_cellsize = new Vector3(
                1.0f / world_cellsize.x,
                1.0f / world_cellsize.y,
                1.0f / world_cellsize.z );
        }
    };
    
    public struct MPGPSPHParams
    {
        public const int size = 32;
    
        public float smooth_len;
        public float particle_mass;
        public float pressure_stiffness;
        public float rest_density;
        public float viscosity;
        public float density_coef;
        public float pressure_coef;
        public float viscosity_coef;
    
        public void SetDefaultValues(float particle_size)
        {
            smooth_len = 0.2f;
            particle_mass = 0.001f;
            pressure_stiffness = 50.0f;
            rest_density = 500.0f;
            viscosity = 0.2f;
    
            density_coef = particle_mass * 315.0f / (64.0f * Mathf.PI * Mathf.Pow(particle_size, 9.0f));
            pressure_coef = particle_mass * -45.0f / (Mathf.PI * Mathf.Pow(particle_size, 6.0f));
            viscosity_coef = particle_mass * viscosity * 45.0f / (Mathf.PI * Mathf.Pow(particle_size, 6.0f));
        }
    };
    
    
    public struct MPGPTrailParams
    {
        public const int size = 16;
    
        public float delta_time;
        public int max_entities;
        public int max_history;
        public float interval;
    };
    
    public struct MPGPTrailEntity
    {
        public const int size = 12;
    
        public uint id;
        public float time;
        public uint frame;
    };
    
    public struct MPGPTrailHistory
    {
        public const int size = 12;
    
        public Vector3 position;
    };
    
    public struct MPGPTrailVertex
    {
        public const int size = 32;
    
        public Vector3 position;
        public Vector3 tangent;
        public Vector2 texcoord;
    };
    
    
    
    public class MPGPImpl
    {
        public static Color WorldGizmoColor = Color.magenta;
        public static Color EmitterGizmoColor = Color.magenta;
        public static Color ColliderGizmoColor = Color.magenta;
        public static Color ForceGizmoColor = Color.magenta;
    
        static void BuildColliderInfo<T>(ref MPGPColliderInfo info, T col, int id) where T : Collider
        {
            info.owner_objid = id;
            info.aabb.center = col.bounds.center;
            info.aabb.extents = col.bounds.extents;
        }
    
        static public void BuildSphereCollider(ref MPGPSphereColliderData cscol, Transform t, ref Vector3 center, float radius, int id)
        {
            cscol.shape.center = t.localToWorldMatrix * new Vector4(center.x, center.y, center.z, 1.0f);
            cscol.shape.radius = radius * t.localScale.x;
            cscol.info.aabb.center = t.position;
            cscol.info.aabb.extents = Vector3.one * cscol.shape.radius;
            cscol.info.owner_objid = id;
        }
    
        static public void BuildCapsuleCollider(ref MPGPCapsuleColliderData cscol, Transform t, ref Vector3 center, float radius, float length, int dir, int id)
        {
            Vector3 e = Vector3.zero;
            float h = Mathf.Max(0.0f, length - radius * 2.0f);
            float r = radius * t.localScale.x;
            switch (dir)
            {
                case 0: e.Set(h * 0.5f, 0.0f, 0.0f); break;
                case 1: e.Set(0.0f, h * 0.5f, 0.0f); break;
                case 2: e.Set(0.0f, 0.0f, h * 0.5f); break;
            }
            Vector4 pos1 = new Vector4(e.x + center.x, e.y + center.y, e.z + center.z, 1.0f);
            Vector4 pos2 = new Vector4(-e.x + center.x, -e.y + center.y, -e.z + center.z, 1.0f);
            pos1 = t.localToWorldMatrix * pos1;
            pos2 = t.localToWorldMatrix * pos2;
            cscol.shape.radius = r;
            cscol.shape.pos1 = pos1;
            cscol.shape.pos2 = pos2;
            cscol.info.aabb.center = t.position;
            cscol.info.aabb.extents = Vector3.one * (r+h);
            cscol.info.owner_objid = id;
        }
    
        static public void BuildBox(ref MPGPBox shape, ref Matrix4x4 mat, ref Vector3 center, ref Vector3 _size)
        {
            Vector3 size = _size * 0.5f;
            Vector3[] vertices = new Vector3[8] {
                new Vector3(size.x + center.x, size.y + center.y, size.z + center.z),
                new Vector3(-size.x + center.x, size.y + center.y, size.z + center.z),
                new Vector3(-size.x + center.x, -size.y + center.y, size.z + center.z),
                new Vector3(size.x + center.x, -size.y + center.y, size.z + center.z),
                new Vector3(size.x + center.x, size.y + center.y, -size.z + center.z),
                new Vector3(-size.x + center.x, size.y + center.y, -size.z + center.z),
                new Vector3(-size.x + center.x, -size.y + center.y, -size.z + center.z),
                new Vector3(size.x + center.x, -size.y + center.y, -size.z + center.z),
            };
            for (int i = 0; i < vertices.Length; ++i)
            {
                vertices[i] = mat * vertices[i];
            }
            Vector3[] normals = new Vector3[6] {
                Vector3.Cross(vertices[3] - vertices[0], vertices[4] - vertices[0]).normalized,
                Vector3.Cross(vertices[5] - vertices[1], vertices[2] - vertices[1]).normalized,
                Vector3.Cross(vertices[7] - vertices[3], vertices[2] - vertices[3]).normalized,
                Vector3.Cross(vertices[1] - vertices[0], vertices[4] - vertices[0]).normalized,
                Vector3.Cross(vertices[1] - vertices[0], vertices[3] - vertices[0]).normalized,
                Vector3.Cross(vertices[7] - vertices[4], vertices[5] - vertices[4]).normalized,
            };
            float[] distances = new float[6] {
                -Vector3.Dot(vertices[0], normals[0]),
                -Vector3.Dot(vertices[1], normals[1]),
                -Vector3.Dot(vertices[0], normals[2]),
                -Vector3.Dot(vertices[3], normals[3]),
                -Vector3.Dot(vertices[0], normals[4]),
                -Vector3.Dot(vertices[4], normals[5]),
            };
            shape.center = mat.GetColumn(3);
            shape.plane0.normal = normals[0];
            shape.plane0.distance = distances[0];
            shape.plane1.normal = normals[1];
            shape.plane1.distance = distances[1];
            shape.plane2.normal = normals[2];
            shape.plane2.distance = distances[2];
            shape.plane3.normal = normals[3];
            shape.plane3.distance = distances[3];
            shape.plane4.normal = normals[4];
            shape.plane4.distance = distances[4];
            shape.plane5.normal = normals[5];
            shape.plane5.distance = distances[5];
        }
    
        static public void BuildBoxCollider(ref MPGPBoxColliderData cscol, Transform t, ref Vector3 center, ref Vector3 size, int id)
        {
            Matrix4x4 m = t.localToWorldMatrix;
            BuildBox(ref cscol.shape, ref m, ref center, ref size);
    
            Vector3 scaled = new Vector3(
                size.x * t.localScale.x,
                size.y * t.localScale.y,
                size.z * t.localScale.z );
            float s = Mathf.Max(Mathf.Max(scaled.x, scaled.y), scaled.z);
    
            cscol.info.aabb.center = t.position + center;
            cscol.info.aabb.extents = Vector3.one * (s * 1.415f);
            cscol.info.owner_objid = id;
        }
    }
    
    
    public class MPGPUtils
    {
    }
}
