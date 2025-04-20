import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var navPath: NavigationPath
    
    @State private var lists: [ShoppingList] = []
    @State private var activeListCount = 0
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Lists")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(activeListCount) active lists")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "E8F5E9"))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            // Handle notification tap
                        }) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            navPath.append(Route.profile)
                        }) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 8)
            }
            .frame(height: 120)
            .background(Color(hex: "4CAF50"))
            
            // Main Content
            ScrollView {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4CAF50")))
                        .scaleEffect(1.5)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        // Quick Actions
                        quickActionsSection()
                            .padding(.top, 16)
                        
                        // Your Shopping Lists
                        shoppingListsSection()
                        
                        // Suggestions
                        suggestionsSection()
                            .padding(.bottom, 16)
                    }
                }
            }
            .background(Color(hex: "F5F7FA"))
            .refreshable {
                await fetchLists()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .task {
            await fetchLists()
        }
    }
    
    // View Components
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "616161"))
            
            HStack(spacing: 0) {
                Spacer()
                
                quickActionButton(
                    icon: "plus.circle.fill",
                    color: Color(hex: "4CAF50"),
                    bgColor: Color(hex: "E8F5E9"),
                    label: "New List",
                    action: {
                        navPath.append(Route.createNewList)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "list.bullet",
                    color: Color(hex: "2196F3"),
                    bgColor: Color(hex: "E3F2FD"),
                    label: "Grocery Lists",
                    action: {
                        navPath.append(Route.lists)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "fork.knife",
                    color: Color(hex: "FF9800"),
                    bgColor: Color(hex: "FFF3E0"),
                    label: "Recipes",
                    action: {
                        navPath.append(Route.recipes)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "clock.fill",
                    color: Color(hex: "7e22ce"),
                    bgColor: Color(hex: "F3E5F5"),
                    label: "History",
                    action: {
                        navPath.append(Route.history)
                    }
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    private func shoppingListsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Shopping Lists")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "424242"))
                .padding(.horizontal, 16)
            
            ForEach(lists) { list in
                shoppingListItem(list)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
    
    private func suggestionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested For You")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "424242"))
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You're running low on:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "616161"))
                
                HStack(spacing: 8) {
                    ForEach(["Milk", "Eggs", "Bread"], id: \.self) { item in
                        Button(action: {
                            // Add item to list
                        }) {
                            HStack(spacing: 2) {
                                Text("+ \(item)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "616161"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
    }
    
    // Helper Views   
    private func quickActionButton(icon: String, color: Color, bgColor: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(bgColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "757575"))
            }
        }
    }
    
    private func shoppingListItem(_ list: ShoppingList) -> some View {
        Button(action: {
            navPath.append(Route.listDetail(id: list.id))
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color(hex: list.color))
                    .frame(height: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(list.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "424242"))
                    
                    HStack {
                        Text("\(list.completedItems)/\(list.items.count) items")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "757575"))
                        
                        Spacer()
                        
                        if let dueDate = list.dueDate {
                            Text("Due: \(dueDate.formattedMediumDate())") 
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "616161"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(hex: "F5F5F5"))
                                .cornerRadius(16)
                        }
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "EEEEEE"))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        let progress = list.items.isEmpty ? 0 : CGFloat(list.completedItems) / CGFloat(list.items.count)
                        Rectangle()
                            .fill(Color(hex: list.color))
                            .frame(width: progress * (UIScreen.main.bounds.width - 64), height: 8)
                            .cornerRadius(4)
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .padding(.bottom, 16)
    }
    
    private func fetchLists() async {
        isLoading = true
        do {
            let fetchedLists = try await authManager.getUserLists()
            self.lists = Array(fetchedLists.prefix(3))
            self.activeListCount = fetchedLists.count
        } catch {
            print("Error fetching lists: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
