//
//  Podcast.swift
//  Podcasts
//
//  Created by joe on 2023/01/03.
//

import Foundation

class Podcast: NSObject, Decodable, NSSecureCoding {
    
    static var supportsSecureCoding: Bool { return true }
    
    func encode(with coder: NSCoder) {
        print("Trying to transform Podcast into Data")
        coder.encode(trackName ?? "", forKey: "trackNameKey")
        coder.encode(artistName ?? "", forKey: "artistNameKey")
        coder.encode(artworkUrl600 ?? "", forKey: "artworkKey")
    }
    
    required init?(coder: NSCoder) {
        print("Trying to turn Data into Podcast")
        self.trackName = coder.decodeObject(forKey: "trackNameKey") as? String
        self.artistName = coder.decodeObject(forKey: "artistNameKey") as? String
        self.artworkUrl600 = coder.decodeObject(forKey: "artworkKey") as? String
    }
    
    var trackName: String?
    var artistName: String?
    var artworkUrl600: String?
    var trackCount: Int?
    var feedUrl: String?
}
