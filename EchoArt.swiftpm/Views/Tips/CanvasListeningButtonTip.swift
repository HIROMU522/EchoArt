//
//  CanvasListeningButtonTip.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/10.
//

import SwiftUI
import TipKit

struct CanvasListeningButtonTip: Tip, Identifiable {
    
    var id: String { "CanvasListeningButtonTip" }
    
    var image: Image? {
        Image(systemName: "waveform")
    }
    
    var title: Text {
        Text("Draw & Record with Your Voice")
    }
    
    var message: Text? {
        Text("Toggle voice input to create and capture sound.")
    }
}
