//
//  UserDefaults.swift
//  Podcasts
//
//  Created by joe on 2023/01/22.
//

import Foundation

extension UserDefaults {
    static let favoritedPodcastKey = "favoritedPodcastKey"
    static let downloadedEpisodesKey = "downloadedEpisodesKey"
    
    func deleteEpisode(episode: Episode) {
        let savedEpisodes = downloadedEpisodes()
        let filteredEpisodes = savedEpisodes.filter { e -> Bool in
            // we should use episode.collectionId to be safer with deletes
//            return e.title != episode.title && e.description != episode.description && e.pubDate != episode.pubDate
            return e != episode
        }
        
        do {
            let data = try JSONEncoder().encode(filteredEpisodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodesKey)
        } catch let encodeErr {
            print("Failed to encode episode:", encodeErr)
        }
    }
    
    func downloadEpisode(episode: Episode) {
        do {
            var downloadedEpisodes = downloadedEpisodes()
//            downloadedEpisodes.append(episode)
            downloadedEpisodes.insert(episode, at: 0)
            let data = try JSONEncoder().encode(downloadedEpisodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodesKey)
        } catch let encodeErr {
            print("Failed to encode episode:", encodeErr)
        }
    }
    
    func downloadedEpisodes() -> [Episode] {
//        let episodesData = UserDefaults.standard.data(forKey: UserDefaults.downloadedEpisodesKey)
        guard let episodesData = data(forKey: UserDefaults.downloadedEpisodesKey) else { return [] }
        do {
            let episodes = try JSONDecoder().decode([Episode].self, from: episodesData)
            return episodes
        } catch let decodeErr {
            print("Failed to decode episode:", decodeErr)
        }
        return []
    }
    
    func savedPodcasts() -> [Podcast] {
        guard let savedPodcastsData = UserDefaults.standard.data(forKey: UserDefaults.favoritedPodcastKey) else { return [] }
        guard let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: savedPodcastsData) as? [Podcast] else { return [] }
        return savedPodcasts
    }
}
