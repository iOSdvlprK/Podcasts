//
//  APIService.swift
//  Podcasts
//
//  Created by joe on 2023/01/04.
//

import Foundation
import Alamofire
import FeedKit

class APIService {
    
    let baseiTunesSearchURL = "https://itunes.apple.com/search"
    
    // singleton
    static let shared = APIService()
    
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
