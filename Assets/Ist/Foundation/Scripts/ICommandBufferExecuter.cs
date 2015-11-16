using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    public abstract class ICommandBufferExecuter<T> : MonoBehaviour where T : ICommandBufferExecuter<T>
    {
        #region static
        static HashSet<T> s_instances;
        static CommandBuffer s_commands;
        static HashSet<Camera> s_cameras;
        static int s_nth;

        static public HashSet<T> GetInstances()
        {
            if (s_instances == null) { s_instances = new HashSet<T>(); }
            return s_instances;
        }

        static public HashSet<Camera> GetCameraTable()
        {
            if (s_cameras == null) { s_cameras = new HashSet<Camera>(); }
            return s_cameras;
        }

        static public CommandBuffer GetCommandBuffer()
        {
            return s_commands;
        }
        #endregion


        public virtual void OnEnable()
        {
            GetInstances().Add(this as T);
        }

        public virtual void OnDisable()
        {
            var intances = GetInstances();
            intances.Remove(this as T);

            if (intances.Count == 0 && s_commands!=null)
            {
                var cam_table = GetCameraTable();
                foreach (var c in cam_table)
                {
                    if (c != null)
                    {
                        RemoveCommandBuffer(c, s_commands);
                    }
                }
                cam_table.Clear();
            }
        }

        public virtual void OnWillRenderObject()
        {
            if (!gameObject.activeInHierarchy && !enabled) { return; }

            if (s_nth++ == 0)
            {
                if (s_commands == null)
                {
                    s_commands = new CommandBuffer();
                    s_commands.name = GetCommandBufferName();
                }
                UpdateCommandBuffer(s_commands);
            }

            var cam = Camera.current;
            if (cam == null) { return; }
            var cam_table = GetCameraTable();
            if (!cam_table.Contains(cam))
            {
                AddCommandBuffer(cam, s_commands);
                cam_table.Add(cam);
            }
        }

        public virtual void OnRenderObject()
        {
            s_nth = 0;
        }


        protected virtual string GetCommandBufferName() { return typeof(T).Name; }

        // add command buffer to camera
        // ex.
        //  cam.AddCommandBuffer(CameraEvent.AfterGBuffer, cb);
        protected abstract void AddCommandBuffer(Camera cam, CommandBuffer cb);

        // remove command buffer to camera
        // ex.
        //  cam.RemoveCommandBuffer(CameraEvent.AfterGBuffer, cb);
        protected abstract void RemoveCommandBuffer(Camera cam, CommandBuffer cb);

        // issue draw commands
        // ex.
        //  cb.Clear();
        //  foreach (var i in GetInstances()) { i.IssueDrawCall(cb); }
        protected abstract void UpdateCommandBuffer(CommandBuffer cb);
    }

}
