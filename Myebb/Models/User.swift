//
//  User.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
    let provider: String?
    let providerID: String?
    let avatarURL: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case provider
        case providerID = "provider_id"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }
}

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SocialLoginRequest: Codable {
    let token: String
}

struct ProfileUpdateRequest: Codable {
    let name: String?
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case avatarURL = "avatar_url"
    }
}

