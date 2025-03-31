import Foundation
import SwiftUI

struct ShoppingList: Identifiable, Codable {
    var id: String
    var name: String
    var color: String // Store as hex string
    var items: [ShoppingItem]
    var createdAt: Date
    var updatedAt: Date
    
    // Computed property to convert hex string to Color
    var displayColor: Color {
        Color(hex: color)
    }
}

struct ShoppingItem: Identifiable, Codable {
    var id: String
    var name: String
    var quantity: Int
    var checked: Bool
    var category: String?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
}
