/// Model that groups shopping items by their category.
struct CategoryWithItems: Identifiable {
    /// Unique identifier for the category (same as the category ID)
    let id: String
    
    /// Name of the category
    let name: String
    
    /// Array of shopping items that belong to this category
    var items: [ShoppingItem]
}
