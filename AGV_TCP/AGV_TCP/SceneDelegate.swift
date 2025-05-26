//
//  SceneDelegate.swift
//  AGV_TCP
//
//  Created by Dawid Widawski on 26/05/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let connectionVC = ConnectionViewController()
        let navigationController = UINavigationController(rootViewController: connectionVC)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

