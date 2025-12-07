//
//  AppConfig.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import Foundation

enum AppConfig {
    static let apiBaseURL: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !value.isEmpty {
            return value
        }
        return "http://127.0.0.1:9090/api/v1"
    }()

    static let googleClientID: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
           !value.isEmpty {
            return value
        }
        return ""
    }()


    static let googleRedirectScheme: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_REDIRECT_SCHEME") as? String,
           !value.isEmpty {
            return value
        }
        // Fallback to the general OAuth scheme if not provided
        return oauthRedirectScheme
    }()

    static let oauthRedirectScheme: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "OAUTH_REDIRECT_SCHEME") as? String,
           !value.isEmpty {
            return value
        }
        return "myebb"
    }()
}

