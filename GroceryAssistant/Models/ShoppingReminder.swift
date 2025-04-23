// MARK: - Reminder Models

import SwiftUI

/// Types of reminders supported in the application.
enum ReminderType: String, Codable {
    /// Reminder for a shopping list
    case list
    
    /// Reminder for a specific item
    case item
    
    /// Reminder for item expiration
    case expiry
}

/// Model representing a shopping reminder with details about what to remind and when.
struct ShoppingReminder: Identifiable, Codable {
    /// Unique identifier for the reminder
    var id: String
    
    /// Type of reminder (list, item, or expiry)
    var type: ReminderType
    
    /// Title of the reminder
    var title: String
    
    /// ID of the shopping list associated with this reminder
    var listId: String
    
    /// Optional name of the shopping list
    var listName: String?
    
    /// Optional ID of a specific item if this is an item reminder
    var itemId: String?
    
    /// Date and time when the reminder should trigger
    var date: Date
    
    /// Message content of the reminder
    var message: String
    
    /// Whether the reminder is currently active
    var isActive: Bool
    
    /// Optional EventKit identifier to link with system reminders
    var eventId: String?
    
    /// Formatted date string (e.g., "Jan 1, 2024")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    /// Formatted time string (e.g., "3:30 PM")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}