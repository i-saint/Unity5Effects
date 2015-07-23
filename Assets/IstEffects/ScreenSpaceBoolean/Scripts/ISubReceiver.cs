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
            Singleton<SubRenderer>.GetInstance()._OnWillRenderObject();
        }

        void OnPostRender()
        {
            Singleton<SubRenderer>.GetInstance()._OnPostRender();
        }

        // for detecting piercing
        public abstract void IssueDrawCall_BackDepth(SubRenderer br, CommandBuffer cb);
        public abstract void IssueDrawCall_FrontDepth(SubRenderer br, CommandBuffer cb);
    }
}