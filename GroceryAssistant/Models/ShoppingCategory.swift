// MARK: - Shopping Category Model

import SwiftUI

/// Model representing a category for organizing shopping items.
struct ShoppingCategory: Identifiable, Codable, Hashable {
    /// Unique identifier for the category
    var id: String
    
    /// Name of the category
    var name: String
    
    /// Optional array of items in this category
    var items: [ShoppingItem]?
    
    /// Date when the category was created
    var createdDate: Date?
    
    /// ID of the user who created this category
    var userId: String?
    
    /// Initializes a category with the specified properties
    /// - Parameters:
    ///   - id: Unique identifier for the category
    ///   - name: Name of the category
    ///   - items: Optional array of items in this category
    ///   - createdDate: Date when the category was created
    ///   - userId: ID of the user who created this category
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
        
        // We don't store items directly in the category document
        // They are linked by categoryId in the items collection
        
        return dict
    }
    
    /// Hashing implementation for Hashable conformance
    /// - Parameter hasher: The hasher to use
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equatable implementation to compare categories by ID
    static func == (lhs: ShoppingCategory, rhs: ShoppingCategory) -> Bool {
        return lhs.id == rhs.id
    }
}