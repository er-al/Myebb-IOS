//
//  APIService.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = AppConfig.apiBaseURL
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Custom date decoding strategy to handle both date-only (YYYY-MM-DD) and RFC3339 formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try RFC3339 format first
            let rfc3339Formatter = ISO8601DateFormatter()
            rfc3339Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = rfc3339Formatter.date(from: dateString) {
                return date
            }
            
            // Try RFC3339 without fractional seconds
            rfc3339Formatter.formatOptions = [.withInternetDateTime]
            if let date = rfc3339Formatter.date(from: dateString) {
                return date
            }
            
            // Try date-only format (YYYY-MM-DD)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return decoder
    }()
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Authentication
    
    func register(email: String, password: String, name: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RegisterRequest(email: email, password: password, name: name)
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Registration failed")
        }
        
        return try jsonDecoder.decode(LoginResponse.self, from: data)
    }
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(email: email, password: password)
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Login failed")
        }
        
        return try jsonDecoder.decode(LoginResponse.self, from: data)
    }

    func loginWithGoogle(idToken: String) async throws -> LoginResponse {
        try await socialLogin(path: "/auth/google", token: idToken)
    }


    private func socialLogin(path: String, token: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = SocialLoginRequest(token: token)
        request.httpBody = try jsonEncoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Login failed")
        }

        return try jsonDecoder.decode(LoginResponse.self, from: data)
    }

    // MARK: - Profile
    
    func getProfile() async throws -> User {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to load profile")
        }
        
        let user = try jsonDecoder.decode(User.self, from: data)
        AuthManager.shared.updateUser(user)
        return user
    }
    
    func updateProfile(name: String?, avatarDataURL: String?) async throws -> User {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAvatar = avatarDataURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = ProfileUpdateRequest(
            name: trimmedName?.isEmpty == true ? nil : trimmedName,
            avatarURL: trimmedAvatar?.isEmpty == true ? nil : trimmedAvatar
        )
        
        let url = URL(string: "\(baseURL)/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to update profile")
        }
        
        let user = try jsonDecoder.decode(User.self, from: data)
        AuthManager.shared.updateUser(user)
        return user
    }
    
    // MARK: - Mood Management
    
    func logMood(state: Int, intensity: Int, date: String? = nil, note: String? = nil) async throws -> Mood {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/states")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = MoodRequest(state: state, intensity: intensity, date: date, note: note, weather: nil)
        request.httpBody = try jsonEncoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to log state")
        }
        
        return try jsonDecoder.decode(Mood.self, from: data)
    }
    
    func getTodayMood() async throws -> Mood? {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        // Format date as YYYY-MM-DD for the API
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let url = URL(string: "\(baseURL)/states/date/\(today)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to get today's state")
        }
        
        return try jsonDecoder.decode(Mood.self, from: data)
    }
    
    func getMoodHistory(limit: Int = 30) async throws -> [Mood] {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/states?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to get state history")
        }
        
        return try jsonDecoder.decode([Mood].self, from: data)
    }
    
    // MARK: - Dashboard
    
    func getDashboardStats(range: DashboardRange = .monthly) async throws -> DashboardStats {
        guard let token = AuthManager.shared.token else {
            throw APIError.unauthorized
        }
        
        var components = URLComponents(string: "\(baseURL)/analytics/dashboard")!
        components.queryItems = [
            URLQueryItem(name: "range", value: range.rawValue)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? jsonDecoder.decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.serverError("Failed to load dashboard")
        }
        
        return try jsonDecoder.decode(DashboardStats.self, from: data)
    }
}

