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
}

