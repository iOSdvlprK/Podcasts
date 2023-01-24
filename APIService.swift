//
//  APIService.swift
//  Podcasts
//
//  Created by joe on 2023/01/04.
//

import Foundation
import Alamofire
import FeedKit

extension Notification.Name {
    static let downloadProgress = Notification.Name("downloadProgress")
    static let downloadComplete = Notification.Name("downloadComplete")
}

class APIService {
    
    typealias EpisodeDownloadCompleteTuple = (fileUrl: String, episodeTitle: String)
    let baseiTunesSearchURL = "https://itunes.apple.com/search"
    
    // singleton
    static let shared = APIService()
    
    func downloadEpisode(episode: Episode) {
        print("Downloading episode using Alamofire at stream url:", episode.streamUrl)
        
        let downloadRequest = DownloadRequest.suggestedDownloadDestination()
        
        AF.download(episode.streamUrl, to: downloadRequest).downloadProgress { progress in
//            print(progress.fractionCompleted)
            // notify DownloadsController about the download progress somehow
            NotificationCenter.default.post(name: .downloadProgress, object: nil, userInfo: ["title": episode.title, "progress": progress.fractionCompleted])
        }.response { resp in
            print(resp.fileURL?.absoluteString ?? "")
            
            // update UserDefaults downloaded episodes with this temp file somehow
            var downloadedEpisodes = UserDefaults.standard.downloadedEpisodes()
            guard let index = downloadedEpisodes.firstIndex(where: { $0.title == episode.title && $0.author == episode.author }) else { return }
            downloadedEpisodes[index].fileUrl = resp.fileURL?.absoluteString ?? ""
            
            do {
                let data = try JSONEncoder().encode(downloadedEpisodes)
                UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodesKey)
            } catch let err {
                print("Failed to encode downloaded episodes with file url update:", err)
            }
            
            let episodeDownloadComplete = EpisodeDownloadCompleteTuple(resp.fileURL?.absoluteString ?? "", episode.title)
            NotificationCenter.default.post(name: .downloadComplete, object: episodeDownloadComplete, userInfo: nil)
        }
    }
    
    func fetchEpisodes(feedUrl: String, completionHandler: @escaping ([Episode]) -> ()) {
        let secureFeedUrl = feedUrl.contains("https") ? feedUrl : feedUrl.replacingOccurrences(of: "http", with: "https")
        
        guard let url = URL(string: secureFeedUrl) else { return }
        
        // async loading
        DispatchQueue.global(qos: .background).async {
            print("Before parser")
            let parser = FeedParser(URL: url)
            print("After parser")
            
            parser.parseAsync { result in
                print("Successfully parse feed:", result.self)
                
                // associative enumeration values
                switch result {
                case .success(let feed):
                    switch feed {
                    case let .rss(feed):
                        let episodes = feed.toEpisodes()
                        completionHandler(episodes)
                    default:
                        print("Found a feed...")
                    }
                case .failure(let error):
                    print("Failed to parse feed:", error)
                }
            }
        }
    }
    
    func fetchPodcasts(searchText: String, completionHandler: @escaping ([Podcast]) -> ()) {
        print("Searching for podcasts...")
        
        let parameters = ["term": searchText, "media": "podcast"]
        
        AF.request(baseiTunesSearchURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { dataResponse in
            if let err = dataResponse.error {
                print("Failed to contact itunes", err)
                return
            }
            guard let data = dataResponse.data else { return }
            do {
//                print(3)
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                print(searchResult.resultCount)
                completionHandler(searchResult.results)
//                self.podcasts = searchResult.results
//                self.tableView.reloadData()
            } catch let decodeErr {
                print("Failed to decode:", decodeErr)
            }
        }
//        print(2)
    }
    
    struct SearchResults: Decodable {
        let resultCount: Int
        let results: [Podcast]
    }
    
}
