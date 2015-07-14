#if UNITY_EDITOR
using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;


public class Packaging
{
    [MenuItem("Assets/Unity5Effects/MakePackages")]
    public static void MakePackages()
    {
        MakePackage_Mosaic();
        MakePackage_WaterSurface();
        MakePackage_BooleanRenderer();
        MakePackage_ScreenSpaceReflections();
    }


    public static void MakePackage_Mosaic()
    {
        string[] files = new string[]
        {
"Assets/Mosaic",
        };
        AssetDatabase.ExportPackage(files, "Mosaic.unitypackage", ExportPackageOptions.Recurse);
    }


    public static void MakePackage_WaterSurface()
    {
        string[] files = new string[]
        {
"Assets/GBufferUtils",
"Assets/WaterSurface",
        };
        AssetDatabase.ExportPackage(files, "WaterSurface.unitypackage", ExportPackageOptions.Recurse);
    }


    public static void MakePackage_BooleanRenderer()
    {
        string[] files = new string[]
        {
"Assets/GBufferUtils",
"Assets/BooleanRenderer",
        };
        AssetDatabase.ExportPackage(files, "BooleanRenderer.unitypackage", ExportPackageOptions.Recurse);
    }


    public static void MakePackage_ScreenSpaceReflections()
    {
        string[] files = new string[]
        {
"Assets/GBufferUtils",
"Assets/ScreenSpaceReflections",
        };
        AssetDatabase.ExportPackage(files, "ScreenSpaceReflections.unitypackage", ExportPackageOptions.Recurse);
    }
}
#endif
