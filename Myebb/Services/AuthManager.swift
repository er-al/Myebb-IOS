//
//  AuthManager.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    
    var token: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    private init() {
        loadAuthState()
    }
    
    func login(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        saveUser(user)
        self.currentUser = user
        self.isAuthenticated = true
    }

    func updateUser(_ user: User) {
        saveUser(user)
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    private func loadAuthState() {
        if let token = token, !token.isEmpty {
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    private func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
}

