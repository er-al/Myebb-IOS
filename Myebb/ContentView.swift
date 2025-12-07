//
//  ContentView.swift
//  Myebb
//
//  Created by Eric Al on 12/7/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MoodLoggingView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
