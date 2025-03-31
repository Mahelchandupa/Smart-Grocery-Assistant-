import SwiftUI

struct HomeView: View {
    @Binding var navPath: NavigationPath
    
    // Sample list data
    @State private var lists = [
        ShoppingList(
            id: 1,
            name: "Weekend Groceries",
            items: 14,
            completed: 5,
            dueDate: "Mar 8",
            color: HexColor(hex: "4CAF50")
        ),
        ShoppingList(
            id: 2,
            name: "Party Supplies",
            items: 8,
            completed: 2,
            dueDate: "Mar 15",
            color: HexColor(hex: "2196F3")
        ),
        ShoppingList(
            id: 3,
            name: "Essentials",
            items: 6,
            completed: 0,
            dueDate: "Today",
            color: HexColor(hex: "F44336")
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Lists")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("3 active lists")
                            .font(.subheadline)
                            .foregroundColor(HexColor(hex: "E8F5E9")) // Light green
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "4CAF50")) // Green background
            .padding(.top, 1) // To match React Native's padding
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(HexColor(hex: "616161")) // Gray-700
                        
                        HStack(spacing: 0) {
                            Spacer()
                            
                            // New List
                            quickActionButton(
                                icon: "plus.circle.fill",
                                color: HexColor(hex: "4CAF50"),
                                bgColor: HexColor(hex: "E8F5E9"),
                                label: "New List",
                                action: {
                                    navPath.append(Route.signIn)
                                }
                            )
                            
                            Spacer()
                            
                            // Grocery Lists
                            quickActionButton(
                                icon: "list.bullet",
                                color: HexColor(hex: "2196F3"),
                                bgColor: HexColor(hex: "E3F2FD"),
                                label: "Grocery Lists",
                                action: {}
                            )
                            
                            Spacer()
                            
                            // Recipes
                            quickActionButton(
                                icon: "fork.knife",
                                color: HexColor(hex: "FF9800"),
                                bgColor: HexColor(hex: "FFF3E0"),
                                label: "Recipes",
                                action: {
                                    navPath.append(Route.nutritionalInfo)
                                }
                            )
                            
                            Spacer()
                            
                            // History
                            quickActionButton(
                                icon: "clock.fill",
                                color: HexColor(hex: "7e22ce"),
                                bgColor: HexColor(hex: "F3E5F5"),
                                label: "History",
                                action: {
                                    // Navigate to history
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
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Your Shopping Lists
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Shopping Lists")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(HexColor(hex: "424242")) // Gray-800
                            .padding(.horizontal, 16)
                        
                        // List items
                        ForEach(lists) { list in
                            shoppingListItem(list)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested For You")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(HexColor(hex: "424242")) // Gray-800
                            .padding(.horizontal, 16)
                        
                        // Suggestions box
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You're running low on:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(HexColor(hex: "616161")) // Gray-700
                            
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
                                        .background(HexColor(hex: "F5F5F5")) // Gray-100
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
                    .padding(.bottom, 16)
                }
            }
            .background(HexColor(hex: "F5F7FA")) // Light gray background
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
    }
    
    // Helper function to create Quick Action buttons
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
                    .foregroundColor(HexColor(hex: "757575")) // Gray-600
            }
        }
    }
    
    // Helper function to create shopping list items
    private func shoppingListItem(_ list: ShoppingList) -> some View {
        Button(action: {
            // Navigate to list detail
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Colored top bar
                Rectangle()
                    .fill(list.color)
                    .frame(height: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(list.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(HexColor(hex: "424242")) // Gray-800
                    
                    HStack {
                        Text("\(list.completed)/\(list.items) items")
                            .font(.system(size: 14))
                            .foregroundColor(HexColor(hex: "757575")) // Gray-600
                        
                        Spacer()
                        
                        Text("Due: \(list.dueDate)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(HexColor(hex: "616161")) // Gray-700
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(HexColor(hex: "F5F5F5")) // Gray-100
                            .cornerRadius(16)
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(HexColor(hex: "EEEEEE")) // Gray-200
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(list.color)
                            .frame(width: CGFloat(list.completed) / CGFloat(list.items) * UIScreen.main.bounds.width * 0.85, height: 8)
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
}