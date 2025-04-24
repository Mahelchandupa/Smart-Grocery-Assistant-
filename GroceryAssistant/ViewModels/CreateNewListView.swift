import SwiftUI
import FirebaseFirestore

/// A view for creating a new shopping list.
///
/// This view provides an interface for users to enter a list name,
/// select a color, and optionally set a due date for a new shopping list.
struct CreateNewListView: View {
    /// Authentication manager for user context and Firestore operations
    @EnvironmentObject var authManager: AuthManager
    
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath

    /// Environment dismiss action for dismissing the view
    @Environment(\.dismiss) var dismiss
    
    /// Name of the shopping list being created
    @State private var listName: String = ""
    
    /// Selected color for the shopping list
    @State private var selectedColor = Color.green
    
    /// Optional due date for the shopping list
    @State private var dueDate: Date?
    
    /// Flag indicating whether the date picker is shown
    @State private var showDatePicker = false
    
    /// Available color options for the shopping list
    private let colorOptions = [
        (color: Color.green, name: "Green"),
        (color: Color.blue, name: "Blue"),
        (color: Color.red, name: "Red"),
        (color: Color.orange, name: "Orange"),
        (color: Color.purple, name: "Purple"),
        (color: Color.teal, name: "Teal")
    ]
        
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation header
            ZStack {
                Color(hex: "4CAF50")
                    .ignoresSafeArea()
                    .frame(height: 60)
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .padding(.leading, 16)
                    
                    Text("Create a List")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
            }
            
            // Form content
            ScrollView {
                VStack(spacing: 24) {
                    // List name input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("List Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.darkGray))
                        
                        TextField("Enter list name", text: $listName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    
                    // Color selection grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.darkGray))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                            ForEach(colorOptions, id: \.name) { option in
                                Button(action: {
                                    selectedColor = option.color
                                }) {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(option.color)
                                                .frame(width: 56, height: 56)
                                            
                                            if selectedColor == option.color {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 24))
                                            }
                                        }
                                        
                                        Text(option.name)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Due date selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.darkGray))
                        
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text(dueDate != nil ? formattedDate(dueDate!) : "Select a due date (optional)")
                                    .foregroundColor(dueDate != nil ? .primary : .gray)
                                
                                Spacer()
                                
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            
            // Create button
            Button(action: handleCreateList) {
                Text("Create List")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(listName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.green)
                    .cornerRadius(8)
            }
            .disabled(listName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding()
        }
        .navigationBarHidden(true)

        .sheet(isPresented: $showDatePicker) {
            DatePicker("Select Date", selection: Binding(
                get: { dueDate ?? Date() },
                set: { dueDate = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .presentationDetents([.medium])
        }
    }
    
    /// Formats a date into a user-friendly string.
    /// - Parameter date: The date to format
    /// - Returns: A formatted date string (e.g., "Jan 1, 2023")
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Creates a new shopping list and saves it to Firestore.
    ///
    /// This method validates the list name, creates a ShoppingList object with
    /// the user-selected properties, and saves it using the AuthManager.
    private func handleCreateList() {
        guard !listName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newList = ShoppingList(
            id: UUID().uuidString,
            name: listName,
            color: selectedColor.toHex() ?? "#000000",
            dueDate: dueDate,
            totalItems: 0,
            completedItems: 0
        )
        
        Task {
            do {
                try await authManager.createList(newList)
                dismiss()
            } catch {
                print("Error creating list: \(error.localizedDescription)")
            }
        }
    }
}