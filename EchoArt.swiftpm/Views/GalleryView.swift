//
//  GalleryView.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import SwiftData
import AVKit
import TipKit

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @Query(sort: [SortDescriptor<Artwork>(\.creationDate, order: .reverse)])
    private var artworks: [Artwork]
    
    @State private var isShowingCanvas = false
    @State private var isShowingVideoView = true
    
    @State private var centeredItemId: Artwork.ID? = nil
    @State private var isScrolling: Bool = false
    
    @State private var showDeleteAlert: Bool = false
    @State private var selectedArtworkForDeletion: Artwork? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var canvasButtonTip = GalleryCanvasButtonTip()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Spacer()
                    if artworks.isEmpty {
                        emptyGalleryMessage
                    } else {
                        horizontalScrollView
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                
                HStack(spacing: 8) {
                    TipView(canvasButtonTip, arrowEdge: .trailing)
                        .fixedSize()
                    Button(action: {
                        isShowingCanvas.toggle()
                    }) {
                        Image(systemName: "theatermask.and.paintbrush")
                            .font(.system(size: 30))
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, geometry.safeAreaInsets.top + 10)
                .padding(.trailing, 20)
            }
            .overlay(
                Text("Gallery")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .allowsHitTesting(false),
                alignment: .topLeading
            )
            .overlay(
                Group {
                    if !isScrolling,
                       let centeredID = centeredItemId,
                       let artworkToDelete = artworks.first(where: { $0.id == centeredID }) {
                        Button(action: {
                            selectedArtworkForDeletion = artworkToDelete
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 30))
                                .padding()
                                .background(.ultraThinMaterial)
                                .foregroundColor(.red)
                                .clipShape(Circle())
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: isScrolling)
                    }
                }
                .padding(.leading, 20)
                .padding(.bottom, 20),
                alignment: .bottomLeading
            )
            .alert("Confirm Deletion", isPresented: $showDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {
                    selectedArtworkForDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    NotificationCenter.default.post(name: Notification.Name("StopAudioPlayback"), object: nil)
                    if let artwork = selectedArtworkForDeletion {
                        viewModel.deleteArtwork(artwork)
                        selectedArtworkForDeletion = nil
                    }
                }
            }, message: {
                Text("Are you sure you want to delete this artwork?")
            })
        }
        .onAppear {
            viewModel.setContext(modelContext)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.overrideUserInterfaceStyle = .light
            }
        }
        .onChange(of: isShowingCanvas) { newValue, _ in
            if newValue {
                NotificationCenter.default.post(name: Notification.Name("StopAudioPlayback"), object: nil)
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: Notification.Name("StopAudioPlayback"), object: nil)
        }
        .sheet(isPresented: $isShowingVideoView) {
            FirstSheet
        }
        .fullScreenCover(isPresented: $isShowingCanvas) {
            CanvasView(isShowingCanvas: $isShowingCanvas)
        }
    }
    
    var FirstSheet: some View {
        VStack {
            Spacer()
            Text("Welcome to EchoArt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 20)
                    .onAppear {
                        player.play()
                    }
            } else {
                Text("Video not found")
                    .font(.title)
                    .foregroundColor(.red)
            }
            Spacer()
            Text("When you utter 'ah,' art is born as your pen.")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .transition(.opacity)
            
            Spacer()
            Button {
                isShowingVideoView = false
                viewModel.pauseVideoPlayer()
            } label: {
                Text("Start Exploring")
                    .padding()
                    .frame(width: 350)
                    .font(.system(size: 19).bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
            Spacer()
        }
        .onAppear {
            viewModel.loadVideoPlayer()
        }
        .onDisappear {
            viewModel.pauseVideoPlayer()
        }
    }
    
    private var emptyGalleryMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            Text("No Echo Art Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Your masterpiece will be showcased here. \nBegin your creative journey now!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var horizontalScrollView: some View {
        let isPad = horizontalSizeClass == .regular
        let itemWidth: CGFloat = isPad ? 1000 : 400
        let scrollHeight: CGFloat = isPad ? 700 : 500
        
        return CoverFlow(
            itemWidth: itemWidth,
            enableReflection: viewModel.enableReflection,
            spacing: viewModel.spacing,
            rotation: viewModel.rotation,
            items: artworks,
            content: { artwork in
                artworkCard(viewModel: viewModel.artworkCard(for: artwork))
                    .overlay(
                        Group {
                            if let first = artworks.first, first.id == artwork.id {
                                TipView(GalleryListeningButtonTip())
                                    .padding(.top, -75)
                            }
                        },
                        alignment: .topTrailing
                    )
            },
            onCenteredItemChange: { id in
                centeredItemId = id
            },
            onScrollStateChange: { scrolling in
                isScrolling = scrolling
                if scrolling {
                    NotificationCenter.default.post(name: Notification.Name("StopAudioPlayback"), object: nil)
                }
            }
        )
        .id(artworks.first?.id)
        .frame(height: scrollHeight)
    }
    
    private func artworkCard(viewModel: ArtworkCardViewModel) -> some View {
        let isPad = horizontalSizeClass == .regular
        let currentArea: CGFloat = isPad ? (500 * 400) : (250 * 200)
        let screenSize = UIScreen.main.bounds.size
        let isPortrait = screenSize.width < screenSize.height
        let canvasAspectRatio: CGFloat = isPortrait
            ? (screenSize.height / screenSize.width)
            : (screenSize.width / screenSize.height)
        
        let newWidth = sqrt(currentArea * canvasAspectRatio)
        let newHeight = sqrt(currentArea / canvasAspectRatio)
        
        return ZStack(alignment: .topTrailing) {
            VStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: newWidth, height: newHeight)
                        .clipped()
                        .cornerRadius(20)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.gradient)
                        .frame(width: newWidth, height: newHeight)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
            
            if let audioData = viewModel.audioData {
                AudioPlaybackButton(audioData: audioData)
                    .padding(10)
            }
        }
    }
}

struct AudioPlaybackButton: View {
    let audioData: Data
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var audioDelegate: AudioPlayerDelegateHandler? = nil

    private class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate {
        var didFinishPlaying: (() -> Void)?
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            didFinishPlaying?()
        }
    }

    var body: some View {
        Group {
            if isPlaying {
                EmptyView()
            } else {
                Button(action: {
                    do {
                        if audioPlayer == nil {
                            audioPlayer = try AVAudioPlayer(data: audioData)
                            let delegate = AudioPlayerDelegateHandler()
                            delegate.didFinishPlaying = {
                                isPlaying = false
                            }
                            audioDelegate = delegate
                            audioPlayer?.delegate = delegate
                        }
                        audioPlayer?.stop()
                        audioPlayer?.currentTime = 0
                        audioPlayer?.prepareToPlay()
                        audioPlayer?.play()
                        isPlaying = true
                    } catch {
                        print("Error initializing audio player: \(error)")
                    }
                }) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor, in: Circle())
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StopAudioPlayback"))) { _ in
            if isPlaying {
                audioPlayer?.stop()
                isPlaying = false
            }
        }
    }
}



