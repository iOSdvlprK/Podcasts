//
//  Podcast.swift
//  Podcasts
//
//  Created by joe on 2023/01/03.
//

import Foundation

struct Podcast: Decodable {
    let trackName: String?
    let artistName: String?
    let artworkUrl600: String?
    let trackCount: Int?
    let feedUrl: String?
}
