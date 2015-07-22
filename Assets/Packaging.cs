#if UNITY_EDITOR
using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;


public class Packaging
{
    [MenuItem("Assets/IstEffects/MakePackages")]
    public static void MakePackages()
    {
        string[] files = new string[]
        {
"Assets/IstEffects",
        };
        AssetDatabase.ExportPackage(files, "IstEffects.unitypackage", ExportPackageOptions.Recurse);
    }

}
#endif
