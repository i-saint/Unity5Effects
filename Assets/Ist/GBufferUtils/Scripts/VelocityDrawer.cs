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
    public abstract class VelocityDrawer : ICommandBufferExecuter<DepthDrawer>
    {
        public Material[] m_materials;

#if UNITY_EDITOR
        void Reset()
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Ist/GBufferUtils/Materials/Velocity.mat");
            int num_materials = GetComponent<Renderer>().sharedMaterials.Length;
            m_materials = new Material[num_materials];
            for (int i = 0; i < m_materials.Length; ++i)
            {
                m_materials[i] = mat;
            }
        }
#endif // UNITY_EDITOR

        void Start()
        {
        }

        void Update()
        {
        }

        public override void OnWillRenderObject()
        {
            base.OnWillRenderObject();

            var cb = GetCommandBuffer();
            var renderer = GetComponent<Renderer>();
            for (int i = 0; i < m_materials.Length; ++i)
            {
                cb.DrawRenderer(renderer, m_materials[i], i, 0);
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

        protected override void UpdateCommandBuffer(CommandBuffer cb)
        {
            cb.Clear();
        }
    }

}