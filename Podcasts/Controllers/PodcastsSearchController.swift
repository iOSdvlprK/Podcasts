//
//  PodcastsSearchController.swift
//  Podcasts
//
//  Created by joe on 2023/01/03.
//

import UIKit
import Alamofire

class PodcastsSearchController: UITableViewController, UISearchBarDelegate {
    
    var podcasts = [
        Podcast(trackName: "Podcasts TableView Controller", artistName: "Joe K."),
        Podcast(trackName: "UISearchController", artistName: "Some Author")
    ]
    
    let cellId = "cellId"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupTableView()
    }
    
    // MARK: - Setup Work
    
    fileprivate func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        print(searchText)
        // later implement Alamofire to search iTunes API
//        let url = "https://itunes.apple.com/search?term=\(searchText)"
        let url = "https://itunes.apple.com/search"
        let parameters = ["term": searchText, "media": "podcast"]
        
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { dataResponse in
            if let err = dataResponse.error {
                print("Failed to contact itunes", err)
                return
            }
            guard let data = dataResponse.data else { return }
            do {
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                self.podcasts = searchResult.results
                self.tableView.reloadData()
            } catch let decodeErr {
                print("Failed to decode:", decodeErr)
            }
        }
    }
    
    struct SearchResults: Decodable {
        let resultCount: Int
        let results: [Podcast]
    }
    
    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let podcast = self.podcasts[indexPath.row]
        cell.textLabel?.text = "\(podcast.trackName ?? "")\n\(podcast.artistName ?? "")"
        cell.textLabel?.numberOfLines = -1
        cell.imageView?.image = #imageLiteral(resourceName: "appicon")
        return cell
    }
}
