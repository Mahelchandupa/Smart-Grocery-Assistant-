// Reminder types
enum ReminderType: String, Codable {
    case list
    case item
    case expiry
}

// Shopping Reminder Model
struct ShoppingReminder: Identifiable, Codable {
    var id: String
    var type: ReminderType
    var title: String
    var listId: String
    var listName: String?
    var itemId: String?
    var date: Date
    var message: String
    var isActive: Bool
    var eventId: String?  // EventKit identifier
    
    // Computed properties for formatting
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}