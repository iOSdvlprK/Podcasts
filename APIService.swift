//
//  APIService.swift
//  Podcasts
//
//  Created by joe on 2023/01/04.
//

import Foundation
import Alamofire

class APIService {
    
    let baseiTunesSearchURL = "https://itunes.apple.com/search"
    
    // singleton
    static let shared = APIService()
    
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
