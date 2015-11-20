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
    class BezierPatchContainer : IBezierPatchContainer
    {
        BezierPatchRaw[] m_bpatches;
        BezierPatchAABB[] m_aabbs;

        public override BezierPatchRaw[] GetBezierPatches()
        {
            return m_bpatches;
        }
        public override BezierPatchAABB[] GetAABBs()
        {
            return m_aabbs;
        }

        public void SetBezierPatches(BezierPatchRaw[] src)
        {
            m_bpatches = src;
        }
        public void SetAABBs(BezierPatchAABB[] src)
        {
            m_aabbs = src;
        }
    }
}
