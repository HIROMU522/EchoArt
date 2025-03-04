# Audio Synchronization Process

```
┌─────────────────┐    
│ Voice Input     │    
│                 │    
│ Microphone      │────┐
│ AVAudioRecorder │    │
└─────────────────┘    │
                       │
┌─────────────────┐    │    ┌─────────────────┐    ┌─────────────────┐
│ Audio Segments  │    │    │ Composition     │    │ Exported Audio  │
│                 │    │    │                 │    │                 │
│ Segment 1       │◀───┘    │ AVMutable-      │    │ M4A File        │
│ Segment 2       │────────▶│ Composition     │───▶│ AAC Encoding    │
│ Segment 3       │         │ Time Alignment  │    │ 44.1kHz, Mono   │
└─────────────────┘         └─────────────────┘    └─────────────────┘
                                                            │
┌─────────────────┐                             ┌───────────▼─────────┐
│ Drawing Data    │                             │ Swift Data Storage  │
│                 │                             │                     │
│ Line Segments   │                             │ Model:              │
│ Color Values    │─────────────────────────────▶ Artwork             │
│ Thickness Data  │                             │ - imageData         │
└─────────────────┘                             │ - audioData         │
                                                └─────────────────────┘
                                                            │
                                               ┌────────────▼────────────┐
                                               │ Gallery Playback        │
                                               │                         │
                                               │ AVAudioPlayer           │
                                               │ Synchronized Display    │
                                               └─────────────────────────┘
```

The diagram above illustrates the complete audio recording, processing, and synchronization pipeline in EchoArt:

1. **Audio Capture**: Voice input is captured in segments during active drawing periods
2. **Segment Management**: Audio segments are stored temporarily as separate files
3. **Composition**: AVMutableComposition aligns segments into a continuous timeline
4. **Export Processing**: The composition is exported as a single M4A file with AAC encoding
5. **Unified Storage**: Both visual artwork and audio recording are stored together in SwiftData
6. **Synchronized Playback**: In the gallery, audio can be played back while viewing the artwork

This approach ensures:
- Memory efficiency (only recording during active drawing)
- Seamless audio continuity (no audible gaps between segments)
- Optimized storage (compact file format with good audio quality)
- Unified data management (artwork and audio remain paired)
