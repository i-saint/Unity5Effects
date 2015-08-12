using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR


namespace Ist
{
    [AddComponentMenu("Ist/Screen Space Boolean/Sub Renderer")]
    [ExecuteInEditMode]
    public class SubRenderer : ICommandBufferRenderer<SubRenderer>
    {
        public bool m_enable_piercing = true;

        public Mesh m_quad;
        public Shader m_shader_composite;

        Material m_material_composite;


#if UNITY_EDITOR
        void Reset()
        {
            m_quad = MeshUtils.GenerateQuad();
            m_shader_composite = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/ScreenSpaceBoolean/Shaders/CompositeSub.shader");
        }
#endif // UNITY_EDITOR

        public override void OnDestroy()
        {
            base.OnDestroy();
            Object.DestroyImmediate(m_material_composite);
        }

        protected override void AddCommandBuffer(Camera cam, CommandBuffer cb)
        {
            cam.AddCommandBuffer(CameraEvent.BeforeGBuffer, cb);
        }

        protected override void RemoveCommandBuffer(Camera cam, CommandBuffer cb)
        {
            cam.RemoveCommandBuffer(CameraEvent.BeforeGBuffer, cb);
        }

        protected override void UpdateCommandBuffer(CommandBuffer commands)
        {
            if (m_material_composite == null)
            {
                m_material_composite = new Material(m_shader_composite);
            }

            commands.Clear();
            var greceivers = ISubReceiver.GetGroups();
            var goperators = ISubOperator.GetGroups();
            foreach (var v in greceivers)
            {
                var operators = goperators.ContainsKey(v.Key) ? goperators[v.Key] : null;
                IssueDrawcalls_Depth(commands, v.Value, operators);
            }
        }

        void IssueDrawcalls_Depth(CommandBuffer commands, HashSet<ISubReceiver> receivers, HashSet<ISubOperator> operaors)
        {
            int id_backdepth = Shader.PropertyToID("BackDepth");
            int id_tmpdepth = Shader.PropertyToID("TmpDepth");

            // render back depth if piercing enabled
            if (m_enable_piercing)
            {
                commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
                commands.SetRenderTarget(id_backdepth);
                commands.ClearRenderTarget(true, true, Color.black, 0.0f);
                foreach (var reseiver in receivers)
                {
                    if (reseiver != null)
                    {
                        reseiver.IssueDrawCall_BackDepth(this, commands);
                    }
                }
                commands.SetGlobalTexture("_BackDepth", id_backdepth);
            }

            commands.GetTemporaryRT(id_tmpdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            commands.SetRenderTarget(id_tmpdepth);
            commands.ClearRenderTarget(true, true, Color.black, 1.0f);
            foreach (var reseiver in receivers)
            {
                if (reseiver != null)
                {
                    reseiver.IssueDrawCall_FrontDepth(this, commands);
                }
            }
            if (operaors != null)
            {
                foreach (var op in operaors)
                {
                    if (op != null)
                    {
                        op.IssueDrawCall_DepthMask(this, commands);
                    }
                }
            }

            commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            commands.SetGlobalTexture("_TmpDepth", id_tmpdepth);
            commands.DrawMesh(m_quad, Matrix4x4.identity, m_material_composite);
        }
    }
}