# 音声-視覚マッピング方程式

## 対数的ピッチマッピング
ピッチの人間の知覚は対数スケールに従うため、以下の式でピッチを正規化します：

$$normalized\_pitch = \frac{\log(pitch) - \log(min\_pitch)}{\log(max\_pitch) - \log(min\_pitch)}$$

## ピッチから色相への計算
HSVカラーモデルにおける色相値は以下により決定されます：

$$hue = (1 - normalized\_pitch) \times 0.66$$

ここで：
- 高いピッチは0.0（赤）に近い値を生成
- 低いピッチは0.66（青）に近い値を生成

## 音量から線幅へのマッピング
線の太さは以下のように計算されます：

$$normalized\_volume = \frac{dB - threshold}{max\_dB - threshold}$$
$$width = min\_width + (max\_width - min\_width) \times normalized\_volume$$

ここで：
- $dB$ は現在のデシベル単位の音量レベル
- $threshold$ は音声活性化閾値
- $max\_dB$ はキャリブレーションされた最大音量
- $min\_width$ は5.0ピクセル
- $max\_width$ は90.0ピクセル

## 位置マッピング
キャンバス上のY位置は以下により決定されます：

$$normalized\_pitch\_log = \frac{\log(pitch) - \log(min\_pitch)}{\log(max\_pitch) - \log(min\_pitch)}$$
$$y\_position = canvas\_height \times (1.0 - normalized\_pitch\_log)$$

X位置は音量の影響を受けます：

$$normalized\_volume = \frac{dB - threshold}{max\_dB - threshold}$$
$$x\_position = canvas\_width \times normalized\_volume$$

## 色の不透明度マッピング
色の不透明度も音量の影響を受けます：

$$opacity = min\_opacity + (max\_opacity - min\_opacity) \times normalized\_volume$$

ここで：
- $min\_opacity$ は0.05
- $max\_opacity$ は1.0
