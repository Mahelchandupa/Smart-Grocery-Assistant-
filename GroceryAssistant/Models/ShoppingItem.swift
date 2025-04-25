// MARK: - Shopping Item Model

import SwiftUI

/// Model representing an individual shopping item within a list.
struct ShoppingItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var checked: Bool = false
    var needToBuy: Bool = true 
    var price: Double?
    var originalPrice: Double?
    var useSimpleCount: Bool = true 
    var targetQuantity: Int? 
    var targetUnit: String?
    var categoryId: String?
    var categoryName: String?
    var listId: String?
    var listName: String?
    var createdDate: Date?
    var updatedDate: Date?
    var userId: String?
    var currentQuantity: Int?
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
