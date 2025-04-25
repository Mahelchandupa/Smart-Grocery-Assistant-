// MARK: - Shopping List Model

import SwiftUI
import FirebaseCore
import FirebaseFirestore

/// Model representing a shopping list with metadata.
struct ShoppingList: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var color: String
    var dueDate: Date?
    var totalItems: Int = 0
    var completedItems: Int = 0

    /// Equatable implementation to compare shopping lists by ID
    static func == (lhs: ShoppingList, rhs: ShoppingList) -> Bool {
        return lhs.id == rhs.id
    }

    /// Coding keys for Codable implementation
    enum CodingKeys: String, CodingKey {
        case id, name, color, dueDate, totalItems, completedItems
    }

    /// Initializes a new shopping list with the specified properties
    init(id: String, name: String, color: String, dueDate: Date? = nil, totalItems: Int = 0, completedItems: Int = 0) {
        self.id = id
        self.name = name
        self.color = color
        self.dueDate = dueDate
        self.totalItems = totalItems
        self.completedItems = completedItems
    }

    /// Initializes a shopping list from a decoder, handling special cases like timestamp conversion
    /// - Parameter decoder: The decoder to read data from
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)
        completedItems = try container.decode(Int.self, forKey: .completedItems)
        totalItems = try container.decode(Int.self, forKey: .totalItems)

        // Handle dueDate as number (timestamp)
        if let timestamp = try? container.decode(Double.self, forKey: .dueDate) {
            dueDate = Date(timeIntervalSince1970: timestamp)
        } else if let intTimestamp = try? container.decode(Int.self, forKey: .dueDate) {
            dueDate = Date(timeIntervalSince1970: TimeInterval(intTimestamp))
        } else {
            dueDate = nil
        }
    }
}