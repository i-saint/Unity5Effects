using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    public abstract class IStencilShadowCaster : InstanceSet<IStencilShadowCaster>
    {
        public abstract void IssueDrawCall_FrontStencil(LightWithStencilShadow light, CommandBuffer commands);
        public abstract void IssueDrawCall_BackStencil(LightWithStencilShadow light, CommandBuffer commands);
    }
}