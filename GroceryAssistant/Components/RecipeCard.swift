import SwiftUI

/// A card component displaying a recipe with its details.
///
/// This component shows a recipe's image, name, match percentage,
/// and other key information in a visually appealing card format.
struct RecipeCard: View {
    /// The recipe to display in this card
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