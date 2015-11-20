using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif


namespace Ist
{
    public abstract class IBezierPatchContainer : MonoBehaviour
    {
        public abstract BezierPatchRaw[] GetBezierPatches();
        public abstract BezierPatchAABB[] GetAABBs();
    }
}
