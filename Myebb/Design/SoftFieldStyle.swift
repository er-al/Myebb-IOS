//
//  SoftFieldStyle.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

struct SoftFieldStyle: ViewModifier {
    let placeholder: String
    let icon: String?
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(ColorTheme.stemGreen)
            }
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                content
                    .foregroundColor(ColorTheme.textPrimary)
            }
        }
        .padding()
        .background(ColorTheme.lilyWhite)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ColorTheme.mistGray, lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

extension View {
    func softFieldStyle(placeholder: String, icon: String? = nil, text: Binding<String>) -> some View {
        modifier(SoftFieldStyle(placeholder: placeholder, icon: icon, text: text))
    }
}

