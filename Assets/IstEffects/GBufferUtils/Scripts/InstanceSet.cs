using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{

    public abstract class InstanceSet<T> : MonoBehaviour where T : MonoBehaviour
    {
        #region static
        static HashSet<T> s_instances;

        static public HashSet<T> GetInstances()
        {
            if (s_instances == null) { s_instances = new HashSet<T>(); }
            return s_instances;
        }
        #endregion


        public virtual void OnEnable()
        {
            GetInstances().Add((T)(System.Object)this);
        }

        public virtual void OnDisable()
        {
            GetInstances().Remove((T)(System.Object)this);

        }
    }

}
