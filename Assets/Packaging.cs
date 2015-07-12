#if UNITY_EDITOR
using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;


public class Packaging
{
    [MenuItem("Assets/Unity5Effects/MakePackage - Mosaic")]
    public static void MakePackage_Mosaic()
    {
        string[] files = new string[]
        {
"Assets/FrameBufferUtils",
"Assets/Mosaic",
        };
        AssetDatabase.ExportPackage(files, "Mosaic.unitypackage", ExportPackageOptions.Recurse);
    }


    [MenuItem("Assets/Unity5Effects/MakePackage - WaterSurface")]
    public static void MakePackage_WaterSurface()
    {
        string[] files = new string[]
        {
"Assets/FrameBufferUtils",
"Assets/WaterSurface",
        };
        AssetDatabase.ExportPackage(files, "WaterSurface.unitypackage", ExportPackageOptions.Recurse);
    }


    [MenuItem("Assets/Unity5Effects/MakePackage - BooleanRenderer")]
    public static void MakePackage_BooleanRenderer()
    {
        string[] files = new string[]
        {
"Assets/FrameBufferUtils",
"Assets/BooleanRenderer",
        };
        AssetDatabase.ExportPackage(files, "BooleanRenderer.unitypackage", ExportPackageOptions.Recurse);
    }
}
#endif
