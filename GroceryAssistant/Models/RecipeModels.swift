import Foundation

/// A model representing an ingredient that can be used in recipes.
///
/// This model includes the ingredient's name, quantity available, and selection state
/// for use in filtering recipe suggestions.
struct Ingredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: String
    var isSelected: Bool = true
}

/// A model representing a recipe with its details.
///
/// This model contains comprehensive information about a recipe, including its
/// ingredients, instructions, and metadata like cooking time and servings.
struct Recipe: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let area: String
    let thumbnail: String
    let instructions: String
    let ingredients: [String]
    let measures: [String]
    let cookTime: String
    let servings: Int
    let matchPercentage: Int
    
    /// Equatable implementation to compare recipes by ID
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id
    }
}