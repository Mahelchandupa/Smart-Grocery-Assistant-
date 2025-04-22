import Foundation
import SwiftUI

// MARK: - Models with dummy data
struct NutrientInfo: Identifiable {
    var id = UUID()
    var name: String
    var value: Double
    var unit: String
    var dailyValue: Int?
    var subNutrients: [NutrientInfo]?
    
    // Helper function to determine color based on daily value percentage
    func dailyValueColor() -> Color {
        guard let percentage = dailyValue else { return .gray }
        if percentage <= 5 { return .green }
        if percentage <= 20 { return .yellow }
        return .red
    }
}

struct FoodProduct: Identifiable {
    var id: String
    var name: String
    var brand: String
    var image: String
    var serving: String
    var calories: Int
    var nutrients: [NutrientInfo]
    var allergens: [String]
    var ingredients: String
    var healthLabels: [String]
    
    // Create dummy data for UI development
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
            FoodProduct(
                id: "2",
                name: "Whole Milk",
                brand: "Dairy Farms",
                image: "https://s3.us-west-2.amazonaws.com/www.gethomesome.com/productimages/whole-milk-darigold.jpg",
                serving: "1 cup (244g)",
                calories: 149,
                nutrients: [
                    NutrientInfo(
                        name: "Total Fat",
                        value: 7.9,
                        unit: "g",
                        dailyValue: 12,
                        subNutrients: [
                            NutrientInfo(name: "Saturated Fat", value: 4.6, unit: "g", dailyValue: 23),
                            NutrientInfo(name: "Trans Fat", value: 0, unit: "g", dailyValue: 0)
                        ]
                    ),
                    NutrientInfo(name: "Cholesterol", value: 24, unit: "mg", dailyValue: 8),
                    NutrientInfo(name: "Sodium", value: 105, unit: "mg", dailyValue: 5),
                    NutrientInfo(
                        name: "Total Carbohydrate",
                        value: 12.3,
                        unit: "g",
                        dailyValue: 4,
                        subNutrients: [
                            NutrientInfo(name: "Dietary Fiber", value: 0, unit: "g", dailyValue: 0),
                            NutrientInfo(name: "Total Sugars", value: 12.3, unit: "g", dailyValue: nil)
                        ]
                    ),
                    NutrientInfo(name: "Protein", value: 7.7, unit: "g", dailyValue: 15)
                ],
                allergens: ["Milk"],
                ingredients: "Grade A Pasteurized Milk, Vitamin D3",
                healthLabels: ["Vegetarian", "Gluten-Free"]
            ),
            FoodProduct(
                id: "3",
                name: "Chicken Breast",
                brand: "Farm Fresh",
                image: "https://www.google.com/url?sa=i&url=https%3A%2F%2Fdownshiftology.https://downshiftology.com/wp-content/uploads/2023/01/How-To-Make-Air-Fryer-Chicken-5.jpg",
                serving: "100g",
                calories: 165,
                nutrients: [
                    NutrientInfo(
                        name: "Total Fat",
                        value: 3.6,
                        unit: "g",
                        dailyValue: 5,
                        subNutrients: [
                            NutrientInfo(name: "Saturated Fat", value: 1.0, unit: "g", dailyValue: 5),
                            NutrientInfo(name: "Trans Fat", value: 0, unit: "g", dailyValue: 0)
                        ]
                    ),
                    NutrientInfo(name: "Cholesterol", value: 85, unit: "mg", dailyValue: 28),
                    NutrientInfo(name: "Sodium", value: 74, unit: "mg", dailyValue: 3),
                    NutrientInfo(
                        name: "Total Carbohydrate",
                        value: 0,
                        unit: "g",
                        dailyValue: 0,
                        subNutrients: [
                            NutrientInfo(name: "Dietary Fiber", value: 0, unit: "g", dailyValue: 0),
                            NutrientInfo(name: "Total Sugars", value: 0, unit: "g", dailyValue: nil)
                        ]
                    ),
                    NutrientInfo(name: "Protein", value: 31, unit: "g", dailyValue: 62)
                ],
                allergens: [],
                ingredients: "Chicken breast without skin",
                healthLabels: ["High Protein", "Low Carb"]
            ),
            FoodProduct(
                id: "4",
                name: "Pasta",
                brand: "Italian Kitchen",
                image: "https://media.istockphoto.com/id/155433174/photo/bolognese-pens.jpg?s=612x612&w=0&k=20&c=A_TBqOAzcOkKbeVv8qSDs0bukfAedhkA458JEFolo_M=",
                serving: "100g (dry)",
                calories: 371,
                nutrients: [
                    NutrientInfo(
                        name: "Total Fat",
                        value: 1.5,
                        unit: "g",
                        dailyValue: 2,
                        subNutrients: [
                            NutrientInfo(name: "Saturated Fat", value: 0.3, unit: "g", dailyValue: 1),
                            NutrientInfo(name: "Trans Fat", value: 0, unit: "g", dailyValue: 0)
                        ]
                    ),
                    NutrientInfo(name: "Cholesterol", value: 0, unit: "mg", dailyValue: 0),
                    NutrientInfo(name: "Sodium", value: 6, unit: "mg", dailyValue: 0),
                    NutrientInfo(
                        name: "Total Carbohydrate",
                        value: 75,
                        unit: "g",
                        dailyValue: 25,
                        subNutrients: [
                            NutrientInfo(name: "Dietary Fiber", value: 3.2, unit: "g", dailyValue: 13),
                            NutrientInfo(name: "Total Sugars", value: 2.7, unit: "g", dailyValue: nil)
                        ]
                    ),
                    NutrientInfo(name: "Protein", value: 13, unit: "g", dailyValue: 26)
                ],
                allergens: ["Wheat", "Gluten"],
                ingredients: "Durum wheat semolina",
                healthLabels: ["Vegan", "Low Fat"]
            ),
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

// Extension for SF Symbols for food images
extension String {
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
