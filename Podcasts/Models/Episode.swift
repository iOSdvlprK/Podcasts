//
//  Episode.swift
//  Podcasts
//
//  Created by joe on 2023/01/10.
//

import Foundation
import FeedKit

struct Episode: Equatable, Codable {
    let title: String
    let pubDate: Date
    let description: String
    let author: String
    var imageUrl: String?
    var streamUrl: String
    var fileUrl: String?
    
    init(feedItem: RSSFeedItem) {
        self.title = feedItem.title ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? ""
        self.author = feedItem.iTunes?.iTunesAuthor ?? ""
        self.imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
    }
    
    static func ==(lhs: Episode, rhs: Episode) -> Bool {
        return lhs.title == rhs.title && lhs.pubDate == rhs.pubDate && lhs.description == rhs.description && lhs.author == rhs.author && lhs.streamUrl == rhs.streamUrl
    }
}
