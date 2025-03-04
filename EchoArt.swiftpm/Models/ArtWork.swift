//
//  ArtWork.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftData
import Foundation

@Model
class Artwork: Identifiable {
    var imageData: Data
    var audioData: Data?  
    var creationDate: Date
    
    init(imageData: Data, audioData: Data? = nil, creationDate: Date = Date()) {
        self.imageData = imageData
        self.audioData = audioData
        self.creationDate = creationDate
    }
}

