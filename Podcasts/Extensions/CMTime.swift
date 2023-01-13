//
//  CMTime.swift
//  Podcasts
//
//  Created by joe on 2023/01/13.
//

import AVKit

extension CMTime {
    func toDisplayString() -> String {
//        let totalSeconds = Int(CMTimeGetSeconds(self))
        let rawSeconds = CMTimeGetSeconds(self)
        guard !(rawSeconds.isNaN || rawSeconds.isInfinite) else { return "--" }
        let totalSeconds = Int(rawSeconds)
        let seconds = totalSeconds % 60
        let minutes = totalSeconds / 60
        let timeFormatString = String(format: "%02d:%02d", minutes, seconds)
        return timeFormatString
    }
}
