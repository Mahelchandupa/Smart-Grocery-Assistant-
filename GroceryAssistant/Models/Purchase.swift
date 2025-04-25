// MARK: - Purchase Model

import SwiftUI

/// Model representing a completed purchase with summary information.
struct Purchase: Identifiable, Codable {
    var id: String
    var listId: String
    var listName: String
    var date: Date
    var itemCount: Int
    var totalSpent: Double
    var storeName: String
    var userId: String
    
    /// Coding keys for Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case listId
        case listName
        case date
        case itemCount
        case totalSpent
        case storeName
        case userId
    }
}