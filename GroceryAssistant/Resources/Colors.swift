//
//  Colors.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/30/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let scanner = Scanner(string: hexSanitized)
        
        if hexSanitized.hasPrefix("#") {
            scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
        }
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct AppColors {
    static let gray800 = Color(hex: "#1F2937")
    static let gray700 = Color(hex: "#374151")
    static let gray600 = Color(hex: "#4B7280")
    static let gray500 = Color(hex: "#6B7280")
    static let gray400 = Color(hex: "#9CA3AF")
    
    static let green600 = Color(hex: "#16A34A")
    static let green500 = Color(hex: "#22C55E")
    static let green800 = Color(hex: "#166534")
    static let green100 = Color(hex: "#DCFCE7")
    static let green400 = Color(hex: "#4ADE80")
    
    static let white = Color(hex: "#FFFFFF")
    static let black = Color(hex: "#000000")
    static let background = Color(hex: "#F9FAFB")
    static let red = Color(hex: "#F44336")
    static let blue = Color(hex: "#2196F3")
    
}
