using System;
using UnityEditor;
using UnityEngine;

namespace Ist
{

    [CustomEditor(typeof(BezierPatchEditor))]
    public class BezierPatchEditorEditor : Editor
    {
        private void OnEnable()
        {
        }
    
    
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();
    
            //if (GUILayout.Button("Generate Mesh"))
            //{
            //    var t = target as BezierPatchEditor;
            //    t.GenerateMesh();
            //}
        }
    }
}
