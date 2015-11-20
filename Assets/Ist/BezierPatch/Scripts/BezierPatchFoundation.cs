using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Ist
{
    // struct for store ComputeBuffer
    [System.Serializable]
    public struct BezierPatchRaw
    {
        public const int size = 12 * 16;

        public Vector3
            cp00, cp01, cp02, cp03,
            cp04, cp05, cp06, cp07,
            cp08, cp09, cp10, cp11,
            cp12, cp13, cp14, cp15;
    }

    [System.Serializable]
    public struct BezierPatchAABB
    {
        public const int size = 12 * 2;

        public Vector3 center, extents;
    }

    [System.Serializable]
    public struct BezierPatchHit
    {
        public Vector2 uv;
        public float t;
        public uint clip_level;
    };



    [System.Serializable]
    public class BezierPatch
    {
        public Vector3[] cp = DefaultControlPoints();


        public Vector3 Evaluate(Vector2 uv)
        {
            return uosBPEvaluate(ref cp[0], ref uv);
        }

        public Vector3 EvaluateNormal(Vector2 uv)
        {
            return uosBPEvaluateNormal(ref cp[0], ref uv);
        }


        public void Split(ref BezierPatch dst0, ref BezierPatch dst1, ref BezierPatch dst2, ref BezierPatch dst3, ref Vector2 uv)
        {
            uosBPSplit(ref cp[0], ref dst0.cp[0], ref dst1.cp[0], ref dst2.cp[0], ref dst3.cp[0], ref uv);
        }
        public void SplitU(ref BezierPatch dst0, ref BezierPatch dst1, float u)
        {
            uosBPSplitU(ref cp[0], ref dst0.cp[0], ref dst1.cp[0], u);
        }
        public void SplitV(ref BezierPatch dst0, ref BezierPatch dst1, float v)
        {
            uosBPSplitV(ref cp[0], ref dst0.cp[0], ref dst1.cp[0], v);
        }

        public void Crop(ref BezierPatch dst0, ref Vector2 uv0, ref Vector2 uv1)
        {
            uosBPCrop(ref cp[0], ref dst0.cp[0], ref uv0, ref uv1);
        }
        public void CropU(ref BezierPatch dst0, ref Vector2 uv0, float u0, float u1)
        {
            uosBPCropU(ref cp[0], ref dst0.cp[0], u0, u1);
        }
        public void CropV(ref BezierPatch dst0, ref Vector2 uv0, float v0, float v1)
        {
            uosBPCropV(ref cp[0], ref dst0.cp[0], v0, v1);
        }

        public void Transform(ref Matrix4x4 mat)
        {
            uosBPTransform(ref cp[0], ref mat);
        }

        public bool Raycast(Vector3 orig, Vector3 dir, float zmin, float zmax, float epsilon, ref BezierPatchHit hit)
        {
            return uosBPRaycast(ref cp[0], ref orig, ref dir, zmin, zmax, epsilon, ref hit);
        }

        public bool Raycast(ref Matrix4x4 trans, Vector3 orig, Vector3 dir, float zmin, float zmax, float epsilon, ref BezierPatchHit hit)
        {
            return uosBPRaycastWithTransform(ref cp[0], ref trans, ref orig, ref dir, zmin, zmax, epsilon, ref hit);
        }


        // I HATE C#
        public void GetRawData(ref BezierPatchRaw dst)
        {
            dst.cp00 = cp[ 0]; dst.cp01 = cp[ 1]; dst.cp02 = cp[ 2]; dst.cp03 = cp[ 3];
            dst.cp04 = cp[ 4]; dst.cp05 = cp[ 5]; dst.cp06 = cp[ 6]; dst.cp07 = cp[ 7];
            dst.cp08 = cp[ 8]; dst.cp09 = cp[ 9]; dst.cp10 = cp[10]; dst.cp11 = cp[11];
            dst.cp12 = cp[12]; dst.cp13 = cp[13]; dst.cp14 = cp[14]; dst.cp15 = cp[15];
        }
        public void SetRawData(ref BezierPatchRaw src)
        {
            cp[ 0] = src.cp00; cp[ 1] = src.cp01; cp[ 2] = src.cp02; cp[ 3] = src.cp03;
            cp[ 4] = src.cp04; cp[ 5] = src.cp05; cp[ 6] = src.cp06; cp[ 7] = src.cp07;
            cp[ 8] = src.cp08; cp[ 9] = src.cp09; cp[10] = src.cp10; cp[11] = src.cp11;
            cp[12] = src.cp12; cp[13] = src.cp13; cp[14] = src.cp14; cp[15] = src.cp15;
        }

        public void GetAABB(ref BezierPatchAABB dst)
        {
            Vector3 min = cp[0];
            Vector3 max = cp[0];
            for(int i=1; i<cp.Length; ++i)
            {
                min = Vector3.Min(min, cp[i]);
                max = Vector3.Max(max, cp[i]);
            }
            dst.center = (max + min) * 0.5f;
            dst.extents = (max - min) * 0.5f;
        }

        public void DrawWireframe(Color color)
        {
            GL.Begin(GL.LINES);
            GL.Color(color);
            for (int y = 0; y < 4; ++y)
            {
                for (int x = 0; x < 3; ++x)
                {
                    GL.Vertex(cp[y * 4 + (x + 0)]);
                    GL.Vertex(cp[y * 4 + (x + 1)]);
                }
            }
            for (int y = 0; y < 3; ++y)
            {
                for (int x = 0; x < 4; ++x)
                {
                    GL.Vertex(cp[(y + 0) * 4 + x]);
                    GL.Vertex(cp[(y + 1) * 4 + x]);
                }
            }
            GL.End();
        }

        public void OnDrawGizmo(Color color)
        {
            Gizmos.color = color;
            for (int y = 0; y < 4; ++y)
            {
                for (int x = 0; x < 3; ++x)
                {
                    Gizmos.DrawLine(cp[y * 4 + x], cp[y * 4 + x + 1]);
                }
            }
            for (int y = 0; y < 3; ++y)
            {
                for (int x = 0; x < 4; ++x)
                {
                    Gizmos.DrawLine(cp[y * 4 + x], cp[(y + 1) * 4 + x]);
                }
            }
        }

        #region impl
        static Vector3[] DefaultControlPoints()
        {
            var cp = new Vector3[16];
            float span = 2.0f / 3.0f;
            for (int y = 0; y < 4; ++y)
            {
                for (int x = 0; x < 4; ++x)
                {
                    cp[4 * y + x] = new Vector3(-1.0f + span * x, 0.0f, -1.0f + span * y);
                }
            }
            return cp;
        }


        [DllImport("UnityOpenSubdiv")]
        static extern Vector3 uosBPEvaluate(ref Vector3 bp, ref Vector2 uv);
        [DllImport("UnityOpenSubdiv")]
        static extern Vector3 uosBPEvaluateNormal(ref Vector3 bp, ref Vector2 uv);

        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPSplit(ref Vector3 bp, ref Vector3 dst0, ref Vector3 dst1, ref Vector3 dst2, ref Vector3 dst3, ref Vector2 uv);
        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPSplitU(ref Vector3 bp, ref Vector3 dst0, ref Vector3 dst1, float u);
        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPSplitV(ref Vector3 bp, ref Vector3 dst0, ref Vector3 dst1, float v);
        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPCrop(ref Vector3 bp, ref Vector3 dst0, ref Vector2 uv0, ref Vector2 uv1);
        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPCropU(ref Vector3 bp, ref Vector3 dst0, float u0, float u1);
        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPCropV(ref Vector3 bp, ref Vector3 dst0, float v0, float v1);

        [DllImport("UnityOpenSubdiv")]
        static extern void uosBPTransform(ref Vector3 bp, ref Matrix4x4 mat);

        [DllImport("UnityOpenSubdiv")]
        static extern bool uosBPRaycast(ref Vector3 bp, ref Vector3 orig, ref Vector3 dir, float zmin, float zmax, float epsilon, ref BezierPatchHit hit);
        [DllImport("UnityOpenSubdiv")]
        static extern bool uosBPRaycastWithTransform(ref Vector3 bp, ref Matrix4x4 mat, ref Vector3 orig, ref Vector3 dir, float zmin, float zmax, float epsilon, ref BezierPatchHit hit);
        #endregion
    }
}
