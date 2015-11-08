using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Ist
{
    public class MPGPColliderBase : MonoBehaviour
    {
        static List<MPGPColliderBase> s_instances;
    
        public static List<MPGPColliderBase> GetInstances()
        {
            if (s_instances == null) s_instances = new List<MPGPColliderBase>();
            return s_instances;
        }
    
        public static void UpdateAll()
        {
            int i = 0;
            GetInstances().ForEach((v) => {
                v.m_id = i++;
                v.ActualUpdate();
            });
        }
    
    
        public MPGPWorld[] m_targets;
        public bool m_send_collision = true;
        public bool m_receive_collision = false;
        protected int m_id;
        protected Transform m_trans;
    
        protected void EachTargets(System.Action<MPGPWorld> a)
        {
            if (m_targets.Length == 0) { MPGPWorld.GetInstances().ForEach(a); }
            else { foreach (var t in m_targets) { a(t); } }
        }
    
        void OnEnable()
        {
            GetInstances().Add(this);
            m_trans = GetComponent<Transform>();
        }
    
        void OnDisable()
        {
            GetInstances().Remove(this);
        }
    
        public virtual void ActualUpdate() { }
    }
    
}
