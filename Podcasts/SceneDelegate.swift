//
//  SceneDelegate.swift
//  Podcasts
//
//  Created by joe on 2023/01/03.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    @available(iOS 13.0, *)
    func customNavBarAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .clear
        
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        return appearance
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        UINavigationBar.appearance().prefersLargeTitles = true
        if #available(iOS 13.0, *) {
            let newNavBarAppearance = customNavBarAppearance()
            UINavigationBar.appearance().scrollEdgeAppearance = newNavBarAppearance
            UINavigationBar.appearance().compactAppearance = newNavBarAppearance
            UINavigationBar.appearance().standardAppearance = newNavBarAppearance
            
            let newTabBarAppearance = UITabBarAppearance()
            newTabBarAppearance.configureWithDefaultBackground()
            newTabBarAppearance.backgroundColor = .clear
            UITabBar.appearance().standardAppearance = newTabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = newTabBarAppearance
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }



}

