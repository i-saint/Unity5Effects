using System;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ShaderParams))]
public class ShaderParamsEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

    }
}
