//
//  GalleryListeningButtonTip.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/21.
//

import SwiftUI
import TipKit

struct GalleryListeningButtonTip: Tip, Identifiable {
    var id: String { "GalleryListeningButtonTip" }
    
    var image: Image? {
        Image(systemName: "music.note")
    }
    
    var title: Text {
        Text("Listen to the Artwork's Sound")
    }
    
    var message: Text? {
        Text("Tap to play the sound of this artwork.")
    }
}
