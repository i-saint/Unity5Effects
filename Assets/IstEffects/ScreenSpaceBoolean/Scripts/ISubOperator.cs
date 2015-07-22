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
    public abstract class ISubOperator : GroupedInstanceSet<ISubOperator>
    {
        public abstract void IssueDrawCall_DepthMask(SubRenderer br, CommandBuffer cb);
    }
}