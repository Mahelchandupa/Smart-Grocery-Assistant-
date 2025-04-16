struct ShoppingItem: Identifiable, Codable {
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
    var createdDate: Date?
    var updatedDate: Date?
    var userId: String?
    
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
        case createdDate
        case updatedDate
        case userId
    }
}