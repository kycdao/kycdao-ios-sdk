//
//  SceneDelegate.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import SwiftUI
import UIKit
import KycDao

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        //let rootView = ContentView()

        let config = Configuration(
//            apiKey: "",
            environment: .dev
        )
        
        VerificationManager.configure(config)
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()//UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
    }
}
