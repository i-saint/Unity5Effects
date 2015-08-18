using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif // UNITY_EDITOR

namespace Ist
{
    public static class PostEffectPresets
    {
#if UNITY_EDITOR
        [MenuItem("Assets/Ist/Post Effect Presets/Fastest")]
        public static void ApplyFastest() { ApplyConfigMenuImpl(Profile.Fastest); }

        [MenuItem("Assets/Ist/Post Effect Presets/Fast")]
        public static void ApplyFast() { ApplyConfigMenuImpl(Profile.Fast); }

        [MenuItem("Assets/Ist/Post Effect Presets/Medium")]
        public static void ApplyMedium() { ApplyConfigMenuImpl(Profile.Medium); }

        [MenuItem("Assets/Ist/Post Effect Presets/High")]
        public static void ApplyHigh() { ApplyConfigMenuImpl(Profile.High); }

        [MenuItem("Assets/Ist/Post Effect Presets/VeryHigh")]
        public static void ApplyVeryHigh() { ApplyConfigMenuImpl(Profile.VeryHigh); }

        public static void ApplyConfigMenuImpl(Profile prof)
        {
            var go = Selection.activeObject as GameObject;
            if(go != null)
            {
                ApplyConfig(go.GetComponent<Camera>(), prof);
            }
        }
#endif // UNITY_EDITOR


        public enum Profile
        {
            Fastest,
            Fast,
            Medium,
            High,
            VeryHigh,
        }

        public static void ApplyConfig(Camera cam, Profile prof)
        {
            if(cam==null) { return; }

            var ssao = cam.GetComponent<UnityStandardAssets.ImageEffects.ScreenSpaceAmbientOcclusion>();
            if(ssao!=null)
            {
                switch(prof)
                {
                    case Profile.Fastest:
                        ssao.enabled = false;
                        break;
                    case Profile.Fast:
                        ssao.enabled = true;
                        ssao.m_SampleCount = UnityStandardAssets.ImageEffects.ScreenSpaceAmbientOcclusion.SSAOSamples.Low;
                        ssao.m_Downsampling = 4;
                        break;
                    case Profile.Medium:
                        ssao.enabled = true;
                        ssao.m_SampleCount = UnityStandardAssets.ImageEffects.ScreenSpaceAmbientOcclusion.SSAOSamples.Low;
                        ssao.m_Downsampling = 2;
                        break;
                    case Profile.High:
                        ssao.enabled = true;
                        ssao.m_SampleCount = UnityStandardAssets.ImageEffects.ScreenSpaceAmbientOcclusion.SSAOSamples.Medium;
                        ssao.m_Downsampling = 2;
                        break;
                    case Profile.VeryHigh:
                        ssao.enabled = true;
                        ssao.m_SampleCount = UnityStandardAssets.ImageEffects.ScreenSpaceAmbientOcclusion.SSAOSamples.High;
                        ssao.m_Downsampling = 2;
                        break;
                }
            }

            var ssr = cam.GetComponent<ScreenSpaceReflections>();
            if (ssr != null)
            {
                switch (prof)
                {
                    case Profile.Fastest:
                    case Profile.Fast:
                        ssr.enabled = false;
                        break;
                    case Profile.Medium:
                        ssr.enabled = true;
                        ssr.m_sample_count = ScreenSpaceReflections.SampleCount.Low;
                        ssr.m_downsampling = 2;
                        break;
                    case Profile.High:
                        ssr.enabled = true;
                        ssr.m_sample_count = ScreenSpaceReflections.SampleCount.Medium;
                        ssr.m_downsampling = 2;
                        break;
                    case Profile.VeryHigh:
                        ssr.enabled = true;
                        ssr.m_sample_count = ScreenSpaceReflections.SampleCount.High;
                        ssr.m_downsampling = 2;
                        break;
                }
            }

            var bloom = cam.GetComponent<UnityStandardAssets.ImageEffects.Bloom>();
            if (bloom != null)
            {
                switch (prof)
                {
                    case Profile.Fastest:
                    case Profile.Fast:
                        bloom.enabled = true;
                        bloom.quality = UnityStandardAssets.ImageEffects.Bloom.BloomQuality.Cheap;
                        break;
                    case Profile.Medium:
                    case Profile.High:
                    case Profile.VeryHigh:
                        bloom.enabled = true;
                        bloom.quality = UnityStandardAssets.ImageEffects.Bloom.BloomQuality.High;
                        break;
                }
            }

            var dof = cam.GetComponent<UnityStandardAssets.ImageEffects.DepthOfField>();
            if (dof != null)
            {
                switch (prof)
                {
                    case Profile.Fastest:
                    case Profile.Fast:
                    case Profile.Medium:
                        dof.enabled = false;
                        break;
                    case Profile.High:
                    case Profile.VeryHigh:
                        dof.enabled = true;
                        break;
                }
            }
        }
    }
}