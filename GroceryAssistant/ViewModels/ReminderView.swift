import SwiftUI
import EventKit

struct ReminderView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var reminderManager = ReminderManager()
    @State private var showNewReminderSheet = false
    @State private var newReminderType: ReminderType = .list
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main Content
                if reminderManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reminderManager.reminders.isEmpty {
                    emptyStateView
                } else {
                    reminderListView
                }
            }
        }
        .onAppear {
            reminderManager.requestAccess { granted in
                if granted {
                    Task {
                        await reminderManager.fetchReminders(userId: authManager.currentUser?.uid)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewReminderSheet) {
            NewReminderSheet(
                isPresented: $showNewReminderSheet,
                reminderType: $newReminderType,
                addReminder: { reminder in
                    Task {
                        await reminderManager.addReminder(
                            reminder: reminder,
                            userId: authManager.currentUser?.uid
                        )
                    }
                }
            )
        }
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        ZStack {
            Color.green
            
            VStack {
                HStack {
                    Button(action: {
                        navPath.removeLast()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                            
                            Text("Reminders")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showNewReminderSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.top, 40)
            .padding(.bottom, 16)
        }
        .frame(height: 110)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            Image(systemName: "bell")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("You don't have any reminders yet.\nTap the + button to add your first reminder.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Spacer()
        }
        .padding()
    }
    
    private var reminderListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Active Reminders
                if !reminderManager.activeReminders.isEmpty {
                    Text("Active Reminders")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal)
                    
                    ForEach(reminderManager.activeReminders) { reminder in
                        ReminderCard(
                            reminder: reminder,
                            toggleReminderStatus: { id in
                                Task {
                                    await reminderManager.toggleReminderStatus(
                                        id: id,
                                        userId: authManager.currentUser?.uid
                                    )
                                }
                            },
                            deleteReminder: { id in
                                Task {
                                    await reminderManager.deleteReminder(
                                        id: id,
                                        userId: authManager.currentUser?.uid
                                    )
                                }
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Inactive Reminders
                if !reminderManager.inactiveReminders.isEmpty {
                    Text("Inactive Reminders")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(reminderManager.inactiveReminders) { reminder in
                        ReminderCard(
                            reminder: reminder,
                            toggleReminderStatus: { id in
                                Task {
                                    await reminderManager.toggleReminderStatus(
                                        id: id,
                                        userId: authManager.currentUser?.uid
                                    )
                                }
                            },
                            deleteReminder: { id in
                                Task {
                                    await reminderManager.deleteReminder(
                                        id: id,
                                        userId: authManager.currentUser?.uid
                                    )
                                }
                            }
                        )
                        .padding(.horizontal)
                        .opacity(0.6)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// New Reminder Sheet
struct NewReminderSheet: View {
    @Binding var isPresented: Bool
    @Binding var reminderType: ReminderType
    @EnvironmentObject var authManager: AuthManager
    
    @State private var selectedList: ShoppingList?
    @State private var selectedItem: ShoppingItem?
    @State private var reminderDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var reminderMessage = ""
    @State private var showListPicker = false
    @State private var showItemPicker = false
    @State private var availableLists: [ShoppingList] = []
    @State private var availableItems: [ShoppingItem] = []
    
    let addReminder: (ShoppingReminder) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Reminder Type Selector
                    VStack(alignment: .leading) {
                        Text("Reminder Type")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 0) {
                            typeButton(title: "List", type: .list)
                                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                            
                            typeButton(title: "Item", type: .item)
                                .cornerRadius(8, corners: [.topRight, .bottomRight])
                        }
                        .frame(height: 44)
                    }
                    
                    // List Selection (for both types)
                    VStack(alignment: .leading) {
                        Text("Select List")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Button(action: {
                            Task {
                                // Fetch available lists
                                if let userId = authManager.currentUser?.uid {
                                    do {
                                        availableLists = try await FirestoreService.getUserLists(userId: userId)
                                        showListPicker = true
                                    } catch {
                                        print("Error fetching lists: \(error)")
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Text(selectedList?.name ?? "Choose a list")
                                    .foregroundColor(selectedList != nil ? .black : .gray)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showListPicker) {
                            listPickerView
                        }
                    }
                    
                    // Item Selection (only for item type)
                    if reminderType == .item {
                        VStack(alignment: .leading) {
                            Text("Select Item")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                guard let list = selectedList else { return }
                                
                                Task {
                                    if let userId = authManager.currentUser?.uid {
                                        do {
                                            availableItems = try await FirestoreService.getListItems(userId: userId, listId: list.id)
                                            showItemPicker = true
                                        } catch {
                                            print("Error fetching items: \(error)")
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Text(selectedItem?.name ?? "Choose an item")
                                        .foregroundColor(selectedItem != nil ? .black : .gray)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            }
                            .disabled(selectedList == nil)
                            .opacity(selectedList == nil ? 0.6 : 1)
                            .sheet(isPresented: $showItemPicker) {
                                itemPickerView
                            }
                        }
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading) {
                        Text("Date & Time")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        DatePicker("", selection: $reminderDate)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Message
                    VStack(alignment: .leading) {
                        Text("Reminder Message")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Enter reminder message", text: $reminderMessage)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: selectedList) { _ in
                                updateDefaultMessage()
                            }
                            .onChange(of: selectedItem) { _ in
                                updateDefaultMessage()
                            }
                            .onChange(of: reminderType) { _ in
                                updateDefaultMessage()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Add New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        createNewReminder()
                    }
                    .disabled(!canCreateReminder)
                    .foregroundColor(canCreateReminder ? .green : .gray)
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                updateDefaultMessage()
            }
        }
    }
    
    private var canCreateReminder: Bool {
        if reminderType == .list {
            return selectedList != nil && !reminderMessage.isEmpty
        } else {
            return selectedList != nil && selectedItem != nil && !reminderMessage.isEmpty
        }
    }
    
    private func updateDefaultMessage() {
        if reminderType == .list, let list = selectedList {
            reminderMessage = "Time to shop from \(list.name)!"
        } else if reminderType == .item, let item = selectedItem {
            reminderMessage = "Remember to buy \(item.name)"
        } else if reminderType == .expiry, let item = selectedItem {
            reminderMessage = "\(item.name) will expire soon"
        }
    }
    
    private func createNewReminder() {
        guard let list = selectedList else { return }
        
        let itemId = selectedItem?.id
        let listName = selectedItem?.listName ?? list.name
        
        let reminder = ShoppingReminder(
            id: UUID().uuidString,
            type: reminderType,
            title: reminderType == .list ? list.name : (selectedItem?.name ?? ""),
            listId: list.id,
            listName: listName,
            itemId: itemId,
            date: reminderDate,
            message: reminderMessage,
            isActive: true,
            eventId: nil
        )
        
        addReminder(reminder)
        isPresented = false
    }
    
    // MARK: - Pickers
    
    private var listPickerView: some View {
        NavigationStack {
            List {
                ForEach(availableLists) { list in
                    Button(action: {
                        selectedList = list
                        showListPicker = false
                        
                        // Clear selected item if list changes
                        if reminderType == .item {
                            selectedItem = nil
                        }
                    }) {
                        HStack {
                            Text(list.name)
                            
                            Spacer()
                            
                            if selectedList?.id == list.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showListPicker = false
                    }
                }
            }
        }
    }
    
    private var itemPickerView: some View {
        NavigationStack {
            List {
                ForEach(availableItems) { item in
                    Button(action: {
                        selectedItem = item
                        showItemPicker = false
                    }) {
                        HStack {
                            Text(item.name)
                            
                            Spacer()
                            
                            if selectedItem?.id == item.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Item")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showItemPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func typeButton(title: String, type: ReminderType) -> some View {
        Button(action: {
            reminderType = type
        }) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(reminderType == type ? Color.green.opacity(0.1) : Color(UIColor.systemGray6))
                .foregroundColor(reminderType == type ? .green : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(reminderType == type ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReminderView(navPath: .constant(NavigationPath()))
                .environmentObject(AuthManager())
        }
    }
}