import SwiftUI

struct RecipeSuggestionsView: View {
    @Binding var navPath: NavigationPath
    @State private var loading = true
    @State private var ingredients: [IngredientItem] = []
    @State private var suggestedRecipes: [RecipeSuggestion] = []
    @State private var activeFilter: String = "All Recipes"
    @State private var selectedIngredients: [String] = []
    
    // Filtering options
    let filterOptions = [
        "All Recipes", "Quick Meals", "Vegetarian", "Breakfast", "Lunch", "Dinner"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(hex: "16A34A") // Green
                    .ignoresSafeArea(edges: .top)
                VStack {
                    HStack {
                        Button(action: {
                            navPath.removeLast()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 12)
                        
                        Text("Recipe Suggestions")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
                .padding(.top, 48)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
            }
            .frame(height: 100)
            
            if loading && ingredients.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(Color(hex: "22c55e"))
                    
                    Text("Loading your ingredients...")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4B5563"))
                        .padding(.top, 16)
                    Spacer()
                }
            } else {
                ScrollView {
                    // Current Ingredients
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Available Ingredients")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "1F2937"))
                                
                                Spacer()
                                
                                Text("\(selectedIngredients.count) selected")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "6B7280"))
                            }
                            .padding(.bottom, 4)
                            
                            if ingredients.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bag")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(hex: "D1D5DB"))
                                    
                                    Text("No ingredients found in your lists.\nAdd items to your shopping lists first.")
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "9CA3AF"))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(ingredients) { ingredient in
                                            IngredientButton(
                                                ingredient: ingredient,
                                                isSelected: selectedIngredients.contains(ingredient.name.lowercased()),
                                                action: {
                                                    toggleIngredientSelection(ingredient.name)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "E5E7EB")),
                        alignment: .bottom
                    )
                    
                    // Filter Options
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filterOptions, id: \.self) { filter in
                                    FilterButton(
                                        title: filter,
                                        isActive: filter == activeFilter,
                                        action: {
                                            activeFilter = filter
                                        }
                                    )
                                }
                                
                                Button(action: {
                                    // More filters action
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "line.3.horizontal.decrease")
                                            .font(.system(size: 14))
                                        Text("More Filters")
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .foregroundColor(Color(hex: "4B5563"))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "D1D5DB"), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color(hex: "F3F4F6"))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "E5E7EB")),
                        alignment: .bottom
                    )
                    
                    // Recipe Suggestions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Suggested Recipes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.horizontal, 16)
                        
                        if loading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.3)
                                    .tint(Color(hex: "22c55e"))
                                
                                Text("Finding recipes...")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "4B5563"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else if filteredRecipes.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "D1D5DB"))
                                
                                Text("No recipes found")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "9CA3AF"))
                                
                                Text("Try selecting different ingredients\nor check your shopping lists")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "9CA3AF"))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        } else {
                            ForEach(filteredRecipes) { recipe in
                                RecipeCard(recipe: recipe, navPath: $navPath)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 32) // Extra padding at bottom
                }
            }
        }
        .background(Color(hex: "F9FAFB"))
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
    }
    
    // Toggle ingredient selection
    private func toggleIngredientSelection(_ ingredientName: String) {
        let lowerName = ingredientName.lowercased()
        if selectedIngredients.contains(lowerName) {
            selectedIngredients.removeAll { $0 == lowerName }
        } else {
            selectedIngredients.append(lowerName)
        }
        
        // Reload recipe suggestions when selection changes
        Task {
            await fetchRecipeSuggestions()
        }
    }
    
    // Initial data loading
    private func loadData() {
        Task {
            do {
                let items = try await RecipeService.getAllItems()
                
                // Process ingredients
                let ingredientsList = items.map { item in
                    IngredientItem(
                        id: item.id,
                        name: item.name,
                        quantity: "\(item.quantity) \(item.quantity > 1 ? "items" : "item")"
                    )
                }
                
                // Remove duplicates
                var uniqueMap: [String: IngredientItem] = [:]
                for item in ingredientsList {
                    uniqueMap[item.name.lowercased()] = item
                }
                
                await MainActor.run {
                    self.ingredients = Array(uniqueMap.values)
                    self.selectedIngredients = uniqueMap.keys.map { $0 }
                    self.loading = false
                }
                
                // Fetch recipe suggestions
                await fetchRecipeSuggestions()
                
            } catch {
                print("Error loading ingredients: \(error.localizedDescription)")
                await MainActor.run {
                    self.ingredients = []
                    self.loading = false
                }
            }
        }
    }
    
    // Fetch recipe suggestions
    private func fetchRecipeSuggestions() async {
        if selectedIngredients.isEmpty {
            await MainActor.run {
                suggestedRecipes = []
                loading = false
            }
            return
        }
        
        await MainActor.run {
            loading = true
        }
        
        do {
            let recipes = try await RecipeService.fetchRecipeSuggestions(selectedIngredients: selectedIngredients)
            
            await MainActor.run {
                suggestedRecipes = recipes
                loading = false
            }
        } catch {
            print("Error fetching recipes: \(error.localizedDescription)")
            await MainActor.run {
                suggestedRecipes = []
                loading = false
            }
        }
    }
    
    // Filter recipes based on active filter
    private var filteredRecipes: [RecipeSuggestion] {
        if activeFilter == "All Recipes" {
            return suggestedRecipes
        }
        
        return suggestedRecipes.filter { recipe in
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

// MARK: - Supporting Views

struct IngredientButton: View {
    let ingredient: IngredientItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color(hex: "166534") : Color(hex: "1F2937"))
                
                Text(ingredient.quantity)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6B7280"))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(hex: "DCFCE7") : Color(hex: "F3F4F6"))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "16A34A") : Color(hex: "E5E7EB"), lineWidth: 1)
            )
            .frame(width: 140)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isActive ? .medium : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color(hex: "16A34A") : Color.white)
                .foregroundColor(isActive ? .white : Color(hex: "4B5563"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isActive ? Color.clear : Color(hex: "D1D5DB"), lineWidth: 1)
                )
        }
    }
}

struct RecipeCard: View {
    let recipe: RecipeSuggestion
    @Binding var navPath: NavigationPath
    
    var body: some View {
        Button(action: {
            navPath.append(Route.recipeDetail(id: recipe.id))
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                AsyncImage(url: URL(string: recipe.thumbnail)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "F3F4F6"))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(Color(hex: "D1D5DB"))
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color(hex: "F3F4F6"))
                    }
                }
                .frame(height: 160)
                .cornerRadius(12, corners: [.topLeft, .topRight])
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and match percentage
                    HStack {
                        Text(recipe.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "1F2937"))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(recipe.matchPercentage)% Match")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(matchPercentageColor(recipe.matchPercentage).opacity(0.1))
                            .foregroundColor(matchPercentageColor(recipe.matchPercentage))
                            .cornerRadius(12)
                    }
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TagPill(title: recipe.category)
                            TagPill(title: recipe.area)
                        }
                    }
                    
                    // Description
                    Text(recipe.description)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4B5563"))
                        .lineLimit(2)
                    
                    // Cook time and servings
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            Text(recipe.cookTime)
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "6B7280"))
                            
                            Text("\(recipe.servings) servings")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                    }
                    
                    // Missing ingredients
                    if !recipe.missingIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Missing ingredients:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "4B5563"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(recipe.missingIngredients.prefix(3), id: \.self) { ingredient in
                                    HStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "DCFCE7"))
                                                .frame(width: 20, height: 20)
                                            
                                            Image(systemName: "plus")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(hex: "16A34A"))
                                        }
                                        
                                        Text(ingredient)
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "4B5563"))
                                            .lineLimit(1)
                                    }
                                }
                                
                                if recipe.missingIngredients.count > 3 {
                                    Text("+\(recipe.missingIngredients.count - 3) more")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "6B7280"))
                                }
                            }
                        }
                    }
                    
                    // View Recipe Button
                    Button(action: {
                        navPath.append(Route.recipeDetail(id: recipe.id))
                    }) {
                        Text("View Recipe")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "16A34A"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func matchPercentageColor(_ percentage: Int) -> Color {
        if percentage > 80 {
            return Color(hex: "16A34A") // Green
        } else if percentage > 50 {
            return Color(hex: "F59E0B") // Yellow
        } else {
            return Color(hex: "EF4444") // Red
        }
    }
}

struct TagPill: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundColor(Color(hex: "4B5563"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "F3F4F6"))
            .cornerRadius(16)
    }
}

// Helper extension to create rounded corners for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}