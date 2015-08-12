using System;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MaterialSettings))]
public class MaterialSettingsEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        if (GUILayout.Button("Assign"))
        {
            var obj = target as MaterialSettings;
            obj.AssignParams();
            SceneView.RepaintAll();
        }
    }
}
