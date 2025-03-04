//
//  PersonalizationViewModel.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import AVFoundation

@MainActor
final class PersonalizationViewModel: ObservableObject {
    enum PersonalizationStep {
        case intro
        case quietMeasureIntro
        case quietMeasure
        case volumeMaxIntro
        case volumeMax
        case pitchMaxIntro
        case pitchMax
        case pitchMinIntro
        case pitchMin
        case done
    }
    
    @Published var step: PersonalizationStep = .intro
    @Published var isFirstMicRequest: Bool = true
    @Published var isMeasuringQuiet: Bool = false
    @Published var quietSeconds: Int = 5
    @Published var quietCount: Int = 0
    @Published var measuredNoise: Float = -100
    
    @Published var tempMaxPitch: Float = 1000
    @Published var tempMinPitch: Float = 50
    @Published var tempMaxDb: Float = -20
    
    @Published var pitchSustainedStart: Date? = nil
    @Published var volumeSustainedStart: Date? = nil
    
    let requiredSustainDuration: TimeInterval = 3.0
    let requiredSustainDurationVolume: TimeInterval = 3.0
    
    var transitionScheduled: Bool = false
    
    private var quietTimer: Timer? = nil
    private var noiseSum: Float = 0.0
    
    let audioManager: AudioManager
    
    var quietProgress: Double {
        return Double(quietCount) / Double(quietSeconds)
    }
    
    var defaultMaxPitch: Float { 1000 }
    var defaultMinPitch: Float { 50 }
    var defaultMaxDb: Float { -20 }
    var defaultMeasuredNoise: Float { -100 }
    
    var isAtDefault: Bool {
        return tempMaxPitch == defaultMaxPitch &&
               tempMinPitch == defaultMinPitch &&
               tempMaxDb == defaultMaxDb
    }
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        self.tempMaxPitch = audioManager.maxPitch
        self.tempMinPitch = audioManager.minPitch
        self.tempMaxDb = audioManager.maxDb
    }

    func requestMicPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    func startQuietMeasurement() {
        isMeasuringQuiet = true
        quietCount = 0
        noiseSum = 0.0
        
        quietTimer?.invalidate()
        quietTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleQuietTimer(_:)), userInfo: nil, repeats: true)
    }
    
    @objc private func handleQuietTimer(_ timer: Timer) {
        noiseSum += audioManager.soundLevel
        quietCount += 1
        
        if quietCount >= quietSeconds {
            timer.invalidate()
            let averageNoise = noiseSum / Float(quietSeconds)
            measuredNoise = averageNoise
            audioManager.noiseGateThreshold = averageNoise - 5
            let offset: Float = 5.0
            audioManager.activeVoiceThreshold = averageNoise + offset
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.step = self.nextStep(for: self.step)
                }
            }
        }
    }
    
    func volumeDiameter(for level: Float) -> CGFloat {
        let clamped = max(audioManager.minDb, min(level, audioManager.maxDb))
        let range = audioManager.maxDb - audioManager.minDb
        let normalized = (clamped - audioManager.minDb) / range
        return 200 * CGFloat(normalized)
    }
    
    func pitchColor(for pitch: Float) -> Color {
        let clamped = max(audioManager.minPitch, min(pitch, audioManager.maxPitch))
        let logMin = log(audioManager.minPitch)
        let logMax = log(audioManager.maxPitch)
        let logP = log(clamped)
        let normalized = (logP - logMin) / (logMax - logMin)
        let hue = (1 - Double(normalized)) * 0.66
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
    
    func nextStep(for currentStep: PersonalizationStep) -> PersonalizationStep {
        switch currentStep {
        case .quietMeasure:
            return .volumeMaxIntro
        case .volumeMax:
            return .pitchMaxIntro
        case .pitchMax:
            return .pitchMinIntro
        case .pitchMin:
            return .done
        default:
            return currentStep
        }
    }
    
    func resetToDefaults(isPresented: Binding<Bool>) {
        tempMaxPitch = defaultMaxPitch
        tempMinPitch = defaultMinPitch
        tempMaxDb = defaultMaxDb
        measuredNoise = defaultMeasuredNoise
        
        audioManager.maxPitch = defaultMaxPitch
        audioManager.minPitch = defaultMinPitch
        audioManager.maxDb = defaultMaxDb
        
        audioManager.activeVoiceThreshold = -45.0
        
        audioManager.savePersonalizationSettings()
        
        audioManager.toggleListeningForPersonalization()
        isPresented.wrappedValue = false
    }
    
    deinit {
        quietTimer?.invalidate()
    }
}


