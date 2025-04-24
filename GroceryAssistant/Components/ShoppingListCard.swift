import SwiftUI

/// A reusable card component that displays a shopping list with its details.
///
/// This component shows a shopping list's name, completion status, due date,
/// and a visual progress bar. It's designed to be used in lists of shopping lists
/// and supports navigation to the list's detail view.
struct ShoppingListCard: View {
    /// The shopping list to display
    let list: ShoppingList
    
    /// Navigation path for handling navigation to list details
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
    
    /// Colored bar at the top of the card matching the list's color
    private var colorBar: some View {
        Rectangle()
            .fill(Color(hex: list.color))
            .frame(height: 8)
    }
    
    /// Main content section containing list information
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
    
    /// Statistics row showing completion status and due date
    private var listStats: some View {
        HStack {
            Text("\(list.completedItems)/\(list.totalItems) items")
                .font(.subheadline)
                .foregroundColor(Color(hex: "6B7280"))
            
            Spacer()
            
            dueDateBadge
        }
    }
    
    /// Badge displaying the list's due date
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
    
    /// Progress bar showing completion status
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
    
    /// Formats a date for display in the due date badge
    /// - Parameter date: The date to format
    /// - Returns: A formatted date string (e.g., "Today", "Apr 20")
    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Example: "Apr 20"
        return formatter.string(from: date)
    }
}