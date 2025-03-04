# Personalization Algorithms

## Ambient Noise Calibration
The ambient noise level is calculated by averaging sound measurements over a period:

$$ambient\_noise = \frac{1}{N} \sum_{i=1}^{N} sound\_level_i$$

Where:
- $N$ is the number of samples (typically 5 seconds)
- $sound\_level_i$ is the sound level measured at time point $i$

## Adaptive Thresholding
The active voice threshold is set dynamically:

$$noise\_gate\_threshold = ambient\_noise - 5.0 \text{ dB}$$
$$active\_voice\_threshold = ambient\_noise + 5.0 \text{ dB}$$

The 5.0 dB offset was determined through user testing to provide the best balance between sensitivity and noise rejection.

## Voice Range Detection Logic
For maximum pitch detection:

$$sustained\_max\_pitch = \begin{cases}
  \text{true}, & \text{if }pitch \geq max\_pitch - 1.0 \text{ Hz for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

For minimum pitch detection:

$$sustained\_min\_pitch = \begin{cases}
  \text{true}, & \text{if }pitch \leq min\_pitch + 1.0 \text{ Hz for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

## Volume Range Detection

$$sustained\_max\_volume = \begin{cases}
  \text{true}, & \text{if }volume \geq threshold \text{ AND } normalized\_diameter \geq 0.95 \text{ for } t \geq 3.0 \text{ seconds} \\
  \text{false}, & \text{otherwise}
\end{cases}$$

Where $normalized\_diameter$ is the ratio of current volume visualization to maximum visualization size.

## Persistence Model
Settings are stored using the following schema:

$$\texttt{UserDefaults.set}(min\_db, \texttt{key} = \texttt{"minDb"})$$
$$\texttt{UserDefaults.set}(max\_db, \texttt{key} = \texttt{"maxDb"})$$
$$\texttt{UserDefaults.set}(min\_pitch, \texttt{key} = \texttt{"minPitch"})$$
$$\texttt{UserDefaults.set}(max\_pitch, \texttt{key} = \texttt{"maxPitch"})$$
$$\texttt{UserDefaults.set}(active\_voice\_threshold, \texttt{key} = \texttt{"activeVoiceThreshold"})$$
