//
//  GalleryViewModel.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import AVKit
import SwiftData

@MainActor
class GalleryViewModel: ObservableObject {
    @Published var spacing: CGFloat = 40
    @Published var rotation: CGFloat = 55
    @Published var enableReflection: Bool = true
    @Published var player: AVPlayer? = nil
    
    private var modelContext: ModelContext?
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func deleteArtwork(_ artwork: Artwork) {
        modelContext?.delete(artwork)
    }
    
    func artworkCard(for artwork: Artwork) -> ArtworkCardViewModel {
        let image = UIImage(data: artwork.imageData)
        return ArtworkCardViewModel(image: image, audioData: artwork.audioData)
    }
    
    func loadVideoPlayer() {
        if let fileURL = Bundle.module.url(forResource: "introduction", withExtension: "mp4") {
            self.player = AVPlayer(url: fileURL)
        }
    }
    
    func pauseVideoPlayer() {
        player?.pause()
    }
}

struct ArtworkCardViewModel {
    let image: UIImage?
    let audioData: Data?
}

