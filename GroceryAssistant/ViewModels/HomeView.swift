import SwiftUI

struct HomeView: View {
    @Binding var navPath: NavigationPath
    @State private var lists: [ShoppingList] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Lists")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(lists.count) active lists")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "E8F5E9")) // Light green
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
                            .foregroundColor(Color(hex: "616161")) // Gray-700
                        
                        HStack(spacing: 0) {
                            Spacer()
                            
                            // New List
                            quickActionButton(
                                icon: "plus.circle.fill",
                                color: Color(hex: "4CAF50"),
                                bgColor: Color(hex: "E8F5E9"),
                                label: "New List",
                                action: {
                                    navPath.append(Route.signIn)
                                }
                            )
                            
                            Spacer()
                            
                            // Grocery Lists
                            quickActionButton(
                                icon: "list.bullet",
                                color: Color(hex: "2196F3"),
                                bgColor: Color(hex: "E3F2FD"),
                                label: "Grocery Lists",
                                action: {}
                            )
                            
                            Spacer()
                            
                            // Recipes
                            quickActionButton(
                                icon: "fork.knife",
                                color: Color(hex: "FF9800"),
                                bgColor: Color(hex: "FFF3E0"),
                                label: "Recipes",
                                action: {
                                    navPath.append(Route.nutritionalInfo)
                                }
                            )
                            
                            Spacer()
                            
                            // History
                            quickActionButton(
                                icon: "clock.fill",
                                color: Color(hex: "7e22ce"),
                                bgColor: Color(hex: "F3E5F5"),
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
                        HStack {
                            Text("Your Shopping Lists")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "424242")) // Gray-800
                            
                            Spacer()
                            
                            Button(action: {
                                // Navigate to all lists
                            }) {
                                Text("See All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "4CAF50"))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Show up to 3 list items
                        ForEach(Array(lists.prefix(3))) { list in
                            shoppingListItem(list)
                                .padding(.horizontal, 16)
                        }
                        
                        // Show empty state if no lists
                        if lists.isEmpty {
                            emptyListsView
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested For You")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "424242")) // Gray-800
                            .padding(.horizontal, 16)
                        
                        // Suggestions box
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You're running low on:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "616161")) // Gray-700
                            
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
                                        .background(Color(hex: "F5F5F5")) // Gray-100
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
                    .padding(.bottom, 100) // Add extra padding for tab bar
                }
            }
            .background(Color(hex: "F5F7FA")) // Light gray background
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .onAppear {
            loadSampleData()
        }
    }
    
    // Empty lists view
    private var emptyListsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundColor(Color.gray.opacity(0.7))
            
            Text("No shopping lists yet")
                .font(.headline)
                .foregroundColor(Color.gray)
            
            Button(action: {
                // Navigate to create new list
                navPath.append(Route.signIn)
            }) {
                Text("Create Your First List")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "4CAF50"))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
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
                    .foregroundColor(Color(hex: "757575")) // Gray-600
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
                    .fill(list.displayColor)
                    .frame(height: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(list.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "424242")) // Gray-800
                    
                    HStack {
                        Text("\(completedItemsCount(for: list))/\(list.items.count) items")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "757575")) // Gray-600
                        
                        Spacer()
                        
                        Text("Due: \(formattedDate(for: list))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "616161")) // Gray-700
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F5F5F5")) // Gray-100
                            .cornerRadius(16)
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "EEEEEE")) // Gray-200
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        if !list.items.isEmpty {
                            Rectangle()
                                .fill(list.displayColor)
                                .frame(width: CGFloat(completedItemsCount(for: list)) / CGFloat(list.items.count) * (UIScreen.main.bounds.width - 64), height: 8)
                                .cornerRadius(4)
                        }
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
    
    // Helper function to count completed items in a list
    private func completedItemsCount(for list: ShoppingList) -> Int {
        list.items.filter { $0.checked }.count
    }
    
    // Helper function to format the date
    private func formattedDate(for list: ShoppingList) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        // If date is today, show "Today"
        if Calendar.current.isDateInToday(list.updatedAt) {
            return "Today"
        }
        
        return formatter.string(from: list.updatedAt)
    }
    
    // Load sample data
    private func loadSampleData() {
        // Create some sample shopping lists
        let sampleLists = [
            ShoppingList(
                id: UUID().uuidString,
                name: "Weekend Groceries",
                color: "4CAF50", // Green
                items: [
                    ShoppingItem(id: UUID().uuidString, name: "Milk", quantity: 1, checked: false, category: "Dairy", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Eggs", quantity: 12, checked: true, category: "Dairy", note: "Free range", createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Bread", quantity: 1, checked: false, category: "Bakery", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Apples", quantity: 6, checked: true, category: "Fruits", note: "Gala preferred", createdAt: Date(), updatedAt: Date())
                ],
                createdAt: Date(),
                updatedAt: Date()
            ),
            ShoppingList(
                id: UUID().uuidString,
                name: "Party Supplies",
                color: "2196F3", // Blue
                items: [
                    ShoppingItem(id: UUID().uuidString, name: "Napkins", quantity: 50, checked: false, category: "Supplies", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Cups", quantity: 24, checked: true, category: "Supplies", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Soda", quantity: 6, checked: false, category: "Beverages", note: "Diet too", createdAt: Date(), updatedAt: Date())
                ],
                createdAt: Date(),
                updatedAt: Date()
            ),
            ShoppingList(
                id: UUID().uuidString,
                name: "Essentials",
                color: "F44336", // Red
                items: [
                    ShoppingItem(id: UUID().uuidString, name: "Soap", quantity: 2, checked: false, category: "Hygiene", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Toilet Paper", quantity: 1, checked: false, category: "Household", note: "12 pack", createdAt: Date(), updatedAt: Date())
                ],
                createdAt: Date(),
                updatedAt: Date()
            ),
            ShoppingList(
                id: UUID().uuidString,
                name: "Office Supplies",
                color: "9C27B0", // Purple
                items: [
                    ShoppingItem(id: UUID().uuidString, name: "Notebooks", quantity: 3, checked: false, category: "Stationery", note: nil, createdAt: Date(), updatedAt: Date()),
                    ShoppingItem(id: UUID().uuidString, name: "Pens", quantity: 10, checked: false, category: "Stationery", note: nil, createdAt: Date(), updatedAt: Date())
                ],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        lists = sampleLists
    }
}

// Extension for previews
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(navPath: .constant(NavigationPath()))
    }
}
