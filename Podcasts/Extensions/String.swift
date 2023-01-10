//
//  String.swift
//  Podcasts
//
//  Created by joe on 2023/01/10.
//

import Foundation

extension String {
    func toSecureHTTPS() -> String {
        return self.contains("https") ? self : self.replacingOccurrences(of: "http", with: "https")
    }
}
