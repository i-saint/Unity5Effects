using UnityEngine;
using System.Collections;

namespace UnityChan
{
	[ExecuteInEditMode]
	public class SplashScreen : MonoBehaviour
	{
		void NextLevel ()
		{
			Application.LoadLevel (Application.loadedLevel + 1);
		}
	}
}