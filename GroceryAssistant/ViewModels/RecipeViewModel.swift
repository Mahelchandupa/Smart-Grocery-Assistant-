//
//  RecipeViewModel.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 4/20/25.
//

import SwiftUI

class RecipeViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var suggestedRecipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var activeFilter: String = "All Recipes"
    
    let filterOptions = ["All Recipes", "Quick Meals", "Vegetarian", "Breakfast", "Lunch", "Dinner"]
    
    init() {
        fetchUserIngredients()
    }
    
    func fetchUserIngredients() {
        // Simulate fetching ingredients from a database
        isLoading = true
        
        // Mock ingredients data
        let mockIngredients = [
            Ingredient(name: "Chicken", quantity: "2 items"),
            Ingredient(name: "Potatoes", quantity: "4 items"),
            Ingredient(name: "Tomatoes", quantity: "3 items"),
            Ingredient(name: "Onion", quantity: "1 item"),
            Ingredient(name: "Garlic", quantity: "5 items"),
            Ingredient(name: "Rice", quantity: "Available"),
            Ingredient(name: "Pasta", quantity: "Available"),
            Ingredient(name: "Cheese", quantity: "Available")
        ]
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.ingredients = mockIngredients
            self?.isLoading = false
            self?.fetchRecipeSuggestions()
        }
    }
    
    func fetchRecipeSuggestions() {
        isLoading = true
        
        // Get the selected ingredients for the API search
        let selectedIngredients = ingredients.filter { $0.isSelected }.map { $0.name.lowercased() }
        
        if selectedIngredients.isEmpty {
            suggestedRecipes = []
            isLoading = false
            return
        }
        
        // Take the first ingredient for API search - this is simplified, in production we'd search for multiple
        if let firstIngredient = selectedIngredients.first {
            // Clean up ingredient name for API
            let cleanIngredient = firstIngredient.split(separator: " ").first?.lowercased() ?? firstIngredient
            
            // Using TheMealDB API
            let urlString = "https://www.themealdb.com/api/json/v1/1/filter.php?i=\(cleanIngredient)"
            
            guard let url = URL(string: urlString) else {
                self.isLoading = false
                return
            }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    guard let data = data, error == nil else {
                        print("Error fetching recipes: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    do {
                        // Parse the JSON data
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let meals = json["meals"] as? [[String: Any]] {
                            
                            // Fetch detailed information for each meal
                            self.processRecipes(meals: meals, selectedIngredients: selectedIngredients)
                        } else {
                            self.suggestedRecipes = []
                        }
                    } catch {
                        print("Error parsing JSON: \(error.localizedDescription)")
                        self.suggestedRecipes = []
                    }
                }
            }.resume()
        }
    }
    
    private func processRecipes(meals: [[String: Any]], selectedIngredients: [String]) {
        // Take only the first 5 recipes to keep it simple
        let limitedMeals = Array(meals.prefix(5))
        isLoading = true
        
        var processedRecipes: [Recipe] = []
        let dispatchGroup = DispatchGroup()
        
        for meal in limitedMeals {
            if let idMeal = meal["idMeal"] as? String {
                dispatchGroup.enter()
                fetchRecipeDetails(id: idMeal, selectedIngredients: selectedIngredients) { recipe in
                    if let recipe = recipe {
                        processedRecipes.append(recipe)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Sort by match percentage
            self.suggestedRecipes = processedRecipes.sorted { $0.matchPercentage > $1.matchPercentage }
            
            // Apply filter if needed
            self.applyFilter(filter: self.activeFilter)
            
            self.isLoading = false
        }
    }
    
    private func fetchRecipeDetails(id: String, selectedIngredients: [String], completion: @escaping (Recipe?) -> Void) {
        let urlString = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(id)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching recipe details: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let meals = json["meals"] as? [[String: Any]],
                   let meal = meals.first {
                    
                    // Extract ingredients and measures
                    var ingredients: [String] = []
                    var measures: [String] = []
                    
                    for i in 1...20 {
                        if let ingredient = meal["strIngredient\(i)"] as? String, !ingredient.isEmpty,
                           let measure = meal["strMeasure\(i)"] as? String {
                            ingredients.append(ingredient.lowercased())
                            measures.append(measure)
                        }
                    }
                    
                    // Calculate match percentage
                    let matchingIngredients = ingredients.filter { ingredient in
                        selectedIngredients.contains { selected in
                            ingredient.contains(selected) || selected.contains(ingredient)
                        }
                    }
                    
                    let matchPercentage = ingredients.isEmpty ? 0 : Int((Double(matchingIngredients.count) / Double(ingredients.count)) * 100)
                    
                    // Prepare the recipe object
                    let recipe = Recipe(
                        id: id,
                        name: meal["strMeal"] as? String ?? "Unknown Recipe",
                        category: meal["strCategory"] as? String ?? "Other",
                        area: meal["strArea"] as? String ?? "Unknown",
                        thumbnail: meal["strMealThumb"] as? String ?? "",
                        instructions: meal["strInstructions"] as? String ?? "No instructions available",
                        ingredients: ingredients,
                        measures: measures,
                        cookTime: meal["strCategory"] as? String == "Starter" ? "15-25 mins" : "30-45 mins",
                        servings: Int.random(in: 2...4), // Random since the API doesn't provide servings
                        matchPercentage: matchPercentage
                    )
                    
                    DispatchQueue.main.async {
                        completion(recipe)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Error parsing recipe details: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func toggleIngredientSelection(ingredient: Ingredient) {
        if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            ingredients[index].isSelected.toggle()
            fetchRecipeSuggestions()
        }
    }
    
    func applyFilter(filter: String) {
        activeFilter = filter
        
        // This is simplified filtering - in a real app, you might want to re-fetch with new filters
        if activeFilter == "All Recipes" {
            // No filtering needed
            return
        }
        
        // Apply category filtering
        suggestedRecipes = suggestedRecipes.filter { recipe in
            switch activeFilter {
            case "Vegetarian":
                return recipe.category == "Vegetarian"
            case "Quick Meals":
                return recipe.category == "Starter" || recipe.category == "Side"
            case "Breakfast":
                return recipe.category == "Breakfast"
            case "Lunch", "Dinner":
                return recipe.category == "Main dish" || recipe.category == "Dinner"
            default:
                return true
            }
        }
    }
}
