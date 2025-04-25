import Foundation
import UIKit
import EventKit
import UserNotifications

/// A manager class that handles all reminder-related operations in the application.
/// This includes creating, updating, and deleting reminders both in the EventKit system
/// and in Firestore, as well as scheduling local notifications for reminders.
class ReminderManager: ObservableObject {
    /// The EventKit event store used for system calendar and reminder operations
    private let eventStore = EKEventStore()

    /// All reminders for the current user
    @Published var reminders: [ShoppingReminder] = []

    /// Indicates whether reminders are currently being loaded
    @Published var isLoading: Bool = false
    
    /// Filtered array of active reminders
    var activeReminders: [ShoppingReminder] {
        reminders.filter { $0.isActive }
    }

    /// Filtered array of inactive reminders
    var inactiveReminders: [ShoppingReminder] {
        reminders.filter { !$0.isActive }
    }
    
    /// Requests access to Calendar/Reminders and Notifications.
    /// This method handles permission requests differently based on iOS version.
    ///
    /// - Parameter completion: A closure that is called with a boolean indicating
    ///   whether permission was granted for both EventKit and notifications
    func requestAccess(completion: @escaping (Bool) -> Void) {
        // Request EventKit access
        if #available(iOS 17.0, *) {
            Task {
                do {
                    print("Requesting EventKit permission for iOS 17+")
                    // request full access
                    let accessGranted = try await eventStore.requestFullAccessToReminders()
                    print("EventKit full access granted: \(accessGranted)")
                    
                    if !accessGranted {
                        print(" User denied EventKit permissions!")
                        DispatchQueue.main.async {
                            completion(false)
                            self.promptToOpenSettings()
                        }
                        return
                    }
                    
                    // Request notification permissions
                    let notificationCenter = UNUserNotificationCenter.current()
                    
                    let notifStatus = await withCheckedContinuation { continuation in
                        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                            if let error = error {
                                print("Error requesting notification permission: \(error)")
                            }
                            continuation.resume(returning: granted)
                        }
                    }
                    
                    print("Notification permission granted: \(notifStatus)")
                    DispatchQueue.main.async {
                        completion(accessGranted && notifStatus)
                    }
                    
                } catch {
                    print("Error requesting EventKit permission: \(error)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        } else {
            // iOS 16 and earlier
            print("Requesting EventKit permission for iOS 16 and earlier")
            eventStore.requestAccess(to: .reminder) { granted, error in
                print("EventKit permission granted: \(granted)")
                if let error = error {
                    print("Error requesting EventKit permission: \(error)")
                }
                
                if !granted {
                    print("User denied EventKit permissions!")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                                
                // Request notification permissions
                let notificationCenter = UNUserNotificationCenter.current()
                
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { notifGranted, notifError in
                    if let error = notifError {
                        print("Error requesting notification permission: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(granted && notifGranted)
                    }
                }
            }
        }
    }
    
    /// Prompts the user to open the Settings app to change permissions.
    /// This is typically called when the user has previously denied a required permission.
    private func promptToOpenSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    
    /// Fetches all reminders for the specified user from Firestore.
    ///
    /// - Parameter userId: The ID of the user whose reminders should be fetched
    func fetchReminders(userId: String?) async {
        guard let userId = userId else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            let firestoreReminders = try await FirestoreService.getReminders(userId: userId)
            
            DispatchQueue.main.async {
                self.reminders = firestoreReminders
                self.isLoading = false
            }
        } catch {
            print("Error fetching reminders: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    /// Creates a new reminder and saves it both to the system's EventKit and to Firestore.
    /// Also schedules a local notification for the reminder.
    ///
    /// - Parameters:
    ///   - reminder: The ShoppingReminder object to add
    ///   - userId: The ID of the user creating the reminder
    func addReminder(reminder: ShoppingReminder, userId: String?) async {
        guard let userId = userId else {
            print("Error: userId is nil")
            return
        }
        
        do {
            print("Creating EventKit reminder...")
            // 1. Create the reminder in EventKit
            let eventId = try await createEventKitReminder(reminder: reminder)
            print("EventKit reminder created with ID: \(eventId)")
            
            // 2. Update the reminder with the EventKit ID
            var updatedReminder = reminder
            updatedReminder.eventId = eventId
            
            print("Saving reminder to Firestore...")
            // 3. Save to Firestore
            try await FirestoreService.saveReminder(userId: userId, reminder: updatedReminder)
            print("Reminder saved to Firestore successfully")
            
            // 4. Schedule a local notification
            print("Scheduling notification...")
            scheduleNotification(for: updatedReminder)
            print("Notification scheduled successfully")
            
            // 5. Refresh the reminders list
            await fetchReminders(userId: userId)
        } catch {
            print("Error adding reminder: \(error.localizedDescription)")
            // More detailed error info
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain), code: \(nsError.code)")
                print("User info: \(nsError.userInfo)")
            }
        }
    }
    
    /// Toggles the active status of a reminder both in EventKit and Firestore.
    /// When a reminder is toggled to active, a notification is scheduled.
    /// When toggled to inactive, the notification is canceled.
    ///
    /// - Parameters:
    ///   - id: The ID of the reminder to toggle
    ///   - userId: The ID of the user who owns the reminder
    func toggleReminderStatus(id: String, userId: String?) async {
        guard let userId = userId,
              let reminderIndex = reminders.firstIndex(where: { $0.id == id }) else { return }
        
        // Get the reminder
        let reminder = reminders[reminderIndex]
        
        // Create updated reminder
        var updatedReminder = reminder
        updatedReminder.isActive.toggle()
        
        do {
            // Update the EventKit reminder
            if let eventId = reminder.eventId {
                try await updateEventKitReminder(
                    eventId: eventId,
                    isActive: updatedReminder.isActive
                )
            }
            
            // Update in Firestore
            try await FirestoreService.updateReminder(
                userId: userId,
                reminderId: id,
                isActive: updatedReminder.isActive
            )
            
            // Update local state
            DispatchQueue.main.async {
                self.reminders[reminderIndex].isActive.toggle()
            }
            
            // Handle notification
            if updatedReminder.isActive {
                scheduleNotification(for: updatedReminder)
            } else {
                cancelNotification(for: updatedReminder.id)
            }
        } catch {
            print("Error toggling reminder status: \(error)")
        }
    }
    
    /// Deletes a reminder from both EventKit and Firestore.
    /// Also cancels any pending notification for the reminder.
    ///
    /// - Parameters:
    ///   - id: The ID of the reminder to delete
    ///   - userId: The ID of the user who owns the reminder
    func deleteReminder(id: String, userId: String?) async {
        guard let userId = userId,
              let reminder = reminders.first(where: { $0.id == id }) else { return }
        
        do {
            // Delete from EventKit if have an event ID
            if let eventId = reminder.eventId {
                try await deleteEventKitReminder(eventId: eventId)
            }
            
            // Delete from Firestore
            try await FirestoreService.deleteReminder(userId: userId, reminderId: id)
            
            // Cancel notification
            cancelNotification(for: id)
            
            // Update local state
            DispatchQueue.main.async {
                self.reminders.removeAll { $0.id == id }
            }
        } catch {
            print("Error deleting reminder: \(error)")
        }
    }
    
    // MARK: - EventKit Integration
    
    /// Creates a new reminder in the system's EventKit.
    ///
    /// - Parameter reminder: The ShoppingReminder object to create in EventKit
    /// - Throws: NSError if permissions aren't granted or if the reminder creation fails
    /// - Returns: The EventKit identifier for the created reminder
    private func createEventKitReminder(reminder: ShoppingReminder) async throws -> String {
        // First, verify have permissions
        if #available(iOS 17.0, *) {
            guard await EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
                print("EventKit permission not granted - need full access")
                throw NSError(domain: "ReminderManager",
                              code: 403,
                              userInfo: [NSLocalizedDescriptionKey: "EventKit permission not granted"])
            }
        } else {
            guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else {
                print("EventKit permission not granted")
                throw NSError(domain: "ReminderManager",
                              code: 403,
                              userInfo: [NSLocalizedDescriptionKey: "EventKit permission not granted"])
            }
        }
        
        // Create a new reminder in EventKit
        let ekReminder = EKReminder(eventStore: eventStore)
        
        // Set reminder properties
        ekReminder.title = reminder.title
        ekReminder.notes = reminder.message
        
        // Verify calendar is available
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            print("No default calendar available for reminders")
            throw NSError(domain: "ReminderManager",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No default calendar available"])
        }
        
        // Set calendar
        ekReminder.calendar = calendar
        
        // Set due date
        let alarm = EKAlarm(absoluteDate: reminder.date)
        ekReminder.addAlarm(alarm)
        
        // Create a due date
        ekReminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date
        )
        
        // Set priority
        ekReminder.priority = 1
        
        do {
            // Save the reminder
            try eventStore.save(ekReminder, commit: true)
            print("Successfully saved EventKit reminder")
            return ekReminder.calendarItemIdentifier
        } catch {
            print("Failed to save reminder: \(error)")
            throw error
        }
    }
    
    /// Updates an existing EventKit reminder's completed status.
    ///
    /// - Parameters:
    ///   - eventId: The EventKit identifier of the reminder to update
    ///   - isActive: The new active state (false means completed in EventKit)
    /// - Throws: NSError if the reminder is not found or can't be updated
    private func updateEventKitReminder(eventId: String, isActive: Bool) async throws {
        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: NSError(domain: "ReminderManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch reminders"]))
                }
            }
        }

        guard let ekReminder = reminders.first(where: { $0.calendarItemIdentifier == eventId }) else {
            throw NSError(domain: "ReminderManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "EventKit reminder not found"])
        }

        ekReminder.isCompleted = !isActive
        try eventStore.save(ekReminder, commit: true)
    }

    /// Deletes an EventKit reminder.
    ///
    /// - Parameter eventId: The EventKit identifier of the reminder to delete
    /// - Throws: NSError if the reminder is not found or can't be deleted
    private func deleteEventKitReminder(eventId: String) async throws {
        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: NSError(domain: "ReminderManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch reminders"]))
                }
            }
        }

        guard let ekReminder = reminders.first(where: { $0.calendarItemIdentifier == eventId }) else {
            throw NSError(domain: "ReminderManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "EventKit reminder not found"])
        }

        try eventStore.remove(ekReminder, commit: true)
    }
 
    // MARK: - Push Notifications
    
    /// Schedules a local notification for a reminder.
    ///
    /// - Parameter reminder: The ShoppingReminder to schedule a notification for    
    private func scheduleNotification(for reminder: ShoppingReminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        
        // Add identifier based on reminder type
        content.categoryIdentifier = reminder.type.rawValue
        
        // Create calendar components for the notification trigger
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date)
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        // Create the notification request
        let request = UNNotificationRequest(
            identifier: reminder.id,
            content: content,
            trigger: trigger
        )
        
        // Add the request to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    /// Cancels a pending notification for a reminder.
    ///
    /// - Parameter reminderID: The ID of the reminder whose notification should be canceled
    private func cancelNotification(for reminderID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
