//
//  AppDelegate.swift
//  Myebb
//
//  Created by ChatGPT on 12/7/25.
//

import SwiftUI
import GoogleSignIn

/// App delegate to support Google OAuth URL callbacks.
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Keep any existing startup work here. Currently nothing to initialize.
        return true
    }

    /// Handles OAuth redirect URLs from Google Sign-In.
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Let GoogleSignIn process the incoming redirect; return whether it could handle it.
        return GIDSignIn.sharedInstance.handle(url)
    }
}
