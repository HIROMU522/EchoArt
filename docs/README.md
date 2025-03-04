# EchoArt - Draw with Your Voice 🎨 🎵

> *"When you utter 'ah,' art is born as your pen."*

EchoArt is an innovative iOS application that transforms voice into digital art, creating a new medium for artistic expression. By analyzing pitch, volume, and duration of your voice in real-time, the app enables anyone to create beautiful, dynamic drawings using only their voice.

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS_18-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![Swift Student Challenge](https://img.shields.io/badge/Swift_Student_Challenge-2025-red.svg)](https://developer.apple.com/swift-student-challenge/)

English | [日本語](README-ja.md)

![EchoArt Demo](https://raw.githubusercontent.com/HIROMU522/EchoArt/main/Resources/demo.png)

## 📱 App Overview

EchoArt analyzes your voice in real-time and transforms it into visual art with the following features:

- **Voice-to-Art Translation**: Your voice becomes a digital paintbrush, creating art through sound
- **Pitch Controls Color**: High pitches create warmer colors (red), while low pitches create cooler colors (blue)
- **Volume Controls Thickness**: Louder sounds create thicker lines, softer sounds create thinner lines
- **Movement through Sustained Sound**: The direction and flow of drawing is controlled by continuous vocalization
- **Audio Recording**: Save both your artwork and the voice that created it
- **Dynamic Gallery**: Browse through your creations and replay the audio that shaped each piece
- **Personalized Voice Calibration**: Customize the app to your vocal range and environment

## 🧩 Architecture & Technical Details

EchoArt employs an advanced signal processing pipeline to transform voice input into visual art in real-time. The diagram below illustrates the core technical workflow:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Audio Capture  │    │ Signal Analysis  │    │ Visual Mapping  │
│                 │───▶│                 │───▶│                 │
│ - AVFoundation  │    │ - FFT Processing │    │ - Pitch to Color│
│ - Buffer Size:  │    │ - Hann Windowing │    │ - Volume to    │
│   1024 samples  │    │ - Peak Detection │    │   Width & X-Pos │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Persistence    │    │  Rendering      │    │ Movement Logic  │
│                 │◀───│                 │◀───│                 │
│ - SwiftData     │    │ - Core Graphics │    │ - Line Segments │
│ - Audio Storage │    │ - UIKit Canvas  │    │ - Interpolation │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

EchoArt follows the MVVM (Model-View-ViewModel) architecture pattern for a clean separation of concerns:

### Application Structure

```
EchoArt/
├── Models/                  # Data models and core functionality
│   ├── Artwork.swift        # SwiftData model for artwork storage
│   └── AudioManager.swift   # Core audio processing and visualization
├── ViewModels/              # Business logic
│   ├── CanvasViewModel.swift     # Canvas rendering logic
│   ├── GalleryViewModel.swift    # Gallery management
│   └── PersonalizationViewModel.swift  # Voice calibration
├── Views/                   # UI components
│   ├── CanvasView.swift     # Drawing interface
│   ├── GalleryView.swift    # Artwork collection
│   ├── PersonalizationView.swift  # Voice calibration UI
│   └── Tips/                # User guidance components
├── Utilities/               # Helper components
│   ├── CoverFlow.swift      # 3D carousel display component
│   └── FloatingButton.swift # Custom floating action button
└── MyApp.swift              # App entry point
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework for intuitive, responsive interfaces
- **SwiftData**: Persistence framework for artwork storage
- **AVFoundation**: Real-time audio capture and processing
- **Accelerate Framework**: Fast Fourier Transform (FFT) for audio frequency analysis
- **TipKit**: User guidance and onboarding experience

### Core Technical Implementation

1. **Real-time Audio Analysis**:
   - Captures audio input through AVFoundation
   - Performs FFT analysis to extract dominant frequencies
   - Calculates volume levels using RMS (root mean square) calculations

2. **Fast Fourier Transform (FFT) Implementation**:

   **FFT Design Decisions**:
   - **Buffer Size Selection (1024 samples)**: Chosen as a compromise between frequency resolution and temporal responsiveness. A larger buffer (e.g., 2048) would provide better frequency resolution but introduce more latency, while a smaller buffer (e.g., 512) would be more responsive but less accurate for lower frequencies.
   
   - **Hann Window Application**: Applied to input samples to reduce spectral leakage. The Hann window function smoothly tapers the signal at the edges of each analysis frame, reducing artifacts that would otherwise occur from analyzing discrete segments of continuous audio.
   
   - **Frequency Calculation**: The relationship between FFT bin index and frequency follows the standard FFT formula, where frequency equals the bin index multiplied by sampling rate divided by FFT size.
   
   - **Memory Management**: Using Swift's pointer-based APIs for buffer handling to ensure optimal performance during real-time processing, avoiding unnecessary memory copies.

   [FFT Implementation Equations](https://github.com/HIROMU522/EchoArt/blob/main/docs/Resources/fft_equations.md)

3. **Audio-Visual Mapping**:

   **Mapping Design Considerations**:
   
   - **Logarithmic Pitch Mapping**: Human perception of pitch follows a logarithmic scale rather than linear. A doubling of frequency (e.g., from 220Hz to 440Hz) is perceived as a one-octave increase. Using logarithmic mapping creates a perceptually uniform color distribution across the human vocal range (typically 80Hz-1100Hz).
   
   - **Color Spectrum Selection**: Uses the HSV color model with hue values ranging from 0.0 (red) to 0.66 (blue), corresponding to high and low pitches respectively. This mapping follows natural associations (high = warm, low = cool) and provides distinct visual feedback.
   
   - **Dynamic Range Compression**: Voice volume (in decibels) is compressed to a usable visual range, ensuring that both quiet and loud voices can create meaningful visual output, making the app accessible to users with different vocal strengths.
   
   - **Position Mapping**: Y-position on canvas is determined by pitch, while X-position is influenced by volume, creating a natural 2D expression space where users can intuitively understand the relationship between their voice and the resulting visuals.

   [FFT Implementation Equations](https://github.com/HIROMU522/EchoArt/blob/main/Resources/mapping_equations.md)

3. **Personalization System**:

   **Personalization Design Rationale**:
   
   - **Ambient Noise Calibration**: Measures the user's environment over a 5-second window to determine the noise floor. This is crucial as different recording environments (quiet room vs. noisy space) require different thresholds for effective voice detection.
   
   - **Adaptive Thresholding**: Sets the active voice threshold dynamically based on ambient noise plus a calibrated offset. This approach ensures the app can distinguish between background noise and intentional vocalization across different environments.
   
   - **Vocal Range Mapping**: 
     - Pitch range calibration measures both the highest and lowest comfortable pitches a user can produce
     - Volume calibration determines maximum comfortable loudness
     - This personalization makes the app accessible to users with different vocal characteristics (e.g., children vs. adults, soprano vs. bass voices)
   
   - **User-Guided Calibration Process**: Interactive step-by-step process with visual feedback provides both accuracy and user engagement
   
   - **Persistence**: Calibration values are stored in UserDefaults, allowing the app to remember each user's vocal profile between sessions

   [FFT Implementation Equations](https://github.com/HIROMU522/EchoArt/blob/main/Resources/personalization_algorithms.md)

5. **Audio-Visual Synchronization**:

   **Synchronization Implementation Strategy**:
   
   - **Segmented Recording Approach**: Audio is recorded in segments aligned with active drawing periods, making it more memory-efficient than continuous recording
   
   - **Composition-Based Joining**: Uses AVMutableComposition to seamlessly join audio segments without audible gaps or clicks
   
   - **Concurrent Processing**: Leverages Swift concurrency (async/await) for non-blocking audio processing
   
   - **Storage Optimization**: Audio data is stored in M4A format using AAC encoding (via AVAssetExportPresetAppleM4A) to balance quality and file size
   
   - **SwiftData Integration**: Combined audio data is stored alongside vector drawing data in a unified SwiftData model, ensuring artwork and audio remain paired throughout the app lifecycle

   [FFT Implementation Equations](https://github.com/HIROMU522/EchoArt/blob/main/Resources/audio_sync_diagram.md)

## 🚀 Features & Screenshots

### Voice Drawing Canvas
![Canvas View](https://raw.githubusercontent.com/HIROMU522/EchoArt/main/Resources/canvas.png)
The main canvas where voice is transformed into visual art in real-time.

### Dynamic Gallery
![Gallery View](https://raw.githubusercontent.com/HIROMU522/EchoArt/main/Resources/gallery.png)
Browse through created artworks with an immersive 3D carousel interface.

### Voice Personalization
![Personalization View](https://raw.githubusercontent.com/HIROMU522/EchoArt/main/Resources/personalization.png)
Customize the app to your unique vocal characteristics and environment.

## 💡 Inspiration & Purpose

EchoArt was inspired by the Japanese word "声色" (kowairo), which combines "voice" (koe) and "color" (iro) to describe the tone of one's voice. This concept, along with the developer's personal experience with hyperhidrosis (a condition causing excessive hand sweating), led to the creation of a tool that enables artistic expression without traditional implements.

The app is designed to be inclusive, offering an alternative creative medium for people with physical limitations that may make traditional drawing challenging. It also creates a unique way for people with speech differences to visualize their voices in vibrant colors, potentially fostering confidence and new forms of self-expression.

## 🔭 Future Developments

- Collaborative drawing features to enable multiple users to create art together
- Cloud synchronization for sharing creations across devices
- Enhanced audio processing for more nuanced visual representations
- Machine learning integration to develop personalized drawing styles
- Cross-platform support for wider accessibility

## 🧑‍💻 Development & Contribution

EchoArt was developed as part of the Swift Student Challenge 2025 submission. The app demonstrates the integration of audio processing, visual rendering, and personalized user experience in a creative iOS application.

## 📝 License

Copyright © 2025 Hiromu Tanaka. All rights reserved.

## 📫 Contact

For inquiries or feedback, please contact:
- Email: [your-email@example.com](mailto:your-email@example.com)
- GitHub: [@HIROMU522](https://github.com/HIROMU522)
- LinkedIn: [Your LinkedIn Profile](https://linkedin.com/in/yourprofile)
