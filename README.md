Unity5 Effects
============

Unity5 用エフェクト置き場。  
こちらのパッケージをインポートすれば大体そのまま使えます：[IstEffects.unitypackage](https://github.com/i-saint/Unity5Effects/raw/master/Packages/IstEffects.unitypackage)  
多くはレンダリングパスが deferred であることを前提としています。また、カメラが HDR モードである方がより望ましい結果になります。

## Temporal Screen Space Reflections
![alt text](doc/ScreenSpaceReflections.jpg)  
スクリーンスペース反射です。  
kode80 氏が[似たようなもの](https://github.com/kode80/kode80SSR)を公開していますが、そちらとはアルゴリズムが違い、
若干残像が残ってしまう欠点があるものの、圧倒的に高速でクオリティも引けを取りません。  
実装の詳細に興味があれば[こちらの記事](http://i-saint.hatenablog.com/entry/2014/12/05/174706)もどうぞ。
また、上記スクリーンショットの背景は[こちら](https://github.com/i-saint/RaymarchingOnUnity5)の Raymarcher によるものです。

## Screen Space Shadows
![alt text](doc/ScreenSpaceShadows.gif)  
G-Buffer をレイマーチすることで影を出せるライトです。点光源の他に線光源も扱えるようになっています。  
ライティング処理の大部分は<a href="http://blogs.unity3d.com/2015/02/06/extending-unity-5-rendering-pipeline-command-buffers/">公式の CommandBuffer のサンプルプロジェクト</a>から借用しています。

## Screen Space Boolean
![alt text](doc/Boolean.gif)  
G-Buffer 加工によるスクリーンスペースブーリアン演算です。  
重い、影を正しく処理できない、複雑な立体交差で破綻する、などいくつか問題はありますが、見た目に結構インパクトがある効果は得られます。  
実装の詳細に興味があれば[こちらの記事 (の下の方)](http://i-saint.hatenablog.com/entry/2014/07/25/001608)もどうぞ。

## Rim Light
![alt text](doc/RimLight.jpg)  
法線と カメラ -> ピクセル位置 の角度が浅い部分を明るくするアレです。

## Water Surface & Caustics Field
![alt text](doc/WaterSurface.jpg)  
水面とコースティクスです。  
水面は G-Buffer をレイマーチすることで屈折をエミュレートしています。コースティクスは 3 次元ノイズで明るくしてそれっぽく見せかけています。


## Light Particle
![alt text](doc/LightParticle.jpg)  
一粒一粒を Point Light として扱うパーティクルレンダラ。MassParticle の拡張。


## Procedural Modeling
![alt text](doc/ProceduralModeling.jpg)  
Mesh の表面を開始点としてレイマーチ (sphere tracing) することで、オブジェクトスペースで distance function をレンダリングする代物。
上の画像は Unity ちゃん以外の背景オブジェクトは全て Cube をピクセルシェーダで加工したものです。

## Metaball
![alt text](doc/Metaball.gif)  
レイマーチによる Metaball。完全に GPU で完結するので、MC 法などでメッシュを生成するよりはずっと高速なはずです。  
実装には Media Molecule の方が発表した soft_min() 関数を拝借しています。([詳細](http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015-sml.pdf)。この資料プロシージャルモデリングの類に関する情報の宝庫なのでおすすめです) また、D3D11 世代の機能 (StructuredBuffer) を使っているのでやや環境を選びます。  

## Temporal SSAO
![alt text](doc/SSAO.jpg)  
dangerous samples を考慮することで残像対策を入れた temporal な SSAO です。  
動いてる箇所のノイズが目立ち、ちょっと実用に耐えるとは言い難いクオリティですが、動きが少ないシーンに限れば標準 SSAO の倍くらいの速度で近いクオリティの絵が出せます。
状況によっては役立つこともあるかもしれません。  
[こちら](http://bitsquid.blogspot.jp/2015/09/temporal-reprojection-and-sao.html) をヒントに実装しました、が、元記事の方がずっと高度な実装になっています。いずれ元記事で言及されている SSAO の発展形にも手を出してみたいところです。

### Mosaic Field
![alt text](doc/mosaic.gif)  
指定オブジェクトをモザイク領域化するシェーダ。

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
