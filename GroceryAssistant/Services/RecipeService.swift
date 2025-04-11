import Foundation
import FirebaseFirestore
import FirebaseAuth

// API models for TheMealDB
struct MealDBResponse: Codable {
    let meals: [MealBasic]?
}

struct MealBasic: Codable, Identifiable {
    let idMeal: String
    let strMeal: String
    let strMealThumb: String
    
    var id: String { idMeal }
}

struct MealDetailResponse: Codable {
    let meals: [MealDetail]?
}

struct MealDetail: Codable, Identifiable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strTags: String?
    let strYoutube: String?
    let strSource: String?
    
    // Ingredients and measures (up to 20)
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?
    
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?
    
    var id: String { idMeal }
    
    // Get all valid ingredients and their measures
    func getAllIngredients() -> [MealIngredient] {
        var ingredients: [MealIngredient] = []
        
        // Helper function to add ingredients
        func addIfValid(ingredient: String?, measure: String?, index: Int) {
            guard let ingredient = ingredient, !ingredient.isEmpty, ingredient != " " else { return }
            ingredients.append(MealIngredient(
                id: index,
                name: ingredient.trimmingCharacters(in: .whitespaces),
                measure: measure?.trimmingCharacters(in: .whitespaces) ?? ""
            ))
        }
        
        addIfValid(ingredient: strIngredient1, measure: strMeasure1, index: 1)
        addIfValid(ingredient: strIngredient2, measure: strMeasure2, index: 2)
        addIfValid(ingredient: strIngredient3, measure: strMeasure3, index: 3)
        addIfValid(ingredient: strIngredient4, measure: strMeasure4, index: 4)
        addIfValid(ingredient: strIngredient5, measure: strMeasure5, index: 5)
        addIfValid(ingredient: strIngredient6, measure: strMeasure6, index: 6)
        addIfValid(ingredient: strIngredient7, measure: strMeasure7, index: 7)
        addIfValid(ingredient: strIngredient8, measure: strMeasure8, index: 8)
        addIfValid(ingredient: strIngredient9, measure: strMeasure9, index: 9)
        addIfValid(ingredient: strIngredient10, measure: strMeasure10, index: 10)
        addIfValid(ingredient: strIngredient11, measure: strMeasure11, index: 11)
        addIfValid(ingredient: strIngredient12, measure: strMeasure12, index: 12)
        addIfValid(ingredient: strIngredient13, measure: strMeasure13, index: 13)
        addIfValid(ingredient: strIngredient14, measure: strMeasure14, index: 14)
        addIfValid(ingredient: strIngredient15, measure: strMeasure15, index: 15)
        addIfValid(ingredient: strIngredient16, measure: strMeasure16, index: 16)
        addIfValid(ingredient: strIngredient17, measure: strMeasure17, index: 17)
        addIfValid(ingredient: strIngredient18, measure: strMeasure18, index: 18)
        addIfValid(ingredient: strIngredient19, measure: strMeasure19, index: 19)
        addIfValid(ingredient: strIngredient20, measure: strMeasure20, index: 20)
        
        return ingredients
    }
}

class RecipeService {
    static let baseURL = "https://www.themealdb.com/api/json/v1/1"
    
    static func getAllItems() async throws -> [ShoppingItem] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("lists")
            .getDocuments()
        
        var allItems: [ShoppingItem] = []
        
        for document in snapshot.documents {
            guard let list = try? document.data(as: ShoppingList.self) else { continue }
            allItems.append(contentsOf: list.items)
        }
        
        return allItems
    }
    
    static func searchRecipesByIngredient(ingredient: String) async throws -> [MealBasic] {
        guard let cleanIngredient = ingredient.split(separator: " ").first?.lowercased() else {
            return []
        }
        
        // URL encode the ingredient
        guard let encodedIngredient = cleanIngredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/filter.php?i=\(encodedIngredient)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let mealResponse = try decoder.decode(MealDBResponse.self, from: data)
        
        return mealResponse.meals ?? []
    }
    
    static func getMealDetails(id: String) async throws -> MealDetail {
        guard let url = URL(string: "\(baseURL)/lookup.php?i=\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let mealResponse = try decoder.decode(MealDetailResponse.self, from: data)
        
        guard let meal = mealResponse.meals?.first else {
            throw NSError(domain: "RecipeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Recipe not found"])
        }
        
        return meal
    }
    
    static func fetchRecipeSuggestions(selectedIngredients: [String]) async throws -> [RecipeSuggestion] {
        if selectedIngredients.isEmpty {
            return []
        }
        
        var allMeals: [MealBasic] = []
        var seenMealIds = Set<String>()
        
        // Search for recipes based on up to 5 ingredients
        for ingredient in selectedIngredients.prefix(5) {
            do {
                let meals = try await searchRecipesByIngredient(ingredient: ingredient)
                
                for meal in meals {
                    if !seenMealIds.contains(meal.idMeal) {
                        seenMealIds.insert(meal.idMeal)
                        allMeals.append(meal)
                    }
                }
            } catch {
                print("Error searching by ingredient \(ingredient): \(error.localizedDescription)")
            }
        }
        
        // Limit to 10 meals for details
        allMeals = Array(allMeals.prefix(10))
        
        var recipeSuggestions: [RecipeSuggestion] = []
        
        // Get details for each meal
        for meal in allMeals {
            do {
                let mealDetail = try await getMealDetails(id: meal.idMeal)
                let mealIngredients = mealDetail.getAllIngredients()
                
                // Calculate match percentage
                let matchingIngredients = mealIngredients.filter { ingredient in 
                    selectedIngredients.contains { selected in
                        ingredient.name.lowercased().contains(selected) || selected.contains(ingredient.name.lowercased())
                    }
                }
                
                let matchPercentage = mealIngredients.isEmpty ? 0 : Int(Double(matchingIngredients.count) / Double(mealIngredients.count) * 100)
                
                // Find missing ingredients
                let missingIngredients = mealIngredients
                    .filter { ingredient in 
                        !selectedIngredients.contains { selected in
                            ingredient.name.lowercased().contains(selected) || selected.contains(ingredient.name.lowercased())
                        }
                    }
                    .map { "\($0.name)\($0.measure.isEmpty ? "" : " (\($0.measure))")" }
                
                // Determine cook time based on category
                let cookTime = (mealDetail.strCategory == "Starter" || mealDetail.strCategory == "Side") ? "15-25 mins" : "30-45 mins"
                
                // Random servings (API doesn't provide this)
                let servings = Int.random(in: 2...4)
                
                // Random prep time and calories
                let prepTime = "\(Int.random(in: 5...20)) mins"
                let calories = Int.random(in: 200...700)
                
                let description = (mealDetail.strInstructions ?? "").prefix(100) + "..."
                
                // Parse tags
                let tags = mealDetail.strTags?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []
                
                let recipe = RecipeSuggestion(
                    id: mealDetail.idMeal,
                    name: mealDetail.strMeal,
                    matchPercentage: matchPercentage,
                    cookTime: cookTime,
                    servings: servings,
                    missingIngredients: missingIngredients,
                    description: String(description),
                    category: mealDetail.strCategory ?? "Unknown",
                    area: mealDetail.strArea ?? "Unknown",
                    thumbnail: mealDetail.strMealThumb ?? "",
                    instructions: mealDetail.strInstructions ?? "",
                    allIngredients: mealIngredients,
                    youtubeUrl: mealDetail.strYoutube,
                    sourceUrl: mealDetail.strSource,
                    prepTime: prepTime,
                    calories: calories,
                    tags: tags
                )
                
                recipeSuggestions.append(recipe)
            } catch {
                print("Error getting meal details for \(meal.idMeal): \(error.localizedDescription)")
            }
        }
        
        // Sort by match percentage
        return recipeSuggestions.sorted { $0.matchPercentage > $1.matchPercentage }
    }
    
    static func getRecipeDetails(id: String) async throws -> RecipeSuggestion {
        let mealDetail = try await getMealDetails(id: id)
        let mealIngredients = mealDetail.getAllIngredients()
        
        // Process instructions into steps
        let instructionsText = mealDetail.strInstructions ?? ""
        let instructionSteps = instructionsText
            .split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Randomize these values as they're not provided by the API
        let cookTime = "\(Int.random(in: 15...45)) mins"
        let prepTime = "\(Int.random(in: 5...20)) mins"
        let servings = Int.random(in: 2...4)
        let calories = Int.random(in: 200...700)
        
        // Parse tags
        let tags = mealDetail.strTags?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []
        
        return RecipeSuggestion(
            id: mealDetail.idMeal,
            name: mealDetail.strMeal,
            matchPercentage: 100, // Not applicable for direct view
            cookTime: cookTime,
            servings: servings,
            missingIngredients: [], // Not applicable for direct view
            description: instructionsText.prefix(100) + "...",
            category: mealDetail.strCategory ?? "Unknown",
            area: mealDetail.strArea ?? "Unknown",
            thumbnail: mealDetail.strMealThumb ?? "",
            instructions: instructionsText,
            allIngredients: mealIngredients,
            youtubeUrl: mealDetail.strYoutube,
            sourceUrl: mealDetail.strSource,
            prepTime: prepTime,
            calories: calories,
            tags: tags
        )
    }
}

enum AuthError: Error {
    case notAuthenticated
}