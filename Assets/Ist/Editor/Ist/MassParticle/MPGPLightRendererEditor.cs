using System;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MPGPLightRenderer))]
public class MPGPLightRendererEditor : Editor
{
    SerializedObject m_obj;

    SerializedProperty m_mesh;
    SerializedProperty m_material;
    SerializedProperty m_camera;

    SerializedProperty m_color;
    SerializedProperty m_intensity;

    SerializedProperty m_heat_color;
    SerializedProperty m_heat_intensity;
    SerializedProperty m_heat_threshold;

    SerializedProperty m_size;
    SerializedProperty m_enable_shadow;
    SerializedProperty m_sample;
    SerializedProperty m_occulusion_strength;


    void OnEnable()
    {
        m_obj = new SerializedObject(target);

        m_mesh = m_obj.FindProperty("m_mesh");
        m_material = m_obj.FindProperty("m_material");
        m_camera = m_obj.FindProperty("m_camera");

        m_color = m_obj.FindProperty("m_color");
        m_intensity = m_obj.FindProperty("m_intensity");

        m_heat_color = m_obj.FindProperty("m_heat_color");
        m_heat_intensity = m_obj.FindProperty("m_heat_intensity");
        m_heat_threshold = m_obj.FindProperty("m_heat_threshold");

        m_size = m_obj.FindProperty("m_size");
        m_enable_shadow = m_obj.FindProperty("m_enable_shadow");
        m_sample = m_obj.FindProperty("m_sample");
        m_occulusion_strength = m_obj.FindProperty("m_occulusion_strength");
    }



    public override void OnInspectorGUI()
    {
        var tobj = target as MPGPLightRenderer;

        m_obj.Update();

        EditorGUILayout.PropertyField(m_camera, new GUIContent("Camera"));

        EditorGUILayout.PropertyField(m_color, new GUIContent("Color"));
        EditorGUILayout.PropertyField(m_intensity, new GUIContent("Intensity"));

        EditorGUILayout.PropertyField(m_heat_color, new GUIContent("Heat Color"));
        EditorGUILayout.PropertyField(m_heat_intensity, new GUIContent("Heat Intensity"));
        EditorGUILayout.PropertyField(m_heat_threshold, new GUIContent("Heat Threshold"));

        EditorGUILayout.PropertyField(m_size, new GUIContent("Size"));
        EditorGUILayout.PropertyField(m_enable_shadow, new GUIContent("Enable Shadow"));
        if(tobj.m_enable_shadow)
        {
            EditorGUILayout.PropertyField(m_sample, new GUIContent("Samples"));
            EditorGUILayout.PropertyField(m_occulusion_strength, new GUIContent("Occulusion Strength"));
        }

        EditorGUILayout.PropertyField(m_mesh, new GUIContent("Mesh"));
        EditorGUILayout.PropertyField(m_material, new GUIContent("Material"));

        m_obj.ApplyModifiedProperties();
    }
}
