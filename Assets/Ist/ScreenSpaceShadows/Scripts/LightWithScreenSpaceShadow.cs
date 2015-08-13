using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    // MeshRenderer is needed to handle OnWillRenderObject()
    [AddComponentMenu("Ist/Screen Space Shadow/Light")]
    [RequireComponent(typeof(MeshFilter))]
    [RequireComponent(typeof(MeshRenderer))]
    [ExecuteInEditMode]
    public class LightWithScreenSpaceShadow : ICommandBufferExecuter<LightWithScreenSpaceShadow>
    {
        public enum Type
        {
            Point,
            Line,
        }
        public enum Sample
        {
            Fast,
            Medium,
            High,
        }
        public Type m_type = Type.Point;
        public bool m_cast_shadow = true;
        public Sample m_sample = Sample.Medium;
        public float m_range = 10.0f;
        public Color m_color = Color.white;
        public float m_intensity = 1.0f;
        public float m_inner_radius = 0.0f;
        public float m_capsule_length = 1.0f;
        public float m_occulusion_strength = 2.0f;

        public Shader m_light_shader;
        Material m_light_material;


        public Vector4 GetPositionAndRadius()
        {
            var pos = GetComponent<Transform>().position;
            return new Vector4(pos.x, pos.y, pos.z, m_range);
        }
        public Vector4 GetLinearColor()
        {
            return new Vector4(
                Mathf.GammaToLinearSpace(m_color.r * m_intensity),
                Mathf.GammaToLinearSpace(m_color.g * m_intensity),
                Mathf.GammaToLinearSpace(m_color.b * m_intensity),
                1.0f
            );
        }
        public Vector4 GetParams()
        {
            return new Vector4(m_inner_radius, m_capsule_length, (float)m_type, m_occulusion_strength);
        }
        public Matrix4x4 GetTRS()
        {
            return GetComponent<Transform>().localToWorldMatrix;
        }
        public Mesh GetMesh()
        {
            return GetComponent<MeshFilter>().sharedMesh;
        }

        public void IssueDrawCall(CommandBuffer commands)
        {
            if (m_light_material == null)
            {
                m_light_material = new Material(m_light_shader);
            }

            var cam = Camera.current;
            if (cam.hdr)
            {
                m_light_material.SetInt("_SrcBlend", (int)BlendMode.One);
                m_light_material.SetInt("_DstBlend", (int)BlendMode.One);
            }
            else
            {
                m_light_material.SetInt("_SrcBlend", (int)BlendMode.DstColor);
                m_light_material.SetInt("_DstBlend", (int)BlendMode.Zero);
            }

            // set light type
            {
                switch (m_type)
                {
                    case Type.Point:
                        m_light_material.EnableKeyword ("POINT_LIGHT");
                        m_light_material.DisableKeyword("LINE_LIGHT");
                        break;
                    case Type.Line:
                        m_light_material.DisableKeyword("POINT_LIGHT");
                        m_light_material.EnableKeyword ("LINE_LIGHT");
                        break;
                }
            }

            // set shadow settings
            if (m_cast_shadow)
            {
                m_light_material.EnableKeyword("ENABLE_SHADOW");
                switch (m_sample)
                {
                    case Sample.Fast:
                        m_light_material.EnableKeyword ("QUALITY_FAST");
                        m_light_material.DisableKeyword("QUALITY_MEDIUM");
                        m_light_material.DisableKeyword("QUALITY_HIGH");
                        break;
                    case Sample.Medium:
                        m_light_material.DisableKeyword("QUALITY_FAST");
                        m_light_material.EnableKeyword ("QUALITY_MEDIUM");
                        m_light_material.DisableKeyword("QUALITY_HIGH");
                        break;
                    case Sample.High:
                        m_light_material.DisableKeyword("QUALITY_FAST");
                        m_light_material.DisableKeyword("QUALITY_MEDIUM");
                        m_light_material.EnableKeyword ("QUALITY_HIGH");
                        break;
                }
            }
            else
            {
                m_light_material.DisableKeyword("ENABLE_SHADOW");
            }

            int id_pos = Shader.PropertyToID("_Position");
            int id_color = Shader.PropertyToID("_Color");
            int id_params = Shader.PropertyToID("_Params1");
            commands.SetGlobalVector(id_pos, GetPositionAndRadius());
            commands.SetGlobalVector(id_color, GetLinearColor());
            commands.SetGlobalVector(id_params, GetParams());
            commands.DrawMesh(GetMesh(), GetTRS(), m_light_material, 0, 0);
        }


#if UNITY_EDITOR
        void Reset()
        {
            m_light_shader = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/ScreenSpaceShadows/Shaders/Light.shader");
            GetComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/Ist/Utilities/Meshes/IcoSphere.asset");
            GetComponent<MeshRenderer>().sharedMaterials = new Material[0];
        }
#endif // UNITY_EDITOR

        void OnDestroy()
        {
            if (m_light_material != null)
            {
                Object.DestroyImmediate(m_light_material);
            }
        }

        void Update()
        {
            GetComponent<Transform>().localScale = new Vector3(m_range * 2.0f, m_range * 2.0f, m_range * 2.0f);
        }

        void OnDrawGizmos()
        {
            Gizmos.DrawIcon(transform.position, m_type == Type.Line ? "AreaLight Gizmo" : "PointLight Gizmo", true);
        }

        void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(0.1f, 0.7f, 1.0f, 0.6f);
            if (m_type == Type.Line)
            {
                Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, new Vector3(m_capsule_length * 2, m_inner_radius * 2, m_inner_radius * 2));
                Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
            }
            else
            {
                Gizmos.matrix = Matrix4x4.identity;
                Gizmos.DrawWireSphere(transform.position, m_inner_radius);
            }
            Gizmos.matrix = Matrix4x4.identity;
            Gizmos.DrawWireSphere(transform.position, m_range);
        }



        protected override void AddCommandBuffer(Camera cam, CommandBuffer cb)
        {
#if UNITY_EDITOR
            if (cam.renderingPath != RenderingPath.DeferredShading &&
                (cam.renderingPath == RenderingPath.UsePlayerSettings && PlayerSettings.renderingPath != RenderingPath.DeferredShading))
            {
                Debug.Log("Rendering path must be deferred.");
            }
#endif // UNITY_EDITOR
            cam.AddCommandBuffer(CameraEvent.AfterLighting, cb);
        }

        protected override void RemoveCommandBuffer(Camera cam, CommandBuffer cb)
        {
            cam.RemoveCommandBuffer(CameraEvent.AfterLighting, cb);
        }

        protected override void UpdateCommandBuffer(CommandBuffer commands)
        {
            Camera cam = Camera.current;
            var rt_default = cam.hdr ? BuiltinRenderTextureType.CameraTarget : BuiltinRenderTextureType.GBuffer3;
            var rt_default_depth = BuiltinRenderTextureType.CameraTarget;

            commands.Clear();
            commands.SetRenderTarget(rt_default, rt_default_depth);
            foreach (var light in GetInstances())
            {
                light.IssueDrawCall(commands);
            }
        }
    }
}