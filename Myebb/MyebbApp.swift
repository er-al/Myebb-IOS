//
//  MyebbApp.swift
//  Myebb
//
//  Created by Eric Al on 12/7/25.
//

import SwiftUI
import GoogleSignIn

@main
struct MyebbApp: App {
    // Bridge UIKit app delegate for URL handling (Google Sign-In callbacks).
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(ColorTheme.stemGreen)
                .preferredColorScheme(.light)
        }
    }
}
