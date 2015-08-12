using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    [AddComponentMenu("Ist/Screen Space Boolean/And Renderer")]
    [ExecuteInEditMode]
    public class AndRenderer : ICommandBufferRenderer<AndRenderer>
    {
        public Mesh m_quad;
        public Shader m_shader_composite;

        Material m_material_composite;


#if UNITY_EDITOR
        void Reset()
        {
            m_quad = MeshUtils.GenerateQuad();
            m_shader_composite = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Ist/ScreenSpaceBoolean/Shaders/CompositeAnd.shader");
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
            var ganded = IAndReceiver.GetGroups();
            var gander = IAndOperator.GetGroups();
            foreach (var v in ganded)
            {
                if (gander.ContainsKey(v.Key))
                {
                    IssueDrawcalls(commands, v.Value, gander[v.Key]);
                }
            }
        }

        void IssueDrawcalls(CommandBuffer commands, HashSet<IAndReceiver> receivers, HashSet<IAndOperator> operators)
        {
            int id_backdepth = Shader.PropertyToID("BackDepth");
            int id_frontdepth = Shader.PropertyToID("TmpDepth"); // reuse SubtractionRenderer's buffer
            int id_backdepth2 = Shader.PropertyToID("BackDepth2");
            int id_frontdepth2 = Shader.PropertyToID("TmpDepth2");

            // back depth - receivers
            commands.GetTemporaryRT(id_backdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            commands.SetRenderTarget(id_backdepth);
            commands.ClearRenderTarget(true, true, Color.black, 0.0f);
            foreach (var rcv in receivers)
            {
                if (rcv != null)
                {
                    rcv.IssueDrawCall_BackDepth(this, commands);
                }
            }
            commands.SetGlobalTexture("_BackDepth", id_backdepth);

            // back depth - operators
            commands.GetTemporaryRT(id_backdepth2, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            commands.SetRenderTarget(id_backdepth2);
            commands.ClearRenderTarget(true, true, Color.black, 0.0f);
            foreach (var op in operators)
            {
                if (op != null)
                {
                    op.IssueDrawCall_BackDepth(this, commands);
                }
            }
            commands.SetGlobalTexture("_BackDepth2", id_backdepth2);


            // front depth - receivers
            commands.GetTemporaryRT(id_frontdepth, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            commands.SetRenderTarget(id_frontdepth);
            commands.ClearRenderTarget(true, true, Color.black, 1.0f);
            foreach (var rcv in receivers)
            {
                if (rcv != null)
                {
                    rcv.IssueDrawCall_FrontDepth(this, commands);
                }
            }
            commands.SetGlobalTexture("_FrontDepth", id_frontdepth);

            // front depth - operators
            commands.GetTemporaryRT(id_frontdepth2, -1, -1, 24, FilterMode.Point, RenderTextureFormat.Depth);
            commands.SetRenderTarget(id_frontdepth2);
            commands.ClearRenderTarget(true, true, Color.black, 1.0f);
            foreach (var op in operators)
            {
                if (op != null)
                {
                    op.IssueDrawCall_FrontDepth(this, commands);
                }
            }
            commands.SetGlobalTexture("_FrontDepth2", id_frontdepth2);


            // output depth
            commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            commands.DrawMesh(m_quad, Matrix4x4.identity, m_material_composite);
        }
    }
}