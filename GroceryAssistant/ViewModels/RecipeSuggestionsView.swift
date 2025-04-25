import SwiftUI

/// A view that suggests recipes based on available ingredients.
///
/// This view displays a list of available ingredients from the user's shopping lists,
/// allows filtering by recipe type, and shows recipe suggestions with match percentages.
struct RecipeSuggestionsView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Authentication manager for user context
    @EnvironmentObject var authManager: AuthManager
    
    /// View model that handles recipe suggestion logic and API calls
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
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Component Views
    
    /// Header view with navigation and title
    var headerView: some View {
        ZStack {
            Color(hex: "4CAF50")
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
    
    /// Loading indicator view displayed while fetching data
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
    
    /// Section displaying available ingredients with selection functionality
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
    
    /// Section with filtering options for recipes
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
    
    /// Section displaying recipe suggestions based on selected ingredients
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

/// A button for selecting/deselecting an ingredient.
///
/// This component displays an ingredient with its name and quantity,
/// and allows toggling its selection state for recipe filtering.
struct IngredientButton: View {
    /// The ingredient this button represents
    let ingredient: Ingredient
    
    /// Whether the ingredient is currently selected
    let isSelected: Bool
    
    /// Action to perform when the button is tapped
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

/// A view displayed when no recipes match the current filter criteria.
///
/// This component shows a friendly message when no recipes are found,
/// and suggests actions the user can take to find recipes.
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

/// Preview provider for RecipeSuggestionsView
struct RecipeSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeSuggestionsView(navPath: .constant(NavigationPath()))
            .environmentObject(AuthManager())
    }
}