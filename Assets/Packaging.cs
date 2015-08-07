#if UNITY_EDITOR
using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;


public class Packaging
{
    [MenuItem("Assets/Ist/MakePackages")]
    public static void MakePackages()
    {
        string[] files = new string[]
        {
"Assets/Ist",
"Assets/smcs.rsp",
        };
        AssetDatabase.ExportPackage(files, "IstEffects.unitypackage", ExportPackageOptions.Recurse);
    }

}
#endif
