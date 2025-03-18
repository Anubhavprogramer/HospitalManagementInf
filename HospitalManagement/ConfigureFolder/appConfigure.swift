//
//  appConfigure.swift
//  HospitalManagement
//
//  Created by Anubhav Dubey on 18/03/25.
//

import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    static let backgroundColor = Color(hex: "#E2F3E2") // BackGroundColor
    static let primaryColor = Color(hex: "#B2E0B2") // PrimaryColor
    static let buttonColor = Color(hex: "#5DAA5D") // PrimaryColor
}

// MARK: - Hex Color Extension 
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1.0; g = 1.0; b = 1.0
        }
        self.init(red: r, green: g, blue: b)
    }
}
