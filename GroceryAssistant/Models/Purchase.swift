// MARK: - Purchase Model

import SwiftUI

/// Model representing a completed purchase with summary information.
struct Purchase: Identifiable, Codable {
    /// Unique identifier for the purchase
    var id: String
    
    /// ID of the shopping list this purchase is associated with
    var listId: String
    
    /// Name of the shopping list
    var listName: String
    
    /// Date when the purchase was made
    var date: Date
    
    /// Number of items included in the purchase
    var itemCount: Int
    
    /// Total amount spent on this purchase
    var totalSpent: Double
    
    /// Name of the store where the purchase was made
    var storeName: String
    
    /// ID of the user who made the purchase
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