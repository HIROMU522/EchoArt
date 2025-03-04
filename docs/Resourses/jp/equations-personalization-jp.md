# パーソナライゼーションアルゴリズム

## 環境ノイズキャリブレーション
環境ノイズレベルは一定期間の音量測定の平均により計算されます：

$$ambient\_noise = \frac{1}{N} \sum_{i=1}^{N} sound\_level_i$$

ここで：
- $N$ はサンプル数（通常5秒間）
- $sound\_level_i$ は時点 $i$ で測定された音量レベル

## 適応型閾値設定
アクティブな音声閾値は動的に設定されます：

$$noise\_gate\_threshold = ambient\_noise - 5.0 \text{ dB}$$
$$active\_voice\_threshold = ambient\_noise + 5.0 \text{ dB}$$

5.0 dBのオフセットは、感度とノイズ除去のバランスを最適化するためにユーザーテストにより決定されました。

## 音声範囲検出ロジック
最大ピッチ検出の場合：

$$sustained\_max\_pitch = \begin{cases}
  \text{true}, & \text{if }pitch \geq max\_pitch - 1.0 \text{ Hz for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

最小ピッチ検出の場合：

$$sustained\_min\_pitch = \begin{cases}
  \text{true}, & \text{if }pitch \leq min\_pitch + 1.0 \text{ Hz for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

## 音量範囲検出

$$sustained\_max\_volume = \begin{cases}
  \text{true}, & \text{if }volume \geq threshold \text{ AND } normalized\_diameter \geq 0.95 \text{ for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

ここで $normalized\_diameter$ は現在の音量視覚化の最大視覚化サイズに対する比率です。

## 永続化モデル
設定は以下のスキーマを使用して保存されます：

$$\texttt{UserDefaults.set}(min\_db, \texttt{key} = \texttt{"minDb"})$$
$$\texttt{UserDefaults.set}(max\_db, \texttt{key} = \texttt{"maxDb"})$$
$$\texttt{UserDefaults.set}(min\_pitch, \texttt{key} = \texttt{"minPitch"})$$
$$\texttt{UserDefaults.set}(max\_pitch, \texttt{key} = \texttt{"maxPitch"})$$
$$\texttt{UserDefaults.set}(active\_voice\_threshold, \texttt{key} = \texttt{"activeVoiceThreshold"})$$
