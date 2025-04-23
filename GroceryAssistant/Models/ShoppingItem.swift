// MARK: - Shopping Item Model

import SwiftUI

/// Model representing an individual shopping item within a list.
struct ShoppingItem: Identifiable, Codable, Equatable {
    /// Unique identifier for the item
    var id: String
    
    /// Name of the item
    var name: String
    
    /// Whether the item has been checked off the list
    var checked: Bool = false
    
    /// Whether the item needs to be purchased
    var needToBuy: Bool = true
    
    /// Optional current price of the item
    var price: Double?
    
    /// Optional original price for comparison
    var originalPrice: Double?
    
    /// Whether to use simple count (true) or more detailed quantity tracking (false)
    var useSimpleCount: Bool = true
    
    /// Optional target quantity to purchase
    var targetQuantity: Int?
    
    /// Optional unit of measurement for the target quantity
    var targetUnit: String?
    
    /// Optional ID of the category this item belongs to
    var categoryId: String?
    
    /// Optional name of the category this item belongs to
    var categoryName: String?
    
    /// Optional ID of the shopping list this item belongs to
    var listId: String?
    
    /// Optional name of the shopping list this item belongs to
    var listName: String?
    
    /// Date when the item was created
    var createdDate: Date?
    
    /// Date when the item was last updated
    var updatedDate: Date?
    
    /// ID of the user who created this item
    var userId: String?
    
    /// Optional current quantity on hand
    var currentQuantity: Int?
    
    /// Optional unit of measurement for the current quantity
    var currentUnit: String?
    
    /// Equatable implementation to compare shopping items by ID
    static func == (lhs: ShoppingItem, rhs: ShoppingItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Coding keys for Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case checked
        case needToBuy
        case price
        case originalPrice
        case useSimpleCount
        case targetQuantity
        case targetUnit
        case categoryId
        case categoryName
        case listId
        case listName
        case createdDate
        case updatedDate
        case userId
        case currentQuantity
        case currentUnit
    }
    
    /// Initializes a shopping item with the specified properties
    /// - Parameters:
    ///   - id: Unique identifier for the item
    ///   - name: Name of the item
    ///   - checked: Whether the item is checked
    ///   - needToBuy: Whether the item needs to be purchased
    ///   - price: Current price of the item
    ///   - originalPrice: Original price for comparison
    ///   - useSimpleCount: Whether to use simple counting
    ///   - targetQuantity: Target quantity to purchase
    ///   - targetUnit: Unit of measurement for target
    ///   - categoryId: ID of the category
    ///   - categoryName: Name of the category
    ///   - listId: ID of the shopping list
    ///   - listName: Name of the shopping list
    ///   - createdDate: Date when created
    ///   - updatedDate: Date when last updated
    ///   - userId: ID of the creating user
    ///   - currentQuantity: Current quantity on hand
    ///   - currentUnit: Unit of measurement for current quantity
    init(id: String = UUID().uuidString, name: String, checked: Bool = false,
         needToBuy: Bool = true, price: Double? = nil, originalPrice: Double? = nil,
         useSimpleCount: Bool = true, targetQuantity: Int? = nil, targetUnit: String? = nil,
         categoryId: String? = nil, categoryName: String? = nil, listId: String? = nil,
         listName: String? = nil,
         createdDate: Date? = nil, updatedDate: Date? = nil, userId: String? = nil,
         currentQuantity: Int? = nil, currentUnit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.checked = checked
        self.needToBuy = needToBuy
        self.price = price
        self.originalPrice = originalPrice
        self.useSimpleCount = useSimpleCount
        self.targetQuantity = targetQuantity
        self.targetUnit = targetUnit
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.listId = listId
        self.listName = listName
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.userId = userId
        self.currentQuantity = currentQuantity
        self.currentUnit = currentUnit
    }
}
