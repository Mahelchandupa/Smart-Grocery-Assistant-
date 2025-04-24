import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// Converts a SwiftUI Color to a hexadecimal string representation.
    ///
    /// This method extracts the RGB components of the color and formats them
    /// as a hexadecimal string with a leading hash character.
    ///
    /// - Returns: A string in the format "#RRGGBB" where RR, GG, and BB are
    ///   hexadecimal values for the red, green, and blue components respectively,
    ///   or nil if the conversion fails
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
    
    /// Creates a Color from a hexadecimal string representation.
    ///
    /// This initializer supports different hex formats:
    /// - 3 digits: RGB format (e.g., "#RGB" or "RGB")
    /// - 6 digits: RRGGBB format (e.g., "#RRGGBB" or "RRGGBB")
    /// - 8 digits: AARRGGBB format with alpha (e.g., "#AARRGGBB" or "AARRGGBB")
    ///
    /// - Parameter hex: A string representing a color in hexadecimal format,
    ///   with or without a leading "#" character
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Color Palette

/// A struct that defines the application's color palette.
///
/// This struct provides a centralized repository of all colors used throughout the application.
/// Colors are organized by color family and intensity, following a consistent naming convention.
struct AppColors {
    // MARK: Gray Scale
    
    /// Dark gray color for primary text (#1F2937)
    static let gray800 = Color(hex: "#1F2937")
    
    /// Medium-dark gray color for secondary text (#374151)
    static let gray700 = Color(hex: "#374151")
    
    /// Medium gray color for subtitles (#4B7280)
    static let gray600 = Color(hex: "#4B7280")
    
    /// Standard gray color for placeholder text (#6B7280)
    static let gray500 = Color(hex: "#6B7280")
    
    /// Light gray color for disabled elements (#9CA3AF)
    static let gray400 = Color(hex: "#9CA3AF")
    
    // MARK: Green Scale
    
    /// Dark green color for primary buttons (#16A34A)
    static let green600 = Color(hex: "#16A34A")
    
    /// Medium green color for secondary elements (#22C55E)
    static let green500 = Color(hex: "#22C55E")
    
    /// Very dark green color for headers (#166534)
    static let green800 = Color(hex: "#166534")
    
    /// Very light green color for backgrounds (#DCFCE7)
    static let green100 = Color(hex: "#DCFCE7")
    
    /// Bright green color for success states (#4ADE80)
    static let green400 = Color(hex: "#4ADE80")
    
    // MARK: Basic Colors
    
    /// Pure white color (#FFFFFF)
    static let white = Color(hex: "#FFFFFF")
    
    /// Pure black color (#000000)
    static let black = Color(hex: "#000000")
    
    /// Light gray background color (#F9FAFB)
    static let background = Color(hex: "#F9FAFB")
    
    /// Red color for errors and alerts (#F44336)
    static let red = Color(hex: "#F44336")
    
    /// Blue color for information and links (#2196F3)
    static let blue = Color(hex: "#2196F3")
}
