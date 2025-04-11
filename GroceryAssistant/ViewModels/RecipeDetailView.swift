import SwiftUI
import SafariServices

struct RecipeDetailView: View {
    let recipeId: String
    @Binding var navPath: NavigationPath
    @State private var recipe: RecipeSuggestion?
    @State private var loading = true
    @State private var isFavorite = false
    @State private var showingSafariView = false
    @State private var urlToOpen: URL?
    
    var body: some View {
        if loading {
            loadingView
        } else if let recipe = recipe {
            recipeView(recipe)
        } else {
            notFoundView
        }
    }
    
    // Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "22c55e"))
            
            Text("Loading recipe...")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6B7280"))
                .padding(.top, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F9FAFB"))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadRecipeDetails()
        }
    }
    
    // Not Found View
    private var notFoundView: some View {
        VStack(spacing: 16) {
            Text("Recipe Not Found")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "1F2937"))
            
            Text("We couldn't find the recipe you're looking for.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: {
                navPath.removeLast()
            }) {
                Text("Go Back")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "22c55e"))
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F9FAFB"))
        .edgesIgnoringSafeArea(.all)
    }
    
    // Recipe View
    private func recipeView(_ recipe: RecipeSuggestion) -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Image
                    ZStack(alignment: .topLeading) {
                        // Recipe image
                        AsyncImage(url: URL(string: recipe.thumbnail)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 224)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .cover)
                                    .frame(height: 224)
                            case .failure:
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 224)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(Color(hex: "9CA3AF"))
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(height: 224)
                            }
                        }
                    }
                    
                    // Overlay buttons
                    VStack {
                        HStack {
                            Button(action: {
                                navPath.removeLast()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            // Favorite and share buttons
                            HStack(spacing: 8) {
                                Button(action: {
                                    toggleFavorite()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                                            .font(.system(size: 20))
                                            .foregroundColor(isFavorite ? Color(hex: "ef4444") : .white)
                                    }
                                }
                                
                                Button(action: {
                                    shareRecipe()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .offset(y: -180)
                    }
                    
                    // Recipe Title and Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "1F2937"))
                        
                        // Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                TagPill(title: recipe.category)
                                TagPill(title: "\(recipe.area) Cuisine")
                                
                                // Additional tags
                                ForEach(recipe.tags, id: \.self) { tag in
                                    TagPill(title: tag)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "E5E7EB")),
                        alignment: .bottom
                    )
                    
                    // Recipe Info Cards
                    HStack(spacing: 0) {
                        // Prep Time
                        InfoCard(
                            icon: "clock",
                            title: "Prep Time",
                            value: recipe.prepTime
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(hex: "E5E7EB")),
                            alignment: .trailing
                        )
                        
                        // Cook Time
                        InfoCard(
                            icon: "clock",
                            title: "Cook Time",
                            value: recipe.cookTime
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(hex: "E5E7EB")),
                            alignment: .trailing
                        )
                        
                        // Servings
                        InfoCard(
                            icon: "person.2",
                            title: "Servings", 
                            value: "\(recipe.servings)"
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(hex: "E5E7EB")),
                            alignment: .trailing
                        )
                        
                        // Calories
                        VStack(spacing: 4) {
                            Text("\(recipe.calories)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "1F2937"))
                            
                            Text("Calories")
                                .font(.caption)
                                .foregroundColor(Color(hex: "6B7280"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)
                    
                    // Actions
                    HStack(spacing: 0) {
                        // Add to List
                        ActionButton(
                            icon: "bag",
                            title: "Add to List",
                            color: Color(hex: "22c55e"),
                            action: {
                                addIngredientsToList()
                            }
                        )
                        
                        // Watch Video
                        if recipe.youtubeUrl != nil {
                            ActionButton(
                                icon: "play.fill",
                                title: "Watch Video",
                                color: Color(hex: "ef4444"),
                                action: {
                                    openVideo(recipe.youtubeUrl)
                                }
                            )
                        }
                        
                        // Source (if available)
                        if recipe.sourceUrl != nil {
                            ActionButton(
                                icon: "globe",
                                title: "Source",
                                color: Color(hex: "3b82f6"),
                                action: {
                                    openSource(recipe.sourceUrl)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "E5E7EB")),
                        alignment: .top
                    )
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "E5E7EB")),
                        alignment: .bottom
                    )
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.bottom, 4)
                        
                        // Ingredients list
                        ForEach(recipe.allIngredients) { ingredient in
                            HStack(alignment: .center, spacing: 8) {
                                // Bullet
                                Circle()
                                    .fill(Color(hex: "22c55e"))
                                    .frame(width: 8, height: 8)
                                
                                // Ingredient name and measure
                                Text(ingredient.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "1F2937"))
                                
                                Spacer()
                                
                                if !ingredient.measure.isEmpty {
                                    Text(ingredient.measure)
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "6B7280"))
                                }
                            }
                            .padding(.vertical, 8)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(hex: "F3F4F6")),
                                alignment: .bottom
                            )
                        }
                        
                        // Add to shopping list button
                        Button(action: {
                            addIngredientsToList()
                        }) {
                            Text("Add Missing Ingredients to Shopping List")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "22c55e"))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Instructions")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.bottom, 4)
                        
                        ForEach(formatInstructions(recipe.instructions), id: \.id) { step in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "22c55e"))
                                            .frame(width: 24, height: 24)
                                        
                                        Text("\(step.id)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Step \(step.id)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: "1F2937"))
                                }
                                
                                Text(step.text)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "4B5563"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(hex: "F3F4F6")),
                                alignment: .bottom
                            )
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(hex: "F9FAFB"))
            .edgesIgnoringSafeArea(.top)
            
            // Safari view if needed
            if showingSafariView, let url = urlToOpen {
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationBarHidden(true)
    }
    
    // Helper Methods
    private func formatInstructions(_ instructions: String) -> [InstructionStep] {
        let steps = instructions
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return steps.enumerated().map { index, text in
            InstructionStep(id: index + 1, text: String(text))
        }
    }
    
    private func loadRecipeDetails() {
        Task {
            do {
                let recipe = try await RecipeService.getRecipeDetails(id: recipeId)
                
                await MainActor.run {
                    self.recipe = recipe
                    self.loading = false
                }
            } catch {
                print("Error loading recipe details: \(error.localizedDescription)")
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }
    
    // Actions
    private func toggleFavorite() {
        isFavorite.toggle()
        let title = isFavorite ? "Added to Favorites" : "Removed from Favorites"
        let message = isFavorite 
            ? "This recipe has been added to your favorites"
            : "This recipe has been removed from your favorites"
        
        showAlert(title: title, message: message)
    }
    
    private func shareRecipe() {
        showAlert(title: "Share", message: "Recipe sharing functionality would be implemented here")
    }
    
    private func addIngredientsToList() {
        guard let recipe = recipe else { return }
        
        // Present an alert with options
        showActionSheet(
            title: "Add to Shopping List",
            message: "Which ingredients would you like to add to your shopping list?",
            options: [
                AlertOption(title: "All Ingredients", action: {
                    showAlert(title: "Success", message: "All ingredients have been added to your shopping list")
                }),
                AlertOption(title: "Missing Only", action: {
                    showAlert(title: "Success", message: "Missing ingredients have been added to your shopping list")
                })
            ]
        )
    }
    
    private func openVideo(_ urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        urlToOpen = url
        showingSafariView = true
    }
    
    private func openSource(_ urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        urlToOpen = url
        showingSafariView = true
    }
    
    // Alert helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func showActionSheet(title: String, message: String, options: [AlertOption]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for option in options {
            alert.addAction(UIAlertAction(title: option.title, style: .default) { _ in
                option.action()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

//  Supporting Views
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "4B5563"))
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "4B5563"))
            
            Text(value)
                .font(.caption)
                .foregroundColor(Color(hex: "6B7280"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(hex: "4B5563"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct AlertOption {
    let title: String
    let action: () -> Void
}

// SafariView for opening web links
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}

// Preview
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipeId: "52772", navPath: .constant(NavigationPath()))
    }
}

// Navigation helper
extension Route {
    static func recipeDetail(id: String) -> Self {
        switch id {
            navPath(recipeDetail(id))
        }
    }
}