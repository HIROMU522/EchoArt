//
//  GalleryCanvasButtonTip.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/10.
//

import SwiftUI
import TipKit

struct GalleryCanvasButtonTip: Tip {
    
    var image: Image? {
        Image(systemName: "theatermask.and.paintbrush")
    }
    
    var title: Text {
        Text("Start Creating")
    }
    
    var message: Text? {
        Text("Tap here to open the canvas.")
    }
}
