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
    public abstract class DepthDrawer : ICommandBufferExecuter<DepthDrawer>
    {
        public Material[] m_materials_depth;

#if UNITY_EDITOR
        void Reset()
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/GBufferUtils/Materials/Depth.mat");
            int num_materials = GetComponent<Renderer>().sharedMaterials.Length;
            m_materials_depth = new Material[num_materials];
            for (int i = 0; i < m_materials_depth.Length; ++i)
            {
                m_materials_depth[i] = mat;
            }
        }
#endif // UNITY_EDITOR

        public virtual void IssueDrawCall_FrontDepth(CommandBuffer commands)
        {
            var renderer = GetComponent<Renderer>();
            for (int i = 0; i < m_materials_depth.Length; ++i)
            {
                commands.DrawRenderer(renderer, m_materials_depth[i], i, 1);
            }
        }

        public virtual void IssueDrawCall_BackDepth(CommandBuffer commands)
        {
            var renderer = GetComponent<Renderer>();
            for (int i = 0; i < m_materials_depth.Length; ++i)
            {
                commands.DrawRenderer(renderer, m_materials_depth[i], i, 0);
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

        // subclass should implement UpdateCommandBuffer()
    }

}