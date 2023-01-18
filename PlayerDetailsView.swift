//
//  PlayerDetailsView.swift
//  Podcasts
//
//  Created by joe on 2023/01/11.
//

import UIKit
import AVKit
import MediaPlayer

class PlayerDetailsView: UIView {
    var episode: Episode! {
        didSet {
            // skip if the same episode is loaded
            guard oldValue != episode else { return }
            
            titleLabel.text = episode.title
            miniTitleLabel.text = episode.title
            authorLabel.text = episode.author
            
            setupNowPlayingInfo()
            
            playEpisode()
            
            guard let url = URL(string: episode.imageUrl ?? "") else { return }
            episodeImageView.sd_setImage(with: url)
//            miniEpisodeImageView.sd_setImage(with: url)
            miniEpisodeImageView.sd_setImage(with: url) { image, _, _, _ in
                guard let image = image else { return }
                // lockscreen artwork setup code
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                // some modifications here
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ -> UIImage in
                    return image
                }
                nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    fileprivate func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.author
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func playEpisode() {
        print("Trying to play episode at url:", episode.streamUrl)
        
        guard let url = URL(string: episode.streamUrl) else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
    
    let player: AVPlayer = {
        let avPlayer = AVPlayer()
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        return avPlayer
    }()
    
    fileprivate func observePlayerCurrentTime() {
        let interval = CMTimeMake(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTimeLabel.text = time.toDisplayString()
            let durationTime = self?.player.currentItem?.duration
            self?.durationLabel.text = durationTime?.toDisplayString()
            
            self?.updateCurrentTimeSlider()
        }
    }
    
    fileprivate func updateCurrentTimeSlider() {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime(value: 1, timescale: 1))
        let percentage = currentTimeSeconds / durationSeconds
        
        self.currentTimeSlider.value = Float(percentage)
    }
    
    var panGesture: UIPanGestureRecognizer!
    
    fileprivate func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        miniPlayerView.addGestureRecognizer(panGesture)
        
        maximizedStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
    }
    
    @objc func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        print("maximizedStackView dismissal")
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: superview)
            maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        } else if gesture.state == .ended {
            let translation = gesture.translation(in: superview)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.maximizedStackView.transform = .identity
                
                if translation.y > 50 {
                    let mainTabBarController = self.window?.rootViewController as? MainTabBarController
                    mainTabBarController?.minimizePlayerDetails()
                }
            })
        }
    }
    
    fileprivate func observeBoundaryTime() {
        let time = CMTimeMake(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            print("Episode started playing")
            self?.enlargeEpisodeImageView()
            self?.setupLockscreenDuration()
        }
    }
    
    fileprivate func setupLockscreenDuration() {
        guard let duration = player.currentItem?.duration else { return }
        let durationSeconds = CMTimeGetSeconds(duration)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationSeconds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupGestures()
        
        observePlayerCurrentTime()
        observeBoundaryTime()
        
        setupAudioSession()
        setupRemoteControl()
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            handlePanChanged(gesture: gesture)
        } else if gesture.state == .ended {
            handlePanEnded(gesture: gesture)
        }
    }
    
    func handlePanChanged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        self.miniPlayerView.alpha = 1 + translation.y / 200
        self.maximizedStackView.alpha = -translation.y / 200
    }
    
    func handlePanEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        print("Ended:", velocity.y)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.transform = .identity
            if translation.y < -200 || velocity.y < -500 {
                let mainTabBarController = self.window?.rootViewController as? MainTabBarController
                mainTabBarController?.maximizePlayerDetails(episode: nil)
            } else {
                self.miniPlayerView.alpha = 1
                self.maximizedStackView.alpha = 0
            }
        })
    }
    
    fileprivate func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let sessionErr {
            print("Failed to activate session:", sessionErr)
        }
    }
    
    fileprivate func setupRemoteControl() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.player.play()
            self.playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            self.setupElapsedTime()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            self.playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "play"), for: .normal)
            self.setupElapsedTime()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.handlePlayPause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { _ in
            self.handleNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { _ in
            self.handlePrevTrack()
            return .success
        }
    }
    
    var playlistEpisodes = [Episode]()
    
    fileprivate func handlePrevTrack() {
        if playlistEpisodes.count == 0 {
            return
        }

        let currentEpisodeIndex = playlistEpisodes.firstIndex { ep in
            return self.episode.title == ep.title && self.episode.author == ep.author
        }
        guard let index = currentEpisodeIndex else { return }
        let nextEpisode: Episode
        if index == 0 {
            nextEpisode = playlistEpisodes[playlistEpisodes.count - 1]
        } else {
            nextEpisode = playlistEpisodes[index - 1]
        }
        self.episode = nextEpisode
    }
    
    fileprivate func handleNextTrack() {
        if playlistEpisodes.count == 0 {
            return
        }
        
        let currentEpisodeIndex = playlistEpisodes.firstIndex { ep in
            return self.episode.title == ep.title && self.episode.author == ep.author
        }
        guard let index = currentEpisodeIndex else { return }
        let nextEpisode: Episode
        if index == playlistEpisodes.count - 1 {
            nextEpisode = playlistEpisodes[0]
        } else {
            nextEpisode = playlistEpisodes[index + 1]
        }
        self.episode = nextEpisode
    }
    
    fileprivate func setupElapsedTime() {
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
    }
    
    @objc func handleTapMaximize() {
        let mainTabBarController = window?.rootViewController as? MainTabBarController
        mainTabBarController?.maximizePlayerDetails(episode: nil)
    }
    
    static func initFromNib() -> PlayerDetailsView {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    deinit {
        print("PlayerDetailsView memory being reclaimed...")
    }
    
    // MARK: - IB Actions and Outlets
    
    @IBOutlet weak var miniEpisodeImageView: UIImageView!
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        didSet {
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
            miniPlayPauseButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    @IBOutlet weak var miniFastForwardButton: UIButton! {
        didSet {
            miniFastForwardButton.addTarget(self, action: #selector(handleFastForward), for: .touchUpInside)
            miniFastForwardButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var maximizedStackView: UIStackView!
    
    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        print("Slider value:", currentTimeSlider.value)
        
        let percentage = currentTimeSlider.value
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        guard !(durationInSeconds.isNaN || durationInSeconds.isInfinite) else { return }
        let seekTimeInSeconds = Float64(percentage) * durationInSeconds
//        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: Int32(NSEC_PER_SEC))
//        print("NSEC_PER_SEC: ", NSEC_PER_SEC)
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: 1000000000)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekTimeInSeconds
        
        player.seek(to: seekTime)
    }
    
    @IBAction func handleRewind(_ sender: Any) {
        seekToCurrentTime(delta: -15)
    }
    @IBAction func handleFastForward(_ sender: Any) {
        seekToCurrentTime(delta: 15)
    }
    fileprivate func seekToCurrentTime(delta: Float64) {
        let fifteenSeconds = CMTimeMakeWithSeconds(delta, preferredTimescale: Int32(NSEC_PER_SEC))
        let seekTime = CMTimeAdd(player.currentTime(), fifteenSeconds)
        player.seek(to: seekTime)
    }
    
    @IBAction func handleVolumeChange(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeSlider: UISlider!
    
    @IBAction func handleDismiss(_ sender: Any) {
//        self.removeFromSuperview()
        let mainTabBarController = window?.rootViewController as? MainTabBarController
        mainTabBarController?.minimizePlayerDetails()
    }
    
    fileprivate func enlargeEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1) {
            self.episodeImageView.transform = .identity
        }
    }
    
    fileprivate let shrunkenTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    fileprivate func shrinkEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1) {
            self.episodeImageView.transform = self.shrunkenTransform
        }
    }
    
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius = 5
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.numberOfLines = 2
        }
    }
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @objc func handlePlayPause() {
        print("Trying to play and pause")
        if player.timeControlStatus == .paused {
            player.play()
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "pause"), for: .normal)
            enlargeEpisodeImageView()
        } else {
            player.pause()
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "play"), for: .normal)
            shrinkEpisodeImageView()
        }
    }
    
}
