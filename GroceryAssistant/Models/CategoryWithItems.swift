/// Model that groups shopping items by their category.
struct CategoryWithItems: Identifiable {
    let id: String
    let name: String
    var items: [ShoppingItem]
}
