# Audio-Visual Mapping Equations

## Logarithmic Pitch Mapping
Human perception of pitch follows a logarithmic scale, so we normalize pitch using:

$$normalized\_pitch = \frac{\log(pitch) - \log(min\_pitch)}{\log(max\_pitch) - \log(min\_pitch)}$$

## Hue Calculation from Pitch
The hue value in the HSV color model is determined by:

$$hue = (1 - normalized\_pitch) \times 0.66$$

Where:
- High pitch produces values closer to 0.0 (red)
- Low pitch produces values closer to 0.66 (blue)

## Volume to Width Mapping
Line thickness is calculated using:

$$normalized\_volume = \frac{dB - threshold}{max\_dB - threshold}$$
$$width = min\_width + (max\_width - min\_width) \times normalized\_volume$$

Where:
- $dB$ is the current sound level in decibels
- $threshold$ is the voice activation threshold
- $max\_dB$ is the calibrated maximum volume
- $min\_width$ is 5.0 pixels
- $max\_width$ is 90.0 pixels

## Position Mapping
Y-position on canvas is determined by:

$$normalized\_pitch\_log = \frac{\log(pitch) - \log(min\_pitch)}{\log(max\_pitch) - \log(min\_pitch)}$$
$$y\_position = canvas\_height \times (1.0 - normalized\_pitch\_log)$$

X-position is influenced by volume:

$$normalized\_volume = \frac{dB - threshold}{max\_dB - threshold}$$
$$x\_position = canvas\_width \times normalized\_volume$$

## Color Opacity Mapping
Color opacity is also influenced by volume:

$$opacity = min\_opacity + (max\_opacity - min\_opacity) \times normalized\_volume$$

Where:
- $min\_opacity$ is 0.05
- $max\_opacity$ is 1.0
