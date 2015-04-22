//
// Mecanimのアニメーションデータが、原点で移動しない場合の Rigidbody付きコントローラ
// サンプル
// 2014/03/13 N.Kobyasahi
// 2015/03/11 Revised for Unity5 (only)
//
using UnityEngine;
using System.Collections;

namespace UnityChan
{
// 必要なコンポーネントの列記
    [RequireComponent(typeof(Animator))]
    [RequireComponent(typeof(CapsuleCollider))]
    [RequireComponent(typeof(Rigidbody))]

    public class UnityChanControlScriptWithRgidBody : MonoBehaviour
    {

        public float animSpeed = 1.5f;				// アニメーション再生速度設定
        public float lookSmoother = 3.0f;			// a smoothing setting for camera motion

        // 以下キャラクターコントローラ用パラメタ
        // 前進速度
        public float forwardSpeed = 7.0f;
        // 後退速度
        public float backwardSpeed = 2.0f;
        // 旋回速度
        public float rotateSpeed = 2.0f;
        // ジャンプ威力
        public float jumpPower = 3.0f; 
        // キャラクターコントローラ（カプセルコライダ）の参照

        Transform trans;
        Animator anim;							// キャラにアタッチされるアニメーターへの参照
        
        int idleState = Animator.StringToHash("Standing@loop");
        int jumpState = Animator.StringToHash("JumpToTop");
        int walkState = Animator.StringToHash("Walking@loop");

        public Vector3 m_up;

        // 初期化
        void Start ()
        {
            trans = GetComponent<Transform>();
            anim = GetComponent<Animator> ();
        }
    
    
        // 以下、メイン処理.リジッドボディと絡めるので、FixedUpdate内で処理を行う.
        void FixedUpdate()
        {
            float h = Input.GetAxis("Horizontal");				// 入力デバイスの水平軸をhで定義
            float v = Input.GetAxis("Vertical");				// 入力デバイスの垂直軸をvで定義
            anim.speed = animSpeed;								// Animatorのモーション再生速度に animSpeedを設定する
            AnimatorStateInfo currentBaseState = anim.GetCurrentAnimatorStateInfo(0);	// 参照用のステート変数にBase Layer (0)の現在のステートを設定する


            // 以下、キャラクターの移動処理
            Vector3 velocity = new Vector3(0, 0, v);		// 上下のキー入力からZ軸方向の移動量を取得
            // キャラクターのローカル空間での方向に変換
            velocity = transform.TransformDirection(velocity);
            //以下のvの閾値は、Mecanim側のトランジションと一緒に調整する
            if (v > 0.1)
            {
                velocity *= forwardSpeed;		// 移動速度を掛ける
            }
            else if (v < -0.1)
            {
                velocity *= backwardSpeed;	// 移動速度を掛ける
            }

            if (Input.GetButtonDown("Jump"))
            {	// スペースキーを入力したら

                if (currentBaseState.shortNameHash == idleState ||
                    currentBaseState.shortNameHash == walkState)
                {
                    //ステート遷移中でなかったらジャンプできる
                    if (!anim.IsInTransition(0))
                    {
                        anim.CrossFade(jumpState, 0.0f);
                    }
                }
            }


            // 上下のキー入力でキャラクターを移動させる
            transform.localPosition += velocity * Time.fixedDeltaTime;
            if (!anim.IsInTransition(0))
            {
                if (Mathf.Abs(v) > 0.01)
                {
                    if (currentBaseState.shortNameHash == idleState)
                    {
                        anim.CrossFade(walkState, 0.2f);
                    }
                }
                else if (currentBaseState.shortNameHash == walkState)
                {
                    anim.CrossFade(idleState, 0.2f);
                }
            }

            // 左右のキー入力でキャラクタをY軸で旋回させる
            transform.Rotate(0, h * rotateSpeed, 0);
        }
    }
}