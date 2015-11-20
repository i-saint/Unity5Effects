using UnityEngine;
using System.Collections;


namespace Ist
{
    [ExecuteInEditMode]
    public class BezierPatchControlPoint : MonoBehaviour
    {
        void OnDrawGizmos()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireCube(transform.position, Vector3.one * 0.1f);
        }
    }
}
