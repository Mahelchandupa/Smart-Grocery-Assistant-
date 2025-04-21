import SwiftUI

struct ListsView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @State private var lists: [ShoppingList] = []
    @State private var loading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(hex: "16A34A")
                    .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 4) {
                    HStack {
                        Button(action: {
                            if navPath.count > 0 {
                                navPath.removeLast()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Lists")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(lists.count) active lists")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "E8F5E9"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.top, 25)
                .padding(.bottom, 20)
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            mainContent
        }
        .background(Color(hex: "F9FAFB"))
        .navigationBarHidden(true)
        .onAppear {
            fetchLists()
        }
    }
    
    // MARK: - Main Components
    
    private var mainContent: some View {
        Group {
            if loading {
                loadingView
            } else {
                listsContent
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(hex: "4CAF50"))
            Spacer()
        }
    }
    
    private var listsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Shopping Lists")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1F2937"))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                if lists.isEmpty {
                    emptyStateView
                } else {
                    listsView
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(hex: "F9FAFB"))
    }
    
    private var listsView: some View {
        ForEach(lists) { list in
            ShoppingListCard(list: list, navPath: $navPath)
                .padding(.horizontal, 16)
        }
    }
    
    private var emptyStateView: some View {
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
            
            createNewListButton
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var createNewListButton: some View {
        Button(action: {
            navPath.append(Route.createNewList)
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
    
    // MARK: - Data Fetching
    
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
            navPath.append(Route.listDetail(id: list.id))
        }) {
            VStack(alignment: .leading, spacing: 0) {
                colorBar
                contentSection
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 8)
    }
    
    // MARK: - Component Views
    
    private var colorBar: some View {
        Rectangle()
            .fill(Color(hex: list.color))
            .frame(height: 8)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "1F2937"))
            
            listStats
            progressBar
        }
        .padding(16)
    }
    
    private var listStats: some View {
        HStack {
            Text("\(list.completedItems)/\(list.totalItems) items")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6B7280"))
            
            Spacer()
            
            dueDateBadge
        }
    }
    
    private var dueDateBadge: some View {
        Text("Due: \(list.dueDate != nil ? formattedDate(list.dueDate!) : "No due date")")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(Color(hex: "6B7280"))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(hex: "F3F4F6"))
            .cornerRadius(16)
    }
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color(hex: "E5E7EB"))
                .frame(height: 8)
                .cornerRadius(4)
            
            if list.totalItems > 0 {
                let progressWidth = (CGFloat(list.completedItems) / CGFloat(list.totalItems)) * (UIScreen.main.bounds.width - 64)
                
                Rectangle()
                    .fill(Color(list.color))
                    .frame(width: progressWidth, height: 8)
                    .cornerRadius(4)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Example: "Apr 20"
        return formatter.string(from: date)
    }
}
