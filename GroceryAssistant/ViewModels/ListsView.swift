import SwiftUI

struct ShoppingListsView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @State private var lists: [ShoppingList] = []
    @State private var loading = true
    
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
                        .padding(.trailing, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Lists")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(lists.count) active lists")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "E8F5E9")) // Light green
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 48)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
            }
            .frame(height: 120)
            
            // Main Content
            if loading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(Color(hex: "4CAF50"))
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Shopping Lists")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Lists
                        ForEach(lists) { list in
                            ShoppingListCard(list: list, navPath: $navPath)
                                .padding(.horizontal, 16)
                        }
                        
                        // Empty state
                        if lists.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "9CA3AF"))
                                
                                Text("No shopping lists yet")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "4B5563"))
                                
                                Text("Create your first shopping list to get started")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "6B7280"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button(action: {
                                    navPath.append(Route.createShoppingList)
                                }) {
                                    Text("Create New List")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 220)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "16A34A"))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "F9FAFB"))
            }
        }
        .background(Color(hex: "F9FAFB"))
        .navigationBarHidden(true)
        .onAppear {
            fetchLists()
        }
    }
    
    private func fetchLists() {
        Task {
            do {
                loading = true
                let userLists = try await authManager.getUserLists()
                
                await MainActor.run {
                    self.lists = userLists
                    self.loading = false
                }
            } catch {
                print("Failed to fetch lists: \(error.localizedDescription)")
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }
}

struct ShoppingListCard: View {
    let list: ShoppingList
    @Binding var navPath: NavigationPath
    
    var body: some View {
        Button(action: {
            navPath.append(Route.shoppingListDetail(id: list.id))
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Colored top bar
                Rectangle()
                    .fill(list.displayColor)
                    .frame(height: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(list.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    HStack {
                        Text("\(list.completed)/\(list.totalItems) items")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "6B7280"))
                        
                        Spacer()
                        
                        Text("Due: \(formattedDate(list.updatedAt))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "6B7280"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F3F4F6"))
                            .cornerRadius(16)
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "E5E7EB"))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        if list.totalItems > 0 {
                            Rectangle()
                                .fill(list.displayColor)
                                .frame(width: (CGFloat(list.completed) / CGFloat(list.totalItems)) * (UIScreen.main.bounds.width - 64), height: 8)
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        // If date is today, show "Today"
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        
        return formatter.string(from: date)
    }
}

extension ShoppingList {
    var completed: Int {
        get { items.filter { $0.checked }.count }
        set { }
    }
    
    var totalItems: Int {
        get { items.count }
        set { } 
    }
}

// // Navigation
// extension Route {
//     static func shoppingListDetail(id: String) -> Self {
//         switch id {
//             default: return .userProfile 
//         }
//     }
// }
