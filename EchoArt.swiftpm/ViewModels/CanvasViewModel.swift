//
//  CanvasViewModel.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import SwiftData

@MainActor
final class CanvasViewModel: ObservableObject {
    private var modelContext: ModelContext?
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func renderImage(lineSegments: [LineSegment]) -> UIImage {
        let screenSize = UIScreen.main.bounds.size
        let isPortrait = screenSize.width < screenSize.height
        
        let rendererSize: CGSize = isPortrait
            ? CGSize(width: screenSize.height, height: screenSize.width)
            : screenSize
        
        let renderer = UIGraphicsImageRenderer(size: rendererSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: rendererSize))
            
            if isPortrait {
                cgContext.translateBy(x: rendererSize.width, y: 0)
                cgContext.rotate(by: CGFloat.pi / 2)
            }
            
            for segment in lineSegments {
                cgContext.setStrokeColor(UIColor(segment.color).cgColor)
                cgContext.setLineWidth(segment.width)
                cgContext.setLineCap(.round)
                cgContext.move(to: segment.start)
                cgContext.addLine(to: segment.end)
                cgContext.strokePath()
            }
        }
    }
    
    func saveArtwork(using audioManager: AudioManager, completion: @escaping (Bool) -> Void) {
        let image = renderImage(lineSegments: audioManager.lineSegments)
        Task {
            let audioData = await audioManager.combineRecordedSegments()
            await MainActor.run {
                self.saveCanvasImage(image: image, audioData: audioData)
                completion(audioData != nil)
            }
        }
    }
    
    func saveCanvasImage(image: UIImage, audioData: Data?) {
        guard let modelContext = modelContext else {
            print("ModelContext is not set.")
            return
        }
        
        if let imageData = image.pngData() {
            let artwork = Artwork(imageData: imageData, audioData: audioData)
            modelContext.insert(artwork)
            try? modelContext.save()
        }
    }
    
    func clearCanvas(for audioManager: AudioManager) {
        audioManager.lineSegments.removeAll()
    }
}

