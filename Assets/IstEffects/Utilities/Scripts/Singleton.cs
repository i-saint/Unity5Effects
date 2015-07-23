using UnityEngine;

namespace Ist
{
    public class Singleton<T> : MonoBehaviour where T : MonoBehaviour
    {
        private static T s_instance;

        public static T GetInstance()
        {
            if (s_instance == null)
            {
                s_instance = FindObjectOfType<T>();

                if (FindObjectsOfType<T>().Length > 1)
                {
                    Debug.LogError("[Singleton] Something went really wrong " +
                        " - there should never be more than 1 singleton!" +
                        " Reopening the scene might fix it.");
                    return s_instance;
                }

                if (s_instance == null)
                {
                    GameObject singleton = new GameObject();
                    s_instance = singleton.AddComponent<T>();
                    singleton.name = "[Singleton] " + typeof(T).ToString();

                    DontDestroyOnLoad(singleton);

                    Debug.Log("[Singleton] An instance of " + typeof(T) +
                        " is needed in the scene, so '" + singleton +
                        "' was created with DontDestroyOnLoad.");
                }
                else
                {
                    Debug.Log("[Singleton] Using instance already created: " +
                        s_instance.gameObject.name);
                }
            }

            return s_instance;
        }

        public virtual void OnDestroy()
        {
            if (s_instance == this)
            {
                s_instance = null;
            }
        }
    }
}