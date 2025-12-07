//
//  MoodPalette.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

enum ColorTheme {
    static let lilyWhite = Color(hex: "#FAFBFC")
    static let mistGray = Color(hex: "#DDE1E6")
    static let pebbleGray = Color(hex: "#C7CCD3")

    static let stemGreen = Color(hex: "#84A89C")
    static let petalRose = Color(hex: "#EFD6E9")

    static let moodUpGreen = Color(hex: "#6EC27F")
    static let moodDownRed = Color(hex: "#E86A6A")

    static let lilyLavender = Color(hex: "#A8A0C9")
    static let lakeBlue = Color(hex: "#AFCAD8")
    static let peachOrange = Color(hex: "#FFCCB0")

    static let textPrimary = Color(hex: "#4A4F5A")
    static let textSecondary = Color(hex: "#4A4F5A").opacity(0.65)
}

enum MoodPalette {
    static let positivePrimary = ColorTheme.moodUpGreen
    static let positiveSecondary = ColorTheme.stemGreen
    static let negativePrimary = ColorTheme.moodDownRed
    static let negativeSecondary = ColorTheme.petalRose

    static let positiveGradient = [positivePrimary, positiveSecondary]
    static let negativeGradient = [negativePrimary, negativeSecondary]
    static let insightGradient = [ColorTheme.lilyLavender, ColorTheme.lakeBlue]
}
