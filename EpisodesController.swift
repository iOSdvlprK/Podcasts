//
//  EpisodesController.swift
//  Podcasts
//
//  Created by joe on 2023/01/08.
//

import UIKit

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
        
        APIService.shared.fetchEpisodes(feedUrl: feedUrl) { episodes in
            self.episodes = episodes
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate let cellId = "cellId"
    
    var episodes = [Episode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBarButtons()
    }
    
    // MARK: - Setup Work
    
    fileprivate func setupNavigationBarButtons() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Favorite", style: .plain, target: self, action: #selector(handleSaveFavorite)),
            UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(handleFetchSavedPodcasts))
        ]
    }
    
    @objc fileprivate func handleFetchSavedPodcasts() {
        print("Fetching saved Podcasts from UserDefaults")
        let value = UserDefaults.standard.value(forKey: favoritedPodcastKey) as? String
        print(value ?? "")
        
        // retrieve Podcast object from UserDefaults
        do {
            guard let data = UserDefaults.standard.data(forKey: favoritedPodcastKey) else { return }
            let podcast = try NSKeyedUnarchiver.unarchivedObject(ofClass: Podcast.self, from: data)
            print(podcast?.trackName, podcast?.artistName)
        } catch {
            print("Failed fetching saved data:", error)
        }
    }
    
    let favoritedPodcastKey = "favoritedPodcastKey"
    
    @objc fileprivate func handleSaveFavorite(){
        print("Saving info into UserDefaults")
        
        guard let podcast = self.podcast else { return }
        
//        UserDefaults.standard.set(podcast.trackName, forKey: favoritedPodcastKey)
        // transform Podcast into Data
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: podcast, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: favoritedPodcastKey)
        } catch {
            print("Failed archiving data:", error)
        }
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    // MARK: - UITableView
    
    // showing activity indicator view while fetching data
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.color = .systemGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodes.isEmpty ? 200 : 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = self.episodes[indexPath.row]
        let mainTabBarController = view.window?.rootViewController as? MainTabBarController
        
        mainTabBarController?.maximizePlayerDetails(episode: episode, playlistEpisodes: self.episodes)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.row]
        cell.episode = episode
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 134
    }
}
