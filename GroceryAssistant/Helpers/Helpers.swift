import SwiftUI
import UIKit

// MARK: - Date Formatting

/// Extension providing standardized date formatters for the application.
extension DateFormatter {
    /// Creates a DateFormatter with medium date style.
    /// 
    /// This formatter follows the user's locale settings and displays dates
    /// in a medium format (e.g., "Jan 1, 2023" in US locale).
    /// 
    /// - Returns: A configured DateFormatter with medium date style
    static func mediumDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

/// Extension providing date formatting capabilities to Date objects.
extension Date {
    /// Formats the date using the medium date style.
    /// 
    /// - Returns: String representation of the date in a medium format (e.g., "Jan 1, 2023")
    func formattedMediumDate() -> String {
        DateFormatter.mediumDateFormatter().string(from: self)
    }
}

// MARK: - View Styling Extensions

/// Extension providing common styling modifiers for SwiftUI views.
extension View {
    /// Applies a standard card shadow effect to the view.
    /// 
    /// The shadow is subtle with low opacity and small radius to give
    /// a slight elevation effect typical of card UI elements.
    /// 
    /// - Returns: The view with card shadow applied
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    /// Centers the view horizontally within its parent container.
    /// 
    /// This modifier places equal Spacer views on both sides of the content
    /// to achieve horizontal centering.
    /// 
    /// - Returns: The view centered horizontally
    func centeredHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
    
    /// Applies corner radius to specific corners of a view.
    /// 
    /// Unlike the standard cornerRadius modifier which rounds all corners,
    /// this modifier allows you to specify which corners should be rounded.
    /// 
    /// - Parameters:
    ///   - radius: The radius to use when rounding the corners
    ///   - corners: The corners to apply the rounding to (e.g., .topLeft, .bottomRight)
    /// - Returns: The view with specified corners rounded
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// A custom shape for the tab bar that has rounded top corners
struct CustomShape: Shape {
    /// Creates a path with rounded top corners
    /// - Parameter rect: The rectangle defining the shape's area
    /// - Returns: A path with rounded top corners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 30, height: 30)
        )
        return Path(path.cgPath)
    }
}

/// A custom shape that allows rounding specific corners of a rectangle.
struct RoundedCorner: Shape {
    /// The radius to use when rounding corners
    var radius: CGFloat = .infinity

    /// The corners to apply rounding to
    var corners: UIRectCorner = .allCorners

    /// Creates a path with rounded corners as specified.
    /// 
    /// - Parameter rect: The rectangle defining the shape's area
    /// - Returns: A path with the specified corners rounded
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Data Conversion Extensions

/// Extension providing data conversion functionality to Encodable objects.
extension Encodable {
    /// Converts an Encodable object to a dictionary.
    /// 
    /// This is particularly useful when preparing data to be stored in Firestore
    /// or other dictionary-based storage systems.
    /// 
    /// - Returns: A dictionary representation of the object, or an empty dictionary if conversion fails
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