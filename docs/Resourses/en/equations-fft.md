# FFT Implementation Equations

## Hann Window Function
The Hann window function used to reduce spectral leakage is defined as:

$$w(n) = 0.5 \times \left(1 - \cos\left(2\pi \frac{n}{N-1}\right)\right)$$

Where:
- $w(n)$ is the window value at sample $n$
- $N$ is the window length (1024 in our implementation)

## Frequency Calculation
The relationship between FFT bin index and frequency:

$$f = \frac{k \times f_s}{N}$$

Where:
- $f$ is the frequency in Hz
- $k$ is the bin index
- $f_s$ is the sampling rate (44.1kHz)
- $N$ is the FFT size (1024)

This gives frequency resolution of approximately 43Hz per bin, sufficient for voice analysis.

## Peak Frequency Detection
After the FFT computation, the magnitude of each bin is calculated:

$$X_{mag}[k] = \sqrt{X_{real}[k]^2 + X_{imag}[k]^2}$$

The dominant frequency corresponds to the bin with the maximum magnitude:

$$k_{max} = \arg\max_k X_{mag}[k]$$
$$f_{dominant} = \frac{k_{max} \times f_s}{N}$$

## Buffer Size Considerations
The choice of buffer size affects:

Time resolution: $\Delta t = \frac{N}{f_s}$

Frequency resolution: $\Delta f = \frac{f_s}{N}$

For N = 1024 and $f_s$ = 44.1kHz:
- Time resolution: ~23ms
- Frequency resolution: ~43Hz
