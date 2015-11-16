using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    public abstract class ICommandBufferRenderer<T> : Singleton<T> where T : MonoBehaviour
    {
        CommandBuffer m_commands;
        HashSet<Camera> m_cameras = new HashSet<Camera>();
        int m_nth;

        void OnDisable()
        {
            if (m_commands != null)
            {
                foreach (var cam in m_cameras)
                {
                    if (cam != null)
                    {
                        RemoveCommandBuffer(cam, m_commands);
                    }
                }
                m_cameras.Clear();
            }
        }


        public void _OnWillRenderObject()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            if (m_nth++ == 0)
            {
                if (m_commands == null)
                {
                    m_commands = new CommandBuffer();
                    m_commands.name = GetCommandBufferName();
                }
                UpdateCommandBuffer(m_commands);
            }

            var cam = Camera.current;
            if (!cam) { return; }
            if (!m_cameras.Contains(cam))
            {
                AddCommandBuffer(cam, m_commands);
                m_cameras.Add(cam);
            }
        }

        public void _OnRenderObject()
        {
            m_nth = 0;
        }

        protected virtual string GetCommandBufferName() { return typeof(T).Name; }
        protected abstract void AddCommandBuffer(Camera cam, CommandBuffer cb);
        protected abstract void RemoveCommandBuffer(Camera cam, CommandBuffer cb);
        protected abstract void UpdateCommandBuffer(CommandBuffer cb);
    }
}