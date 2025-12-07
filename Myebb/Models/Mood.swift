//
//  Mood.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation

struct Mood: Codable, Identifiable {
    let id: Int
    let userId: Int
    let date: Date
    let state: Int // 1 = positive (up), 0 = negative (down)
    let intensity: Int
    let timestamp: Date
    let note: String?
    let weather: String?
    let isEdited: Bool
    let editedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case state
        case intensity
        case timestamp
        case note
        case weather
        case isEdited = "is_edited"
        case editedAt = "edited_at"
        case createdAt = "created_at"
    }
    
    var isPositive: Bool {
        return state == 1
    }
    
    var formattedDate: String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
    
    var dateOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct MoodRequest: Codable {
    let state: Int // 1 = positive, 0 = negative
    let intensity: Int
    let date: String?
    let note: String?
    let weather: String?
}

