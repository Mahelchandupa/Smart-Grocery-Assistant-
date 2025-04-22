import SwiftUI
import UIKit

// Date Formatter
extension DateFormatter {
    static func mediumDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

/// - Returns: String in format like "Jan 1, 2023"
extension Date {
    func formattedMediumDate() -> String {
        DateFormatter.mediumDateFormatter().string(from: self)
    }
}

// View Extensions
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    /// Centers the view horizontally
    func centeredHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else {
            return [:]
        }
        
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        
        return dictionary
    }
}

//private func formattedForecastDate(_ date: Date) -> String {
//    if Calendar.current.isDateInToday(date) {
//        return "Today"
//    } else if Calendar.current.isDateInTomorrow(date) {
//        return "Tomorrow"
//    }
//    
//    let formatter = DateFormatter()
//    formatter.dateFormat = "EEE"
//    return formatter.string(from: date) // "Mon", "Tue"
//}
//
//private func systemSymbol(for condition: String) -> String {
//    // Map WeatherKit symbols to SF Symbols (rough match)
//    switch condition {
//    case "cloud.sun": return "cloud.sun.fill"
//    case "cloud.rain": return "cloud.rain.fill"
//    case "sun.max": return "sun.max.fill"
//    case "cloud.bolt": return "cloud.bolt.fill"
//    case "cloud.snow": return "cloud.snow.fill"
//    default: return "cloud.fill"
//    }
//}
