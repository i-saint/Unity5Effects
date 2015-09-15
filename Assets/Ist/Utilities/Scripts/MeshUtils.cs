using System.Linq;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    public static class MeshUtils
    {
        public static Mesh GenerateQuad()
        {
            float l = 1.0f;
            Vector3[] vertices = new Vector3[4] {
                new Vector3( l, l, 0.0f),
                new Vector3(-l, l, 0.0f),
                new Vector3(-l,-l, 0.0f),
                new Vector3( l,-l, 0.0f),
            };
            int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

            Mesh r = new Mesh();
            r.name = "Quad";
            r.vertices = vertices;
            r.triangles = indices;
            return r;
        }

        public static Mesh GenerateSquare()
        {
            float l = 0.5f;
            Vector3[] vertices = new Vector3[4] {
                new Vector3( l, l, 0.0f),
                new Vector3(-l, l, 0.0f),
                new Vector3(-l,-l, 0.0f),
                new Vector3( l,-l, 0.0f),
            };
            int[] indices = new int[6] { 0, 1, 2, 2, 3, 0 };

            Mesh r = new Mesh();
            r.name = "Quad";
            r.vertices = vertices;
            r.triangles = indices;
            return r;
        }

        public static Mesh GenerateLineSquare()
        {
            float l = 0.5f;
            Vector3[] vertices = new Vector3[4] {
                new Vector3( l, l, 0.0f),
                new Vector3(-l, l, 0.0f),
                new Vector3(-l,-l, 0.0f),
                new Vector3( l,-l, 0.0f),
            };
            int[] indices = new int[] { 0, 1, 1, 2, 2, 3, 3, 0 };

            Mesh r = new Mesh();
            r.name = "Line Quad";
            r.vertices = vertices;
            r.SetIndices(indices, MeshTopology.Lines, 0);
            return r;
        }

        public static Mesh GenerateWireCube()
        {
            float l = 0.5f;
            Vector3[] vertices = new Vector3[] {
                new Vector3( l, l, l),
                new Vector3( l, l,-l),
                new Vector3(-l, l,-l),
                new Vector3(-l, l, l),

                new Vector3( l,-l, l),
                new Vector3( l,-l,-l),
                new Vector3(-l,-l,-l),
                new Vector3(-l,-l, l),
            };
            int[] indices = new int[] {
                0,1, 1,2, 2,3, 3,0,
                4,5, 5,6, 6,7, 7,4,
                0,4, 1,5, 2,6, 3,7,
            };

            Mesh r = new Mesh();
            r.name = "Wire Cube";
            r.vertices = vertices;
            r.SetIndices(indices, MeshTopology.Lines, 0);
            return r;
        }

        public static Mesh CreateRevertedMesh(Mesh mesh)
        {
            var ret = new Mesh();
            ret.name = mesh.name + " (Reverse)";
            ret.vertices = mesh.vertices;
            ret.triangles = mesh.triangles.Reverse().ToArray();
            ret.uv = mesh.uv;
            ret.uv2 = mesh.uv2;
            ret.uv3 = mesh.uv3;
            ret.uv4 = mesh.uv4;
            ret.normals = System.Array.ConvertAll(mesh.normals, (a) => { return new Vector3(-a.x, -a.y, -a.z); });
            ret.colors = mesh.colors;
            ret.tangents = mesh.tangents;
            return ret;
        }

        public static Mesh CopyMesh(Mesh mesh)
        {
            var ret = new Mesh();
            ret.name = mesh.name + " (Copy)";
            ret.vertices = mesh.vertices;
            ret.triangles = mesh.triangles;
            ret.uv = mesh.uv;
            ret.uv2 = mesh.uv2;
            ret.uv3 = mesh.uv3;
            ret.uv4 = mesh.uv4;
            ret.normals = mesh.normals;
            ret.colors = mesh.colors;
            ret.tangents = mesh.tangents;
            return ret;
        }

#if UNITY_EDITOR
        [MenuItem("Assets/Ist/Mesh Utils/Copy Mesh")]
        public static void CopyMesh_Menu()
        {
            Mesh mesh = Selection.activeObject as Mesh;
            if (mesh)
            {
                Mesh newmesh = CopyMesh(mesh);
                var path = AssetDatabase.GetAssetPath(mesh);
                var pattern = new Regex(@"Assets/");
                if (!pattern.Match(path).Success)
                {
                    path = "Assets/" + mesh.name;
                }
                AssetDatabase.CreateAsset(newmesh, path + "(Copy).asset");
            }
        }

        [MenuItem("Assets/Ist/Mesh Utils/Create Reverted Mesh")]
        public static void CreateRevertedMesh_Menu()
        {
            Mesh mesh = Selection.activeObject as Mesh;
            if(mesh)
            {
                Mesh newmesh = CreateRevertedMesh(mesh);
                var path = AssetDatabase.GetAssetPath(mesh);
                var pattern = new Regex(@"Assets/");
                if (!pattern.Match(path).Success)
                {
                    path = "Assets/" + mesh.name;
                }
                AssetDatabase.CreateAsset(newmesh, path + "(Reverse).asset");
            }
        }

        [MenuItem("Assets/Ist/Mesh Utils/Generate Square")]
        public static void GenerateSquare_Menu()
        {
            Mesh mesh = GenerateSquare();
            AssetDatabase.CreateAsset(mesh, "Assets/Square.asset");
        }

        [MenuItem("Assets/Ist/Mesh Utils/Generate Line Square")]
        public static void GenerateLineSquare_Menu()
        {
            Mesh mesh = GenerateLineSquare();
            AssetDatabase.CreateAsset(mesh, "Assets/LineSquare.asset");
        }

        [MenuItem("Assets/Ist/Mesh Utils/Generate Wire Cube")]
        public static void GenerateWireCube_Menu()
        {
            Mesh mesh = GenerateWireCube();
            AssetDatabase.CreateAsset(mesh, "Assets/WireCube.asset");
        }

#endif
    }
}