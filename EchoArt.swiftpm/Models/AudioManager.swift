//
//  AudioManager.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import AVFoundation
import Accelerate

struct LineSegment: Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let width: CGFloat
    let color: Color
}

class AudioManager: ObservableObject {
    @Published var isCanvasListening: Bool = false
    @Published var isPersonalizationListening: Bool = false
    @Published private(set) var isAudioEngineRunning: Bool = false
    
    @Published var soundLevel: Float = 0.0
    @Published var currentPitch: Float = 0.0
    @Published var lineSegments: [LineSegment] = []
    
    @Published var audioRecorder: AVAudioRecorder?
    var recordingFileURL: URL?
    var recordedSegmentURLs: [URL] = []
    
    @Published var minDb: Float = -65.0
    @Published var maxDb: Float = -20.0
    @Published var minPitch: Float = 50.0
    @Published var maxPitch: Float = 1000.0
    @Published var activeVoiceThreshold: Float = -45.0
    @Published var smoothingFactor: CGFloat = 0.7
    @Published var noiseGateThreshold: Float = -50.0
    @Published var silenceThreshold: Int = 5
    private var silenceCounter = 0
    
    private var previousRawLevel: Float = -65.0
    private var lastRawPitch: Float = 100.0
    private var smoothedLevel: Float = -65.0
    private var smoothedPitch: Float = 100.0
    
    private var initialHue: Double? = nil
    private var baseColor: Color = .blue
    private var initialColor: Color = .blue
    private var currentColor: Color = .blue
    
    private let movementSpeed: CGFloat = 5.0
    
    private var hannWindow: [Float]?
    
    private let processingQueue = DispatchQueue(label: "com.echoart.processingQueue", qos: .userInitiated)
    
    private let kMinDbKey = "minDb"
    private let kMaxDbKey = "maxDb"
    private let kMinPitchKey = "minPitch"
    private let kMaxPitchKey = "maxPitch"
    private let kActiveVoiceThresholdKey = "activeVoiceThreshold"
    
    private var audioEngine: AVAudioEngine?
    private var currentPoint: CGPoint?
    
    init() {
        loadPersonalizationSettings()
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if !granted {
                    print("Microphone permission has not been granted.")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if !granted {
                    print("Microphone permission has not been granted.")
                }
            }
        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
            print("Successfully set up the audio session.")
        } catch {
            print("Failed to set up the audio session: \(error)")
        }
    }
    

    func toggleListeningFromCanvas() {
        isCanvasListening.toggle()
        if isCanvasListening {
            startRecording()
        } else {
            stopRecording()
        }
        updateAudioEngineRunningState()
    }
    
    func toggleListeningForPersonalization() {
        isPersonalizationListening.toggle()
        updateAudioEngineRunningState()
        
        if !isPersonalizationListening && !isCanvasListening {
            stopEngineInternally()
        }
    }
    
    func updateAudioEngineRunningState() {
        let shouldRun = isCanvasListening || isPersonalizationListening
        if shouldRun && !isAudioEngineRunning {
            startEngineInternally()
        } else if !shouldRun && isAudioEngineRunning {
            stopEngineInternally()
        }
    }
    
    private func startEngineInternally() {
        guard !isAudioEngineRunning else { return }
        
        configureAudioSession()
        audioEngine = AVAudioEngine()
        
        guard let inputNode = audioEngine?.inputNode else { return }
        let format = inputNode.outputFormat(forBus: 0)
        let bufferSize: AVAudioFrameCount = 1024
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processingQueue.async {
                self.processAudio(buffer: buffer)
            }
        }
        
        do {
            try audioEngine?.start()
            isAudioEngineRunning = true
        } catch {
            print("An error occurred while starting the audio engine: \(error)")
        }
    }
    
    private func stopEngineInternally() {
        guard isAudioEngineRunning else { return }
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        isAudioEngineRunning = false
        currentPoint = nil
        audioEngine = nil
    }
    
    private func processAudio(buffer: AVAudioPCMBuffer) {
        let rawLevel = audioPowerLevel(buffer: buffer)
        let pitch = calculatePitch(buffer: buffer)
        
        self.lastRawPitch = pitch
        
        let levelDiff = abs(rawLevel - smoothedLevel)
        let pitchDiff = abs(pitch - smoothedPitch)
        let levelAlpha: Float = levelDiff > 5 ? 0.3 : 0.1
        let pitchAlpha: Float = pitchDiff > 5 ? 0.3 : 0.1
        
        smoothedLevel = levelAlpha * rawLevel + (1 - levelAlpha) * smoothedLevel
        smoothedPitch = pitchAlpha * pitch + (1 - pitchAlpha) * smoothedPitch
        
        DispatchQueue.main.async {
            self.soundLevel = self.smoothedLevel
            self.currentPitch = self.smoothedPitch
            
            if self.smoothedLevel < self.activeVoiceThreshold {
                self.currentPoint = nil
                self.initialHue = nil
                self.previousRawLevel = rawLevel
                return
            }
            
            if self.isCanvasListening {
                self.updateDrawing(level: self.smoothedLevel, pitch: self.smoothedPitch)
            }
            
            self.previousRawLevel = rawLevel
        }
    }
    
    private func updateDrawing(level: Float, pitch: Float) {
        let canvasSize = UIScreen.main.bounds.size
        
        if currentPoint == nil {
            let initialX = mapDecibelToX(level, canvasWidth: canvasSize.width)
            let initialY = mapPitchToY(lastRawPitch, canvasHeight: canvasSize.height)
            currentPoint = CGPoint(x: initialX, y: initialY)
            
            let (color, hue) = mapPitchToColor(lastRawPitch)
            baseColor = color
            initialColor = color
            currentColor = color
            initialHue = hue
        }
        
        guard let start = currentPoint, let hue = initialHue else { return }
        
        let targetX = mapDecibelToX(level, canvasWidth: canvasSize.width)
        let targetY = mapPitchToY(pitch, canvasHeight: canvasSize.height)
        let targetPoint = CGPoint(x: targetX, y: targetY)
        
        let dx = targetPoint.x - start.x
        let dy = targetPoint.y - start.y
        let distance = hypot(dx, dy)
        if distance < 0.1 { return }
        
        let step = movementSpeed
        var newPoint: CGPoint
        if distance <= step {
            newPoint = targetPoint
        } else {
            let ratio = step / distance
            newPoint = CGPoint(x: start.x + dx * ratio, y: start.y + dy * ratio)
        }
        
        newPoint.x = min(max(0, newPoint.x), canvasSize.width)
        newPoint.y = min(max(0, newPoint.y), canvasSize.height)
        
        let delta = hypot(newPoint.x - start.x, newPoint.y - start.y)
        if delta < 1.0 { return }
        
        let width = mapDecibelToWidth(level)
        let opacity = mapDecibelToOpacity(level)
        let adjustedColor = adjustColorBrightness(for: level, hue: hue).opacity(Double(opacity))
        
        let segment = LineSegment(start: start, end: newPoint, width: width, color: adjustedColor)
        lineSegments.append(segment)
        
        currentPoint = newPoint
    }
    
    private func mapDecibelToX(_ db: Float, canvasWidth: CGFloat) -> CGFloat {
        let lowerBound = activeVoiceThreshold
        let upperBound = maxDb
        let clampedDb = max(lowerBound, min(db, upperBound))
        let normalized = (clampedDb - lowerBound) / (upperBound - lowerBound)
        return canvasWidth * CGFloat(normalized)
    }
    
    private func mapDecibelToWidth(_ db: Float) -> CGFloat {
        let lowerBound = activeVoiceThreshold
        let upperBound = maxDb
        let clampedDb = max(lowerBound, min(db, upperBound))
        let normalized = (clampedDb - lowerBound) / (upperBound - lowerBound)
        return 5.0 + (85.0 * CGFloat(normalized))
    }
    
    private func mapDecibelToOpacity(_ db: Float) -> CGFloat {
        let lowerBound = activeVoiceThreshold
        let upperBound = maxDb
        let clampedDb = max(lowerBound, min(db, upperBound))
        let normalized = (clampedDb - lowerBound) / (upperBound - lowerBound)
        return 0.05 + (0.95 * CGFloat(normalized))
    }
    
    private func mapPitchToY(_ pitch: Float, canvasHeight: CGFloat) -> CGFloat {
        let clampedPitch = max(minPitch, min(pitch, maxPitch))
        let logMin = log(minPitch)
        let logMax = log(maxPitch)
        let logP = log(clampedPitch)
        let normalized = (logP - logMin) / (logMax - logMin)
        return canvasHeight * (1.0 - CGFloat(normalized))
    }
    
    private func mapPitchToColor(_ pitch: Float) -> (Color, Double) {
        let clampedPitch = max(minPitch, min(pitch, maxPitch))
        let logMin = log(Double(minPitch))
        let logMax = log(Double(maxPitch))
        let logP = log(Double(clampedPitch))
        let normalized = (logP - logMin) / (logMax - logMin)
        let hue = (1 - normalized) * 0.66
        return (Color(hue: hue, saturation: 1.0, brightness: 1.0), hue)
    }
    
    private func adjustColorBrightness(for level: Float, hue: Double) -> Color {
        let normalized = (level - activeVoiceThreshold) / (maxDb - activeVoiceThreshold)
        let brightness = 1.0 - Double(normalized) * 0.5
        return Color(hue: hue, saturation: 1.0, brightness: brightness)
    }
    
    private func calculatePitch(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        
        if hannWindow == nil || hannWindow?.count != frameLength {
            hannWindow = [Float](repeating: 0.0, count: frameLength)
            vDSP_hann_window(&hannWindow!, vDSP_Length(frameLength), Int32(vDSP_HANN_NORM))
        }
        
        var windowedSamples = [Float](repeating: 0.0, count: frameLength)
        vDSP_vmul(channelData, 1, hannWindow!, 1, &windowedSamples, 1, vDSP_Length(frameLength))
        
        let log2n = UInt(round(log2(Double(frameLength))))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return 0.0 }
        
        var realp = windowedSamples
        var imagp = [Float](repeating: 0.0, count: frameLength)
        var dominantFrequency: Float = 0.0
        
        realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                vDSP_fft_zip(fftSetup, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))
                
                let halfLength = frameLength / 2
                var magnitudes = [Float](repeating: 0.0, count: halfLength)
                magnitudes.withUnsafeMutableBufferPointer { magPtr in
                    vDSP_zvabs(&splitComplex, 1, magPtr.baseAddress!, 1, vDSP_Length(halfLength))
                }
                
                var maxMag: Float = 0.0
                var maxIndex: vDSP_Length = 0
                vDSP_maxvi(magnitudes, 1, &maxMag, &maxIndex, vDSP_Length(halfLength))
                
                let samplingRate = Float(buffer.format.sampleRate)
                dominantFrequency = Float(maxIndex) * samplingRate / Float(frameLength)
            }
        }
        
        vDSP_destroy_fftsetup(fftSetup)
        return dominantFrequency
    }
    
    private func audioPowerLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return minDb }
        let frameLength = vDSP_Length(buffer.frameLength)
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, frameLength)
        let db = 20 * log10(max(rms, 1e-10))
        return max(db, minDb)
    }
    
    func savePersonalizationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(minDb, forKey: kMinDbKey)
        defaults.set(maxDb, forKey: kMaxDbKey)
        defaults.set(minPitch, forKey: kMinPitchKey)
        defaults.set(maxPitch, forKey: kMaxPitchKey)
        defaults.set(activeVoiceThreshold, forKey: kActiveVoiceThresholdKey)
    }
    
    func loadPersonalizationSettings() {
        let defaults = UserDefaults.standard
        if let savedMinDb = defaults.value(forKey: kMinDbKey) as? Float {
            minDb = savedMinDb
        }
        if let savedMaxDb = defaults.value(forKey: kMaxDbKey) as? Float {
            maxDb = savedMaxDb
        }
        if let savedMinPitch = defaults.value(forKey: kMinPitchKey) as? Float {
            minPitch = savedMinPitch
        }
        if let savedMaxPitch = defaults.value(forKey: kMaxPitchKey) as? Float {
            maxPitch = savedMaxPitch
        }
        if let savedActiveVoiceThreshold = defaults.value(forKey: kActiveVoiceThresholdKey) as? Float {
            activeVoiceThreshold = savedActiveVoiceThreshold
        }
    }
    
    var positiveSoundLevel: Float {
        return soundLevel - minDb
    }
    
    func startRecording() {
        configureAudioSession()
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        recordingFileURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder = recorder
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            print("Start recording: \(fileURL.absoluteString)")
        } catch {
            print("An error occurred while starting the recording : \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        if let url = recordingFileURL {
            let fm = FileManager.default
            if let attributes = try? fm.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? NSNumber, fileSize.intValue > 0 {
                recordedSegmentURLs.append(url)
            } else {
                print("The recording file is empty or invalid. It will not be added.")
            }
        }
        print("Recording stopped.")
    }
    
    func combineRecordedSegments() async -> Data? {
        guard !recordedSegmentURLs.isEmpty else {
            return nil
        }
        
        let composition = AVMutableComposition()
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return nil
        }
        
        var currentTime = CMTime.zero
        for url in recordedSegmentURLs {
            let asset = AVURLAsset(url: url)
            do {
                let assetTracks = try await asset.loadTracks(withMediaType: .audio)
                guard let assetTrack = assetTracks.first else {
                    print("The asset has no audio track: \(url)")
                    continue
                }
                let assetDuration: CMTime = try await asset.load(.duration)
                if assetDuration.seconds == 0 {
                    print("Skipping empty asset: \(url)")
                    continue
                }
                let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
                try compositionAudioTrack.insertTimeRange(timeRange, of: assetTrack, at: currentTime)
                currentTime = CMTimeAdd(currentTime, assetDuration)
            } catch {
                print("An error occurred while processing the asset. (\(url)): \(error)")
                continue
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            return nil
        }
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .m4a
        
        do {
            try await exportSession.export(to: exportURL, as: .m4a)
            let data = try Data(contentsOf: exportURL)
            try? FileManager.default.removeItem(at: exportURL)
            for url in recordedSegmentURLs {
                try? FileManager.default.removeItem(at: url)
            }
            recordedSegmentURLs.removeAll()
            return data
        } catch {
            print("Export failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func clearRecordedSegments() {
        for url in recordedSegmentURLs {
            try? FileManager.default.removeItem(at: url)
        }
        recordedSegmentURLs.removeAll()
        if let currentURL = recordingFileURL {
            try? FileManager.default.removeItem(at: currentURL)
            recordingFileURL = nil
        }
        audioRecorder = nil
    }
}

