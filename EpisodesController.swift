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
        // check if we have already saved this podcast as favorite
        let savedPodcasts = UserDefaults.standard.savedPodcasts()
        let hasFavorited = savedPodcasts.firstIndex(where: { $0.trackName == self.podcast?.trackName && $0.artistName == self.podcast?.artistName }) != nil
        if hasFavorited {
            // set up heart icon
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal), style: .plain, target: nil, action: nil)
        } else {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Favorite", style: .plain, target: self, action: #selector(handleSaveFavorite)),
//                UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(handleFetchSavedPodcasts))
            ]
        }
    }
    
    @objc fileprivate func handleFetchSavedPodcasts() {
        print("Fetching saved Podcasts from UserDefaults")
        
        // retrieve Podcast object from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: UserDefaults.favoritedPodcastKey) else { return }
        let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Podcast]
        savedPodcasts?.forEach({ podcast in
            print(podcast.trackName ?? "")
        })
    }
    
    @objc fileprivate func handleSaveFavorite(){
        print("Saving info into UserDefaults")
        
        guard let podcast = self.podcast else { return }
        
        // transform Podcast into Data
        var listOfPodcasts = UserDefaults.standard.savedPodcasts()
        listOfPodcasts.append(podcast)
        let data = NSKeyedArchiver.archivedData(withRootObject: listOfPodcasts)
        UserDefaults.standard.set(data, forKey: UserDefaults.favoritedPodcastKey)
        
        showBadgeHighlight()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal), style: .plain, target: nil, action: nil)
    }
    
    fileprivate func showBadgeHighlight() {
        let mainTabBarController = view.window?.rootViewController as? MainTabBarController
        mainTabBarController?.viewControllers?[0].tabBarItem.badgeValue = "New"
    }
    
    fileprivate func showDownloadBadgeHighlight() {
        let mainTabBarController = view.window?.rootViewController as? MainTabBarController
        mainTabBarController?.viewControllers?[2].tabBarItem.badgeValue = "New"
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let downloadAction = UIContextualAction(style: .normal, title: "Download") { _, _, _ in
            print("Downloading episode into UserDefaults")
            let episode = self.episodes[indexPath.row]
            UserDefaults.standard.downloadEpisode(episode: episode)
            self.showDownloadBadgeHighlight()
        }
        downloadAction.image = UIImage(systemName: "square.and.arrow.down")
        let swipeConfig = UISwipeActionsConfiguration(actions: [downloadAction])
        return swipeConfig
    }
    
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
