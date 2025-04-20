import SwiftUI

// MARK: - Models
struct Ingredient: Identifiable {
    let id = UUID()
    let name: String
    let quantity: String
    var isSelected: Bool = true
}

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
}

// MARK: - Views
struct RecipeSuggestionsView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = RecipeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    if viewModel.isLoading && viewModel.ingredients.isEmpty {
                        loadingView
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Ingredients section
                                ingredientsSection
                                
                                // Filter section
                                filterSection
                                
                                // Recipe suggestions
                                recipeSuggestionsSection
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Component Views
    
    var headerView: some View {
        ZStack {
            Color.green
                .edgesIgnoringSafeArea(.top)
            
            HStack {
                Button(action: {
                    if navPath.count > 0 {
                        navPath.removeLast()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Recipe Suggestions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .frame(height: 60)
    }
    
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your ingredients...")
                .foregroundColor(.gray)
                .padding(.top, 16)
            Spacer()
        }
    }
    
    var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Available Ingredients")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.ingredients.filter { $0.isSelected }.count) selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if viewModel.ingredients.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "bag")
                            .font(.system(size: 32))
                            .foregroundColor(Color(.systemGray3))
                        
                        Text("No ingredients found in your lists.\nAdd items to your shopping lists first.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(Color(.systemGray))
                            .padding(.top, 8)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.ingredients) { ingredient in
                            IngredientButton(
                                ingredient: ingredient,
                                isSelected: ingredient.isSelected,
                                action: {
                                    viewModel.toggleIngredientSelection(ingredient: ingredient)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.filterOptions, id: \.self) { filter in
                    Button(action: {
                        viewModel.applyFilter(filter: filter)
                    }) {
                        Text(filter)
                            .font(.subheadline)
                            .fontWeight(viewModel.activeFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.activeFilter == filter ?
                                    Color.green :
                                    Color(.systemBackground)
                            )
                            .foregroundColor(
                                viewModel.activeFilter == filter ?
                                    .white :
                                    .primary
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        viewModel.activeFilter == filter ?
                                            Color.green :
                                            Color(.systemGray4),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
                
                Button(action: {
                    // More filters functionality would go here
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 12))
                        Text("More Filters")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    var recipeSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Recipes")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    VStack {
                        ProgressView()
                        Text("Finding recipes...")
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else if viewModel.suggestedRecipes.isEmpty {
                EmptyRecipesView()
            } else {
                ForEach(viewModel.suggestedRecipes) { recipe in
                                   RecipeCard(recipe: recipe)
                                                   .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.top, 8)
    }
}

struct IngredientButton: View {
    let ingredient: Ingredient
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text(ingredient.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .green : .primary)
                
                Text(ingredient.quantity)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(minWidth: 100, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Color.green.opacity(0.1) :
                    Color(.systemGray6)
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ?
                            Color.green :
                            Color(.systemGray4),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recipe Image
            AsyncImage(url: URL(string: recipe.thumbnail)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 200)
                }
            }
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 12) {
                // Title and Match Percentage
                HStack {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text("\(recipe.matchPercentage)% Match")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            recipe.matchPercentage > 80 ? Color.green.opacity(0.2) :
                                recipe.matchPercentage > 50 ? Color.yellow.opacity(0.2) :
                                Color.red.opacity(0.2)
                        )
                        .foregroundColor(
                            recipe.matchPercentage > 80 ? Color.green :
                                recipe.matchPercentage > 50 ? Color.yellow :
                                Color.red
                        )
                        .cornerRadius(10)
                }
                
                // Category Tags
                HStack {
                    Text(recipe.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Text(recipe.area)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Description
                Text(recipe.instructions.prefix(100) + "...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                // Cook Time and Servings
                HStack {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(recipe.cookTime)
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text("\(recipe.servings) servings")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                
                // View Recipe Button
                Button(action: {
                    // Navigation happens through NavigationLink
                }) {
                    Text("View Recipe")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct EmptyRecipesView: View {
    var body: some View {
        VStack {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(Color(.systemGray3))
                .padding(.bottom, 16)
            
            Text("No recipes found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try selecting different ingredients or check your shopping lists")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Entry point for previews
struct RecipeSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeSuggestionsView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}

