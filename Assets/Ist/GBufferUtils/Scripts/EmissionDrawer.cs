using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    [RequireComponent(typeof(Renderer))]
    [ExecuteInEditMode]
    public class EmissionDrawer : ICommandBufferExecuter<EmissionDrawer>
    {
        public Material[] m_materials;

#if UNITY_EDITOR
        void Reset()
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/GBufferUtils/Materials/Depth.mat");
            int num_materials = GetComponent<Renderer>().sharedMaterials.Length;
            m_materials = new Material[num_materials];
            for (int i = 0; i < m_materials.Length; ++i)
            {
                m_materials[i] = mat;
            }
        }
#endif // UNITY_EDITOR

        public void IssueDrawCall(CommandBuffer commands)
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            var renderer = GetComponent<Renderer>();
            for (int i = 0; i < m_materials.Length; ++i)
            {
                commands.DrawRenderer(renderer, m_materials[i], i, 0);
            }
        }

        protected override void AddCommandBuffer(Camera c, CommandBuffer cb)
        {
            c.AddCommandBuffer(CameraEvent.AfterGBuffer, cb);
        }

        protected override void RemoveCommandBuffer(Camera c, CommandBuffer cb)
        {
            c.RemoveCommandBuffer(CameraEvent.AfterGBuffer, cb);
        }

        protected override void UpdateCommandBuffer(CommandBuffer commands)
        {
            commands.Clear();

            if (Camera.current.hdr)
            {
                commands.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
            }
            else
            {
                commands.SetRenderTarget(BuiltinRenderTextureType.GBuffer3);
            }

            foreach (var i in GetInstances()) { i.IssueDrawCall(commands); }
        }
    }

}