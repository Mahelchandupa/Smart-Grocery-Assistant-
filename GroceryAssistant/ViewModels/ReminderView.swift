import SwiftUI
import EventKit

/// A view that displays and manages reminders for shopping lists and items.
///
/// This view allows users to view their reminders in a calendar view, create new reminders,
/// and manage existing ones. It integrates with the EventKit framework to sync reminders
/// with the system calendar.
struct ReminderView: View {
    /// Navigation path for handling navigation within the app
    @Binding var navPath: NavigationPath
    
    /// Authentication manager for user context and data access
    @EnvironmentObject var authManager: AuthManager
    
    /// Reminder manager for handling reminder operations
    @StateObject private var reminderManager = ReminderManager()
    
    /// Flag to control displaying the new reminder sheet
    @State private var showNewReminderSheet = false
    
    /// Type of new reminder to create
    @State private var newReminderType: ReminderType = .list
    
    /// Environment value for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    /// Currently selected month in the calendar view
    @State private var selectedMonth: Date = Date()
    
    /// Currently selected date in the calendar view
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (fixed at top)
                headerView
                
                // Calendar View
                CalendarMonthView(
                    selectedMonth: $selectedMonth,
                    selectedDate: $selectedDate,
                    reminders: reminderManager.reminders
                )
                .padding(.horizontal)
                
                // Main Content - conditional display based on state
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
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            // Request access to system reminders and fetch user reminders
            reminderManager.requestAccess { granted in
                if granted {
                    Task {
                        await reminderManager.fetchReminders(userId: authManager.currentFirebaseUser?.uid)
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
                            userId: authManager.currentFirebaseUser?.uid
                        )
                    }
                }
            )
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - UI Components
    
    /// Header view with navigation and add button
     private var headerView: some View {
         ZStack {
             Color(Color(hex: "4CAF50")).ignoresSafeArea()
             
             VStack {
                 HStack {
                     Button(action: {
                         dismiss()
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
                                 .foregroundColor(.white)
                         }
                         .frame(width: 36, height: 36)
                     }
                 }
                 .padding(.horizontal)
                 .padding(.top, 8)
             }
             .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 40)
             .padding(.bottom, 16)
         }
         .frame(height: 60 + (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0))
     }
     
    /// Empty state view shown when no reminders exist
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
    
    /// List view showing active and inactive reminders
    private var reminderListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Active Reminders Section
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
                                        userId: authManager.currentFirebaseUser?.uid
                                    )
                                }
                            },
                            deleteReminder: { id in
                                Task {
                                    await reminderManager.deleteReminder(
                                        id: id,
                                        userId: authManager.currentFirebaseUser?.uid
                                    )
                                }
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Inactive Reminders Section
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
                                        userId: authManager.currentFirebaseUser?.uid
                                    )
                                }
                            },
                            deleteReminder: { id in
                                Task {
                                    await reminderManager.deleteReminder(
                                        id: id,
                                        userId: authManager.currentFirebaseUser?.uid
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

// MARK: - New Reminder Sheet

/// A sheet view for creating new reminders.
///
/// This view provides a form for selecting reminder type, list, item,
/// date/time, and adding a message for the reminder.
struct NewReminderSheet: View {
    /// Binding to control sheet presentation
    @Binding var isPresented: Bool
    
    /// Type of reminder to create (list, item, or expiry)
    @Binding var reminderType: ReminderType
    
    /// Authentication manager for user context and data access
    @EnvironmentObject var authManager: AuthManager
    
    /// Currently selected shopping list
    @State private var selectedList: ShoppingList?
    
    /// Currently selected shopping item (for item reminders)
    @State private var selectedItem: ShoppingItem?
    
    /// Date and time for the reminder
    @State private var reminderDate = Date().addingTimeInterval(3600) // 1 hour from now
    
    /// Message text for the reminder
    @State private var reminderMessage = ""
    
    /// Flag to control displaying the list picker sheet
    @State private var showListPicker = false
    
    /// Flag to control displaying the item picker sheet
    @State private var showItemPicker = false
    
    /// Available shopping lists to choose from
    @State private var availableLists: [ShoppingList] = []
    
    /// Available shopping items to choose from
    @State private var availableItems: [ShoppingItem] = []
    
    /// Flag indicating whether lists are being fetched
    @State private var isFetchingLists = false
    
    /// Callback to add the created reminder
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
                                isFetchingLists = true
                                if let userId = authManager.currentFirebaseUser?.uid {
                                    do {
                                        availableLists = try await FirestoreService.getUserLists(userId: userId)
                                        showListPicker = true
                                    } catch {
                                        print("Error fetching lists: \(error)")
                                    }
                                }
                                isFetchingLists = false
                            }
                        }) {
                            HStack {
                                if isFetchingLists {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(width: 20, height: 20)
                                } else {
                                    Text(selectedList?.name ?? "Choose a list")
                                        .foregroundColor(selectedList != nil ? .black : .gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                        .disabled(isFetchingLists) // Prevent tapping while loading
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
                                    if let userId = authManager.currentFirebaseUser?.uid {
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
                            .onChange(of: selectedList) { oldValue, newValue in
                                updateDefaultMessage()
                            }
                            .onChange(of: selectedItem) { oldValue, newValue in
                                updateDefaultMessage()
                            }
                            .onChange(of: reminderType) { oldValue, newValue in
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
    
    /// Determines if a reminder can be created based on selected values
    private var canCreateReminder: Bool {
        if reminderType == .list {
            return selectedList != nil && !reminderMessage.isEmpty
        } else {
            return selectedList != nil && selectedItem != nil && !reminderMessage.isEmpty
        }
    }
    
    /// Updates the default reminder message based on selected type, list, and item
    private func updateDefaultMessage() {
        if reminderType == .list, let list = selectedList {
            reminderMessage = "Time to shop from \(list.name)!"
        } else if reminderType == .item, let item = selectedItem {
            reminderMessage = "Remember to buy \(item.name)"
        } else if reminderType == .expiry, let item = selectedItem {
            reminderMessage = "\(item.name) will expire soon"
        }
    }
    
    /// Creates a new reminder with the selected options
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
    
    /// View for selecting a shopping list
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
    
    /// View for selecting a shopping item from the selected list
    private var itemPickerView: some View {
        NavigationStack {
            List {
                ForEach(availableItems) { item in
                    Button(action: {
                        // Create a copy of the item with the listName set
                        var updatedItem = item
                        updatedItem.listName = selectedList?.name
                        selectedItem = updatedItem
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
    
    /// Creates a button for selecting reminder type
    /// - Parameters:
    ///   - title: The button label text
    ///   - type: The reminder type this button represents
    /// - Returns: A styled button view
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

// MARK: - Calendar Components

/// A view that displays a monthly calendar with reminders.
///
/// This component shows a month view with days of the week and highlights
/// days that have reminders. It allows navigation between months and
/// selecting specific dates.
struct CalendarMonthView: View {
    /// Currently selected month to display
    @Binding var selectedMonth: Date
    
    /// Currently selected date in the calendar
    @Binding var selectedDate: Date
    
    /// Array of reminders to display in the calendar
    let reminders: [ShoppingReminder]
    
    /// Calendar used for date calculations
    private let calendar = Calendar.current
    
    /// Short day names for the calendar header
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack {
            // Month header with navigation
            HStack {
                Text(monthYearFormatter.string(from: selectedMonth))
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        selectedMonth = Date()
                        selectedDate = Date()
                    }) {
                        Text("Today")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.bottom, 5)
            
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(day == "S" ? .red : .primary)
                }
            }
            .padding(.bottom, 5)
            
            // Calendar grid of days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            isToday: isToday(date),
                            hasReminders: hasReminders(on: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        // Empty day (placeholder for days from other months)
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    /// Formatter for displaying month and year
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    /// Generates an array of dates for the current month view
    /// - Returns: Array of optional dates (nil for empty cells)
    private func days() -> [Date?] {
        let firstDayOfMonth = firstDay(of: selectedMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)!.count
        
        // Get weekday of first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var days = [Date?]()
        
        // Add empty slots for days before the first day of month
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Fill the remaining days to complete the grid (42 = 6 weeks) or at least 35 (5 weeks)
        let targetCount = days.count <= 35 ? 35 : 42
        while days.count < targetCount {
            days.append(nil)
        }
        
        return days
    }
    
    /// Gets the first day of a month
    /// - Parameter date: Any date in the month
    /// - Returns: Date representing the first day of the month
    private func firstDay(of date: Date) -> Date {
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    
    /// Checks if two dates are the same day
    /// - Parameters:
    ///   - date1: First date to compare
    ///   - date2: Second date to compare
    /// - Returns: True if dates are on the same day
    private func isSameDay(_ date1: Date?, _ date2: Date?) -> Bool {
        guard let date1 = date1, let date2 = date2 else { return false }
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Checks if a date is today
    /// - Parameter date: Date to check
    /// - Returns: True if the date is today
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    /// Checks if there are any active reminders on a specific date
    /// - Parameter date: Date to check
    /// - Returns: True if there are active reminders on this date
    private func hasReminders(on date: Date) -> Bool {
        return reminders.contains { reminder in
            reminder.isActive && calendar.isDate(reminder.date, inSameDayAs: date)
        }
    }
    
    /// Navigates to the previous month
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
    
    /// Navigates to the next month
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

/// A view representing a single day in the calendar.
struct CalendarDayView: View {
    /// The date this view represents
    let date: Date
    
    /// Whether this date is currently selected
    let isSelected: Bool
    
    /// Whether this date is today
    let isToday: Bool
    
    /// Whether this date has active reminders
    let hasReminders: Bool
    
    /// Calendar used for date calculations
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(height: 40)
            
            VStack {
                Text("\(dayNumber)")
                    .foregroundColor(textColor)
                    .font(.system(size: 16))
                
                if hasReminders {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
    
    /// Day number extracted from the date
    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }
    
    /// Whether the date falls on a weekend
    private var isWeekend: Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    /// Background color based on selected and today states
    private var backgroundColor: Color {
        if isSelected {
            return .green
        } else if isToday {
            return Color.green.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    /// Text color based on selected and weekend states
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isWeekend {
            return .red
        } else {
            return .primary
        }
    }
}

/// Preview provider for ReminderView
struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ReminderView(navPath: .constant(NavigationPath()))
                .environmentObject(AuthManager())
        }
    }
}