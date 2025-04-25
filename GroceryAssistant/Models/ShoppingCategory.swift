// MARK: - Shopping Category Model

import SwiftUI

/// Model representing a category for organizing shopping items.
struct ShoppingCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var items: [ShoppingItem]?
    var createdDate: Date?
    var userId: String?
    
    /// Initializes a category with the specified properties
    init(id: String = UUID().uuidString, name: String, items: [ShoppingItem]? = nil, createdDate: Date? = nil, userId: String? = nil) {
        self.id = id
        self.name = name
        self.items = items
        self.createdDate = createdDate
        self.userId = userId
    }
    
    /// Coding keys for Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case items
        case createdDate
        case userId
    }
    
    /// Converts the category to a dictionary for Firestore storage
    /// - Returns: A dictionary representation of the category
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name
        ]
        
        if let createdDate = createdDate {
            dict["createdDate"] = createdDate
        }
        
        if let userId = userId {
            dict["userId"] = userId
        }
        
        return dict
    }
    
    /// Hashing implementation for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equatable implementation to compare categories by ID
    static func == (lhs: ShoppingCategory, rhs: ShoppingCategory) -> Bool {
        return lhs.id == rhs.id
    }
}