//
//  PersonalizationView.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import AVFoundation

final class CountdownTimerManager: ObservableObject {
    @Published var currentTime: Date = Date()
    private var timer: Timer?
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = Date()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct PersonalizationView: View {
    @ObservedObject var audioManager: AudioManager
    @Binding var isPresented: Bool
    @StateObject private var viewModel: PersonalizationViewModel
    @State private var showResetAlert: Bool = false

    private let measurementCircleSize: CGFloat = 150

    init(audioManager: AudioManager, isPresented: Binding<Bool>) {
        self.audioManager = audioManager
        self._isPresented = isPresented
        _viewModel = StateObject(wrappedValue: PersonalizationViewModel(audioManager: audioManager))
    }

    var body: some View {
        ZStack {
            VisualEffectBlur(blurStyle: .systemMaterial)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                switch viewModel.step {
                case .intro:
                    introView.transition(.opacity)
                case .quietMeasureIntro:
                    quietMeasureIntroView.transition(.opacity)
                case .quietMeasure:
                    quietMeasureView.transition(.opacity)
                case .volumeMaxIntro:
                    volumeMaxIntroView.transition(.opacity)
                case .volumeMax:
                    volumeMaxView.transition(.opacity)
                case .pitchMaxIntro:
                    pitchMaxIntroView.transition(.opacity)
                case .pitchMax:
                    pitchMaxView.transition(.opacity)
                case .pitchMinIntro:
                    pitchMinIntroView.transition(.opacity)
                case .pitchMin:
                    pitchMinView.transition(.opacity)
                case .done:
                    doneView.transition(.opacity)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.tempMaxPitch = min(max(audioManager.maxPitch, 100), 3000)
            viewModel.tempMinPitch = min(max(audioManager.minPitch, 20), 500)
            viewModel.tempMaxDb = audioManager.maxDb
        }
        .onDisappear {
            audioManager.isPersonalizationListening = false
            audioManager.updateAudioEngineRunningState()
        }
        .onChange(of: viewModel.tempMaxPitch) { _, newVal in
            audioManager.maxPitch = newVal
        }
        .onChange(of: viewModel.tempMinPitch) { _, newVal in
            audioManager.minPitch = newVal
        }
        .onChange(of: viewModel.tempMaxDb) { _, newVal in
            audioManager.maxDb = newVal
        }
        .onChange(of: viewModel.step) { _, newStep in
            viewModel.transitionScheduled = false
            if newStep == .quietMeasure {
                viewModel.quietCount = 0
            }
            viewModel.volumeSustainedStart = nil
            viewModel.pitchSustainedStart = nil
        }
    }
}

extension PersonalizationView {
    private func measurementHeader(title: String, icon: Image? = nil, iconColor: Color? = nil) -> some View {
        VStack(spacing: 8) {
            if let icon = icon, let iconColor = iconColor {
                icon
                    .font(.largeTitle)
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }
}

extension PersonalizationView {
    private var introView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Personalize your voice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Text("For more accurate measurements, please stay as close as possible to the microphone during the test.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
            VStack(spacing: 20) {
                Button(action: {
                    if viewModel.isFirstMicRequest {
                        viewModel.requestMicPermission { granted in
                            if granted {
                                audioManager.toggleListeningForPersonalization()
                                withAnimation {
                                    viewModel.step = .quietMeasureIntro
                                }
                            }
                        }
                        viewModel.isFirstMicRequest = false
                    } else {
                        audioManager.toggleListeningForPersonalization()
                        withAnimation {
                            viewModel.step = .quietMeasureIntro
                        }
                    }
                }) {
                    Text("Continue")
                        .padding()
                        .frame(width: 350)
                        .font(.system(size: 19).bold())
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.accentColor)
                        .cornerRadius(20)
                }
                if !viewModel.isAtDefault {
                    Button(action: {
                        showResetAlert = true
                    }) {
                        Text("Default")
                            .bold()
                            .font(.system(size: 20))
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Reset Settings", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults(isPresented: $isPresented)
            }
        } message: {
            Text("Are you sure you want to reset all settings to default?")
        }
    }

    private var quietMeasureIntroView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("🤫")
                    .font(.system(size: 80))
                Text("Measuring Ambient Noise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("Stay still for a moment to let us understand your surroundings")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.step = .quietMeasure
                }
            }) {
                Text("Continue")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var quietMeasureView: some View {
        VStack(spacing: 20) {
            Spacer()
            measurementHeader(title: "Measuring...")
            QuietProgressView(progress: viewModel.quietProgress)
                .frame(width: measurementCircleSize, height: measurementCircleSize)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !viewModel.isMeasuringQuiet && viewModel.quietCount == 0 {
                viewModel.startQuietMeasurement()
            }
        }
    }

    private var volumeMaxIntroView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Reach Your Loudest Voice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("Speak up to expand the circle and find your volume limit.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.step = .volumeMax
                }
            }) {
                Text("Continue")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var volumeMaxView: some View {
        VStack(spacing: 20) {
            Spacer()
            measurementHeader(title: "Speak louder to enlarge the circle", icon: Image(systemName: "speaker.wave.3.fill"), iconColor: .orange)
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.7), lineWidth: 3)
                let innerDiameter = min(measurementCircleSize, CGFloat(viewModel.volumeDiameter(for: audioManager.soundLevel)) * (measurementCircleSize / 200))
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: innerDiameter, height: innerDiameter)
            }
            .frame(width: measurementCircleSize, height: measurementCircleSize)
            .overlay(
                Group {
                    if let volumeStart = viewModel.volumeSustainedStart {
                        CountdownView(startDate: volumeStart, duration: viewModel.requiredSustainDurationVolume)
                            .id(volumeStart)
                    }
                }
            )
            Text("(Current volume: \(audioManager.positiveSoundLevel, specifier: "%.1f") dB)")
                .foregroundStyle(.secondary)
            VStack {
                Text("Max dB: \(Int(viewModel.tempMaxDb - audioManager.minDb))")
                Slider(value: $viewModel.tempMaxDb, in: (audioManager.minDb)...0, step: 1)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: audioManager.soundLevel) { _, newVolume in
            if viewModel.volumeDiameter(for: newVolume) >= 190,
               audioManager.soundLevel >= audioManager.activeVoiceThreshold {
                if viewModel.volumeSustainedStart == nil {
                    viewModel.volumeSustainedStart = Date()
                } else if Date().timeIntervalSince(viewModel.volumeSustainedStart!) >= viewModel.requiredSustainDurationVolume,
                          !viewModel.transitionScheduled {
                    viewModel.transitionScheduled = true
                    withAnimation {
                        viewModel.step = viewModel.nextStep(for: viewModel.step)
                    }
                    viewModel.volumeSustainedStart = nil
                    viewModel.transitionScheduled = false
                }
            } else {
                viewModel.volumeSustainedStart = nil
            }
        }
    }

    private var pitchMaxIntroView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Find Your Highest Note")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("Try to produce the highest pitch possible and match the red circle. If it's difficult, adjust the slider below to set your maximum pitch range.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.step = .pitchMax
                }
            }) {
                Text("Continue")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pitchMaxView: some View {
        VStack(spacing: 20) {
            Spacer()
            measurementHeader(title: "Increase your pitch to reach red", icon: Image(systemName: "arrow.up.circle.fill"), iconColor: .red)
            ZStack {
                Circle()
                    .fill(audioManager.currentPitch >= viewModel.tempMaxPitch - 1 ? Color.red : viewModel.pitchColor(for: audioManager.currentPitch))
                Circle()
                    .stroke(Color.red, lineWidth: 4)
            }
            .frame(width: measurementCircleSize, height: measurementCircleSize)
            .overlay(
                Group {
                    if let pitchStart = viewModel.pitchSustainedStart {
                        CountdownView(startDate: pitchStart, duration: viewModel.requiredSustainDuration)
                            .id(pitchStart)
                    }
                }
            )
            Text("(Current pitch: \(audioManager.currentPitch, specifier: "%.1f") Hz)")
                .foregroundStyle(.secondary)
            VStack {
                Text("Max pitch: \(Int(viewModel.tempMaxPitch))")
                Slider(value: $viewModel.tempMaxPitch, in: 100...3000, step: 1)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: audioManager.currentPitch) { _, newPitch in
            if newPitch >= viewModel.tempMaxPitch - 1,
               audioManager.soundLevel >= audioManager.activeVoiceThreshold {
                if viewModel.pitchSustainedStart == nil {
                    viewModel.pitchSustainedStart = Date()
                } else if Date().timeIntervalSince(viewModel.pitchSustainedStart!) >= viewModel.requiredSustainDuration,
                          !viewModel.transitionScheduled {
                    viewModel.transitionScheduled = true
                    withAnimation {
                        viewModel.step = viewModel.nextStep(for: viewModel.step)
                    }
                    viewModel.pitchSustainedStart = nil
                    viewModel.transitionScheduled = false
                }
            } else {
                viewModel.pitchSustainedStart = nil
            }
        }
    }

    private var pitchMinIntroView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Find Your Lowest Note")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                Text("Try to produce the lowest pitch possible and match the blue circle. If it's difficult, adjust the slider below to set your minimum pitch range.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.step = .pitchMin
                }
            }) {
                Text("Continue")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pitchMinView: some View {
        VStack(spacing: 20) {
            Spacer()
            measurementHeader(title: "Lower your pitch to reach blue", icon: Image(systemName: "arrow.down.circle.fill"), iconColor: .blue)
            ZStack {
                Circle()
                    .fill(audioManager.currentPitch <= viewModel.tempMinPitch + 1 ? Color.blue : viewModel.pitchColor(for: audioManager.currentPitch))
                Circle()
                    .stroke(Color.blue, lineWidth: 4)
            }
            .frame(width: measurementCircleSize, height: measurementCircleSize)
            .overlay(
                Group {
                    if let pitchStart = viewModel.pitchSustainedStart {
                        CountdownView(startDate: pitchStart, duration: viewModel.requiredSustainDuration)
                            .id(pitchStart)
                    }
                }
            )
            Text("(Current pitch: \(audioManager.currentPitch, specifier: "%.1f") Hz)")
                .foregroundStyle(.secondary)
            VStack {
                Text("Min pitch: \(Int(viewModel.tempMinPitch))")
                Slider(value: $viewModel.tempMinPitch, in: 20...(viewModel.tempMaxPitch - 1), step: 1)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: audioManager.currentPitch) { _, newPitch in
            if newPitch <= viewModel.tempMinPitch + 1,
               audioManager.soundLevel >= audioManager.activeVoiceThreshold {
                if viewModel.pitchSustainedStart == nil {
                    viewModel.pitchSustainedStart = Date()
                } else if Date().timeIntervalSince(viewModel.pitchSustainedStart!) >= viewModel.requiredSustainDuration,
                          !viewModel.transitionScheduled {
                    viewModel.transitionScheduled = true
                    withAnimation {
                        viewModel.step = viewModel.nextStep(for: viewModel.step)
                    }
                    viewModel.pitchSustainedStart = nil
                    viewModel.transitionScheduled = false
                }
            } else {
                viewModel.pitchSustainedStart = nil
            }
        }
    }

    private var doneView: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.green)
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            Text("Your voice is now tuned for a seamless drawing experience.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
            Button(action: {
                audioManager.savePersonalizationSettings()
                audioManager.toggleListeningForPersonalization()
                isPresented = false
            }) {
                Text("Start")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct QuietProgressView: View {
    var progress: Double
    var body: some View {
        ZStack {
            Image(systemName: "mic.fill")
                .font(.system(size: 50))
                .foregroundStyle(.primary)
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.3)
                .foregroundStyle(.primary)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(
                    AngularGradient(gradient: Gradient(colors: [.blue, .purple, .blue]),
                                    center: .center)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct CountdownView: View {
    let startDate: Date
    let duration: TimeInterval
    @StateObject private var timerManager = CountdownTimerManager()
    
    var body: some View {
        Text("\(Int(ceil(remainingTime)))")
            .font(.system(size: 50, weight: .bold))
            .foregroundColor(.primary)
    }
    
    var remainingTime: TimeInterval {
        max(duration - timerManager.currentTime.timeIntervalSince(startDate), 0)
    }
}

