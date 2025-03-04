//
//  CanvasView.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import SwiftData
import TipKit

private struct TitleAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context[VerticalAlignment.top]
    }
}
extension VerticalAlignment {
    static let titleAlignment = VerticalAlignment(TitleAlignment.self)
}

struct CanvasView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var audioManager = AudioManager()
    @StateObject private var viewModel = CanvasViewModel()
    
    @Binding var isShowingCanvas: Bool
    
    @State private var isShowingPersonalization: Bool = false
    
    private static var hasShownRulesSheet: Bool = false
    @State private var isShowingRulesSheet: Bool = {
        return !CanvasView.hasShownRulesSheet
    }()
    
    @State private var activeAlert: ActiveAlert?
    
    enum ActiveAlert: Identifiable {
        case save, exit, saveError(String)
        
        var id: Int {
            switch self {
            case .save: return 1
            case .exit: return 2
            case .saveError: return 3
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CoreGraphicsCanvas(audioManager: audioManager)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        listeningControlButton
                        TipView(CanvasListeningButtonTip(), arrowEdge: .leading)
                            .fixedSize()
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                VStack {
                    Spacer()
                    HStack {
                        clearButton
                        Spacer()
                        if !audioManager.isCanvasListening {
                            HStack(spacing: 8) {
                                floatingButton
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .save:
                    return Alert(
                        title: Text("Save Artwork"),
                        message: Text("Do you want to save the artwork?"),
                        primaryButton: .destructive(Text("Save")) {
                            viewModel.saveArtwork(using: audioManager) { audioSaved in
                                isShowingCanvas = false
                                if !audioSaved {
                                    activeAlert = .saveError("The recording file was not found.")
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .exit:
                    return Alert(
                        title: Text("Unsaved Changes"),
                        message: Text("You have unsaved changes. If you exit now, your artwork will be lost. Are you sure?"),
                        primaryButton: .destructive(Text("Exit Without Saving")) {
                            isShowingCanvas = false
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                case .saveError(let message):
                    return Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .sheet(isPresented: $isShowingPersonalization) {
                PersonalizationView(audioManager: audioManager, isPresented: $isShowingPersonalization)
            }
            .sheet(isPresented: $isShowingRulesSheet, onDismiss: {
                CanvasView.hasShownRulesSheet = true
            }) {
                RulesPersonalizationContainerView(audioManager: audioManager, isPresented: $isShowingRulesSheet)
            }
        }
        .onAppear {
            viewModel.setContext(context)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.overrideUserInterfaceStyle = .light
            }
        }
    }
    
    private var listeningControlButton: some View {
        Button(action: {
            audioManager.toggleListeningFromCanvas()
        }) {
            ZStack {
                if audioManager.isCanvasListening {
                    Image("scribble.variable.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "scribble.variable")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
            }
            .frame(width: 40, height: 40)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
    
    private var clearButton: some View {
        Group {
            if !audioManager.isCanvasListening {
                Button(action: {
                    viewModel.clearCanvas(for: audioManager)
                    audioManager.clearRecordedSegments()
                }) {
                    Image(systemName: "eraser.line.dashed")
                        .font(.system(size: 30))
                        .foregroundColor(audioManager.lineSegments.isEmpty ? Color.gray : .red)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(audioManager.lineSegments.isEmpty)
            }
        }
    }
    
    private var floatingButton: some View {
        FloatingButton(buttonSize: 60) {
            FloatingAction(symbol: "arrowshape.turn.up.backward.fill") {
                if audioManager.lineSegments.isEmpty {
                    isShowingCanvas.toggle()
                } else {
                    activeAlert = .exit
                }
            }
            FloatingAction(symbol: "waveform.and.person.filled") {
                isShowingPersonalization = true
                audioManager.isCanvasListening = false
            }
            FloatingAction(symbol: "square.and.arrow.down") {
                activeAlert = .save
            }
        } label: { isExpanded in
            Image(systemName: "plus")
                .font(.system(size: 30))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                .frame(width: 60, height: 60)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)
                .scaleEffect(isExpanded ? 0.9 : 1)
        }
    }
}

struct CoreGraphicsCanvas: UIViewRepresentable {
    @ObservedObject var audioManager: AudioManager

    func makeUIView(context: Context) -> CanvasUIView {
        return CanvasUIView(audioManager: audioManager)
    }

    func updateUIView(_ uiView: CanvasUIView, context: Context) {
        uiView.setNeedsDisplay()
    }
}

class CanvasUIView: UIView {
    @ObservedObject var audioManager: AudioManager

    init(audioManager: AudioManager) {
        self.audioManager = audioManager
        super.init(frame: .zero)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        guard !audioManager.lineSegments.isEmpty else { return }

        for segment in audioManager.lineSegments {
            context.setStrokeColor(UIColor(segment.color).cgColor)
            context.setLineWidth(segment.width)
            context.setLineCap(.round)
            context.move(to: segment.start)
            context.addLine(to: segment.end)
            context.strokePath()
        }
    }
}

struct RulesPersonalizationContainerView: View {
    @ObservedObject var audioManager: AudioManager
    @Binding var isPresented: Bool
    @State private var navigationPath = NavigationPath()
    @State private var currentRulesPage: Int = 1
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            RulesView(currentRulesPage: $currentRulesPage, onStart: {
                navigationPath.append("personalization")
            }, onLater: {
                isPresented = false
            })
            .navigationDestination(for: String.self) { value in
                if value == "personalization" {
                    PersonalizationView(audioManager: audioManager, isPresented: $isPresented)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

struct RulesView: View {
    @Binding var currentRulesPage: Int
    var onStart: () -> Void
    var onLater: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if currentRulesPage == 1 {
                Text("How to Draw")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    ruleRow(icon: "scribble.variable",
                            title: "Enable Voice Drawing",
                            description: "Turn on your microphone to shape the canvas with your voice and save your sound to revisit in the gallery.")
                    
                    ruleRow(icon: "mic.fill",
                            title: "Loudness Controls Thickness & Horizontal Movement",
                            description: "Your voice controls the line's thickness and horizontal movement the louder, the thicker and farther it moves.")
                    
                    ruleRow(icon: "music.note",
                            title: "Pitch Controls Color & Position",
                            description: "Low pitch draws cool blue lines at the bottom, while high pitch creates vibrant red lines at the top. Raising your pitch moves the line upward.")
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentRulesPage = 2
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
                .padding(.bottom, 40)
            } else {
                Spacer()
                
                Image(systemName: "waveform.and.person.filled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                
                Text("Personalize")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                
                Text("Everyone's voice is unique. \nOptimize your settings to match your sound environment and make drawing feel natural.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    onStart()
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
                Button(action: {
                    onLater()
                }) {
                    Text("Not now")
                        .bold()
                        .font(.system(size: 20))
                        .foregroundColor(.indigo)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func ruleRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .frame(width: 40, alignment: .center)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

