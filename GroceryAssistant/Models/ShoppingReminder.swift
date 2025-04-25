// MARK: - Reminder Models

import SwiftUI

/// Types of reminders supported in the application.
enum ReminderType: String, Codable {
    case list
    case item
    case expiry
}

/// Model representing a shopping reminder with details about what to remind and when.
struct ShoppingReminder: Identifiable, Codable {
    var id: String
    var type: ReminderType
    var title: String
    var listId: String
    var listName: String?
    var itemId: String?
    /// Date and time when the reminder should trigger
    var date: Date
    var message: String
    /// Whether the reminder is currently active
    var isActive: Bool
    var eventId: String?
    
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