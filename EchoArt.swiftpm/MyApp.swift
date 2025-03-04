//
//  MyApp.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct EchoArtApp: App {
    init() {
            try? Tips.configure()
        }
    var body: some Scene {
        WindowGroup {
            GalleryView()
                .modelContainer(for: Artwork.self)
        }
    }
}


