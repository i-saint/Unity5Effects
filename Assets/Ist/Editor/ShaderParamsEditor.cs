using System;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ShaderParams))]
public class ShaderParamsEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("Reset Material"))
        {
            var obj = target as ShaderParams;
            obj.ResetMaterial();
            SceneView.RepaintAll();
        }
    }
}
