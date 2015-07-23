using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    public abstract class ISubReceiver : GroupedInstanceSet<ISubReceiver>
    {
        void OnWillRenderObject()
        {
            SubRenderer.GetInstance()._OnWillRenderObject();
        }

        void OnRenderObject()
        {
            SubRenderer.GetInstance()._OnRenderObject();
        }

        // for detecting piercing
        public abstract void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb);
        public abstract void IssueDrawCall_FrontDepth(SubRenderer br, CommandBuffer cb);
    }
}