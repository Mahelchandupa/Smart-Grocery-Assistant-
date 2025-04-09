import SwiftUI
import FirebaseFirestore

struct CreateNewListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var listName = ""
    @State private var selectedColor = Color.green
    @State private var dueDate: Date?
    @State private var showDatePicker = false
    
    private let colorOptions = [
        (color: Color.green, name: "Green"),
        (color: Color.blue, name: "Blue"),
        (color: Color.red, name: "Red"),
        (color: Color.orange, name: "Orange"),
        (color: Color.purple, name: "Purple"),
        (color: Color.teal, name: "Teal")
    ]
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.green
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
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // List Name Input
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
                    
                    // Color Selection
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
                    
                    // Due Date Selection
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
            
            // Create Button
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
        .sheet(isPresented: $showDatePicker) {
            DatePicker("Select Date", selection: Binding(
                get: { dueDate ?? Date() },
                set: { dueDate = $0 }
            ), displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .presentationDetents([.medium])
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func handleCreateList() {
        guard !listName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let newList = ShoppingList(
            id: UUID().uuidString,
            name: listName,
            color: selectedColor.toHex(),
            dueDate: dueDate,
            items: [],
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

