// MARK: - Nutrition Models

import Foundation
import SwiftUI

/// Model representing nutritional information for a food product.
/// This can represent both top-level nutrients and nested sub-nutrients.
struct NutrientInfo: Identifiable {
    /// Unique identifier for the nutrient
    var id = UUID()
    
    /// Name of the nutrient (e.g., "Total Fat", "Protein")
    var name: String
    
    /// Numerical value of the nutrient
    var value: Double
    
    /// Unit of measurement (e.g., "g", "mg")
    var unit: String
    
    /// Percentage of daily recommended value, if applicable
    var dailyValue: Int?
    
    /// Optional array of sub-nutrients (e.g., saturated fat under total fat)
    var subNutrients: [NutrientInfo]?
    
    /// Determines the appropriate color to display based on daily value percentage.
    /// - Returns: A color representing the nutritional impact (green for low, yellow for moderate, red for high)
    func dailyValueColor() -> Color {
        guard let percentage = dailyValue else { return .gray }
        if percentage <= 5 { return .green }
        if percentage <= 20 { return .yellow }
        return .red
    }
}

/// Model representing a food product with nutritional information.
struct FoodProduct: Identifiable {
    /// Unique identifier for the food product
    var id: String
    
    /// Name of the food product
    var name: String
    
    /// Brand or manufacturer name
    var brand: String
    
    /// URL or path to the product image
    var image: String
    
    /// Description of what constitutes a serving (e.g., "1 cup (244g)")
    var serving: String
    
    /// Caloric content per serving
    var calories: Int
    
    /// Array of nutrients contained in the product
    var nutrients: [NutrientInfo]
    
    /// Array of potential allergens present in the product
    var allergens: [String]
    
    /// List of ingredients as a string
    var ingredients: String
    
    /// Array of health-related labels (e.g., "Organic", "Vegan")
    var healthLabels: [String]
    
    /// Creates an array of sample food products for development and testing.
    /// - Returns: An array of FoodProduct objects with realistic nutritional data
    static func dummyData() -> [FoodProduct] {
        return [
            FoodProduct(
                id: "1",
                name: "Organic Apple",
                brand: "Nature's Best",
                image: "https://www.orgpick.com/cdn/shop/articles/Apple_1024x1024.jpg?v=1547124407",
                serving: "1 medium (182g)",
                calories: 95,
                nutrients: [
                    NutrientInfo(
                        name: "Total Fat",
                        value: 0.3,
                        unit: "g",
                        dailyValue: 0,
                        subNutrients: [
                            NutrientInfo(name: "Saturated Fat", value: 0.1, unit: "g", dailyValue: 0),
                            NutrientInfo(name: "Trans Fat", value: 0, unit: "g", dailyValue: 0)
                        ]
                    ),
                    NutrientInfo(name: "Cholesterol", value: 0, unit: "mg", dailyValue: 0),
                    NutrientInfo(name: "Sodium", value: 2, unit: "mg", dailyValue: 0),
                    NutrientInfo(
                        name: "Total Carbohydrate",
                        value: 25,
                        unit: "g",
                        dailyValue: 8,
                        subNutrients: [
                            NutrientInfo(name: "Dietary Fiber", value: 4.4, unit: "g", dailyValue: 16),
                            NutrientInfo(name: "Total Sugars", value: 19, unit: "g", dailyValue: nil)
                        ]
                    ),
                    NutrientInfo(name: "Protein", value: 0.5, unit: "g", dailyValue: 1)
                ],
                allergens: [],
                ingredients: "Organic Apple",
                healthLabels: ["Organic", "Vegan", "Low Fat"]
            ),
            // Additional food products...
            FoodProduct(
                id: "5",
                name: "Avocado",
                brand: "Fresh Organics",
                image: "https://media.istockphoto.com/id/1210634323/photo/avocado-on-old-wooden-table-in-bowl.jpg?s=612x612&w=0&k=20&c=yEPVRJU3_7tw_1zK5DB5SbvxEG-jsSWTet8tvWc0-pc=",
                serving: "1 medium (150g)",
                calories: 240,
                nutrients: [
                    NutrientInfo(
                        name: "Total Fat",
                        value: 22,
                        unit: "g",
                        dailyValue: 34,
                        subNutrients: [
                            NutrientInfo(name: "Saturated Fat", value: 3.2, unit: "g", dailyValue: 16),
                            NutrientInfo(name: "Trans Fat", value: 0, unit: "g", dailyValue: 0)
                        ]
                    ),
                    NutrientInfo(name: "Cholesterol", value: 0, unit: "mg", dailyValue: 0),
                    NutrientInfo(name: "Sodium", value: 10, unit: "mg", dailyValue: 0),
                    NutrientInfo(
                        name: "Total Carbohydrate",
                        value: 12.8,
                        unit: "g",
                        dailyValue: 4,
                        subNutrients: [
                            NutrientInfo(name: "Dietary Fiber", value: 10, unit: "g", dailyValue: 40),
                            NutrientInfo(name: "Total Sugars", value: 0.7, unit: "g", dailyValue: nil)
                        ]
                    ),
                    NutrientInfo(name: "Protein", value: 3, unit: "g", dailyValue: 6)
                ],
                allergens: [],
                ingredients: "Organic Avocado",
                healthLabels: ["Organic", "Vegan", "High Fiber"]
            )
        ]
    }
}

/// Extension to map food names to appropriate SF Symbols.
extension String {
    /// Converts a food name to a corresponding SF Symbol name.
    /// - Parameter fallback: Symbol to use if no match is found
    /// - Returns: The name of an SF Symbol representing the food
    func foodImage(fallback: String = "questionmark.circle") -> String {
        switch self.lowercased() {
        case "apple": return "apple.logo"
        case "milk": return "cup.and.saucer"
        case "chicken": return "hare"
        case "pasta": return "fork.knife"
        case "avocado": return "leaf"
        default: return fallback
        }
    }
}
