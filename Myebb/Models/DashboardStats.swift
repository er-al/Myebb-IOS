//
//  DashboardStats.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation

enum DashboardRange: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .weekly:
            return "Week"
        case .monthly:
            return "Month"
        case .yearly:
            return "Year"
        }
    }
}

struct DashboardStats: Codable, Equatable {
    let range: String
    let totalEntries: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let mmrScore: Int
    let avgUpIntensity: Double
    let avgDownIntensity: Double
    let recentPerformance: [DailyPerformancePoint]
    
    private enum CodingKeys: String, CodingKey {
        case range
        case totalEntries = "total_entries"
        case wins
        case losses
        case winRate = "win_rate"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case mmrScore = "mmr_score"
        case avgUpIntensity = "avg_up_intensity"
        case avgDownIntensity = "avg_down_intensity"
        case recentPerformance = "recent_performance"
    }
    
    var winRateFormatted: String {
        String(format: "%.0f%%", winRate)
    }
    
    var momentumText: String {
        if winRate >= 70 {
            return "On fire"
        } else if winRate >= 50 {
            return "Steady"
        } else {
            return "Reset in progress"
        }
    }
}

struct DailyPerformancePoint: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let label: String
    let outcome: Int // 1 win, 0 loss, -1 no entry
    let intensity: Int?
}


