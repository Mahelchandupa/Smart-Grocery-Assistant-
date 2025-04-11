import SwiftUI

// ingredient selection
struct IngredientItem: Identifiable {
    let id: String
    let name: String
    let quantity: String
}

// Ingredient model for recipe details
struct MealIngredient: Identifiable {
    let id: Int
    let name: String
    let measure: String
}

// Instruction step model
struct InstructionStep: Identifiable {
    let id: Int
    let text: String
}

// Recipe suggestion model
struct RecipeSuggestion: Identifiable {
    let id: String
    let name: String
    let matchPercentage: Int
    let cookTime: String
    let servings: Int
    let missingIngredients: [String]
    let description: String
    let category: String
    let area: String
    let thumbnail: String
    let instructions: String
    let allIngredients: [MealIngredient]
    let youtubeUrl: String?
    let sourceUrl: String?
    let prepTime: String
    let calories: Int
    let tags: [String]
}