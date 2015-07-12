using System;
using UnityEditor;
using UnityEngine;

namespace UnityStandardAssets.ImageEffects
{
    [CustomEditor (typeof(VignetteAndChromaticAberration))]
    class VignetteAndChromaticAberrationEditor : Editor
    {
        private SerializedObject m_SerObj;
        private SerializedProperty m_Mode;
        private SerializedProperty m_Intensity;             // intensity == 0 disables pre pass (optimization)
        private SerializedProperty m_ChromaticAberration;
        private SerializedProperty m_AxialAberration;
        private SerializedProperty m_Blur;                  // blur == 0 disables blur pass (optimization)
        private SerializedProperty m_BlurSpread;
        private SerializedProperty m_BlurDistance;
        private SerializedProperty m_LuminanceDependency;


        void OnEnable ()
        {
            m_SerObj = new SerializedObject (target);
            m_Mode = m_SerObj.FindProperty ("mode");
            m_Intensity = m_SerObj.FindProperty ("intensity");
            m_ChromaticAberration = m_SerObj.FindProperty ("chromaticAberration");
            m_AxialAberration = m_SerObj.FindProperty ("axialAberration");
            m_Blur = m_SerObj.FindProperty ("blur");
            m_BlurSpread = m_SerObj.FindProperty ("blurSpread");
            m_LuminanceDependency = m_SerObj.FindProperty ("luminanceDependency");
            m_BlurDistance = m_SerObj.FindProperty ("blurDistance");
        }


        public override void OnInspectorGUI ()
        {
            m_SerObj.Update ();

            EditorGUILayout.LabelField("Simulates the common lens artifacts 'Vignette' and 'Aberration'", EditorStyles.miniLabel);

            EditorGUILayout.PropertyField (m_Intensity, new GUIContent("Vignetting"));
            EditorGUILayout.PropertyField (m_Blur, new GUIContent(" Blurred Corners"));
            if (m_Blur.floatValue>0.0f)
                EditorGUILayout.PropertyField (m_BlurSpread, new GUIContent(" Blur Distance"));

            EditorGUILayout.Separator ();

            EditorGUILayout.PropertyField (m_Mode, new GUIContent("Aberration"));
            if (m_Mode.intValue>0)
            {
                EditorGUILayout.PropertyField (m_ChromaticAberration, new GUIContent("  Tangential Aberration"));
                EditorGUILayout.PropertyField (m_AxialAberration, new GUIContent("  Axial Aberration"));
                m_LuminanceDependency.floatValue = EditorGUILayout.Slider("  Contrast Dependency", m_LuminanceDependency.floatValue, 0.001f, 1.0f);
                m_BlurDistance.floatValue = EditorGUILayout.Slider("  Blur Distance", m_BlurDistance.floatValue, 0.001f, 5.0f);
            }
            else
                EditorGUILayout.PropertyField (m_ChromaticAberration, new GUIContent(" Chromatic Aberration"));

            m_SerObj.ApplyModifiedProperties();
        }
    }
}
