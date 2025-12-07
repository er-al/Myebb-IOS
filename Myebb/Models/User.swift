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
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
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
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

