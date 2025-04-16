struct ShoppingCategory: Identifiable, Codable {
    var id: String
    var name: String
    var items: [ShoppingItem]
}