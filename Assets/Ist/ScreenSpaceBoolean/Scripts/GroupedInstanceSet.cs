using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    public class GroupedInstanceSet<T> : InstanceSet<T> where T : GroupedInstanceSet<T>
    {
        #region static
        static private Dictionary<int, HashSet<T>> s_groups;
        static private bool s_dirty = true;

        static public Dictionary<int, HashSet<T>> GetGroups()
        {
            if (s_groups == null) { s_groups = new Dictionary<int, HashSet<T>>(); }
            if (s_dirty)
            {
                s_dirty = false;

                foreach (var g in s_groups)
                {
                    g.Value.Clear();
                }

                var instances = GetInstances();
                foreach (var instance in instances)
                {
                    for (int j = 0; j < instance.m_groups.Length; ++j)
                    {
                        int k = instance.m_groups[j];
                        if (!s_groups.ContainsKey(k))
                        {
                            s_groups.Add(k, new HashSet<T>());
                        }
                        s_groups[k].Add(instance);
                    }
                }
            }
            return s_groups;
        }
        #endregion

        public int[] m_groups = new int[] { 0 };


        public int[] groups
        {
            get { return m_groups; }
            set { m_groups = value; s_dirty = true; }
        }

#if UNITY_EDITOR
        public virtual void OnValidate()
        {
            s_dirty = true;
        }
#endif

        public override void OnEnable()
        {
            base.OnEnable();
            s_dirty = true;
        }

        public override void OnDisable()
        {
            base.OnDisable();
            s_dirty = true;
        }
    }
}