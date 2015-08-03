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
    public abstract class IAndReceiver : GroupedInstanceSet<IAndReceiver>
    {
        void OnWillRenderObject()
        {
            AndRenderer.GetInstance()._OnWillRenderObject();
        }

        void OnRenderObject()
        {
            AndRenderer.GetInstance()._OnRenderObject();
        }

        public abstract void IssueDrawCall_FrontDepth(AndRenderer br, CommandBuffer cb);
        public abstract void IssueDrawCall_BackDepth(AndRenderer br, CommandBuffer cb);
    }
}