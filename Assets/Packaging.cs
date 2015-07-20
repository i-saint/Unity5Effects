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
        MakePackage_MosaicField();
        MakePackage_WaterSurface();
        MakePackage_ScreenSpaceBoolean();
        MakePackage_ScreenSpaceReflections();
        MakePackage_ScreenSpaceShadows();
    }


    public static void MakePackage_MosaicField()
    {
        string[] files = new string[]
        {
"Assets/MosaicField",
        };
        AssetDatabase.ExportPackage(files, "MosaicField.unitypackage", ExportPackageOptions.Recurse);
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


    public static void MakePackage_ScreenSpaceBoolean()
    {
        string[] files = new string[]
        {
"Assets/GBufferUtils",
"Assets/ScreenSpaceBoolean",
        };
        AssetDatabase.ExportPackage(files, "ScreenSpaceBoolean.unitypackage", ExportPackageOptions.Recurse);
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

    public static void MakePackage_ScreenSpaceShadows()
    {
        string[] files = new string[]
        {
"Assets/GBufferUtils",
"Assets/ScreenSpaceShadows",
        };
        AssetDatabase.ExportPackage(files, "ScreenSpaceShadows.unitypackage", ExportPackageOptions.Recurse);
    }
}
#endif
