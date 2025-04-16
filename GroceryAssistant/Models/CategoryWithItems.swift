struct CategoryWithItems: Identifiable {
    let id: String
    let name: String
    var items: [ShoppingItem]
}
