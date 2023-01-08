//
//  EpisodesController.swift
//  Podcasts
//
//  Created by joe on 2023/01/08.
//

import UIKit
import FeedKit

class EpisodesController: UITableViewController {
    
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
            
            fetchEpisodes()
        }
    }
    
    fileprivate func fetchEpisodes() {
        print("Looking for episodes at feed url:", podcast?.feedUrl ?? "")
        
        guard let feedUrl = podcast?.feedUrl else { return }
        
        let secureFeedUrl = feedUrl.contains("https") ? feedUrl : feedUrl.replacingOccurrences(of: "http", with: "https")
        
//        guard let url = URL(string: feedUrl) else { return }
        guard let url = URL(string: secureFeedUrl) else { return }
        let parser = FeedParser(URL: url)
        parser.parseAsync { result in
            print("Successfully parse feed:", result.self)
            
            // associative enumeration values
            switch result {
            case .success(let feed):
                switch feed {
                case let .rss(feed):
                    var episodes = [Episode]()
                    feed.items?.forEach({ feedItem in
                        let episode = Episode(title: feedItem.title ?? "")
                        episodes.append(episode)
                    })
                    self.episodes = episodes
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                default:
                    print("Found a feed...")
                }
            case .failure(let error):
                print("Failed to parse feed:", error)
            }
        }
    }
    
    fileprivate let cellId = "cellId"
    
    struct Episode {
        let title: String
    }
    
    var episodes = [
        Episode(title: "First Episode"),
        Episode(title: "Second Episode"),
        Episode(title: "Third Episode")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    // MARK: - Setup Work
    
    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        let episode = episodes[indexPath.row]
        cell.textLabel?.text = episode.title
        return cell
    }
}
