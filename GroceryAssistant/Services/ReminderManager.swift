import Foundation
import UIKit
import EventKit
import UserNotifications

// ReminderManager to handle EventKit and Firestore operations
class ReminderManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var reminders: [ShoppingReminder] = []
    @Published var isLoading: Bool = false
    
    // Computed properties for active/inactive reminders
    var activeReminders: [ShoppingReminder] {
        reminders.filter { $0.isActive }
    }
    
    var inactiveReminders: [ShoppingReminder] {
        reminders.filter { !$0.isActive }
    }
    
    // Request access to EKEventStore and UNUserNotificationCenter
    func requestAccess(completion: @escaping (Bool) -> Void) {
        // Request EventKit access
        if #available(iOS 17.0, *) {
            Task {
                do {
                    print("Requesting EventKit permission for iOS 17+")
                    // For iOS 17, we need to request full access
                    let accessGranted = try await eventStore.requestFullAccessToReminders()
                    print("EventKit full access granted: \(accessGranted)")
                    
                    if !accessGranted {
                        print("⚠️ User denied EventKit permissions!")
                        DispatchQueue.main.async {
                            completion(false)
                            self.promptToOpenSettings() // 🔥 Add this line
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
                    print("❌ Error requesting EventKit permission: \(error)")
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
                    print("⚠️ User denied EventKit permissions!")
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
    
    private func promptToOpenSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    
    // Fetch reminders from Firestore
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
    
    // Add a new reminder
//    func addReminder(reminder: ShoppingReminder, userId: String?) async {
//        guard let userId = userId else { return }
//        
//        do {
//            // 1. Create the reminder in EventKit
//            let eventId = try await createEventKitReminder(reminder: reminder)
//            
//            // 2. Update the reminder with the EventKit ID
//            var updatedReminder = reminder
//            updatedReminder.eventId = eventId
//            
//            // 3. Save to Firestore
//            try await FirestoreService.saveReminder(userId: userId, reminder: updatedReminder)
//            
//            // 4. Schedule a local notification
//            scheduleNotification(for: updatedReminder)
//            
//            // 5. Refresh the reminders list
//            await fetchReminders(userId: userId)
//        } catch {
//            print("Error adding reminder: \(error)")
//        }
//    }
    
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
    
    // Toggle reminder active status
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
    
    // Delete a reminder
    func deleteReminder(id: String, userId: String?) async {
        guard let userId = userId,
              let reminder = reminders.first(where: { $0.id == id }) else { return }
        
        do {
            // Delete from EventKit if we have an event ID
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
    private func createEventKitReminder(reminder: ShoppingReminder) async throws -> String {
        // First, verify we have permissions
        if #available(iOS 17.0, *) {
            guard await EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
                print("❌ EventKit permission not granted - need full access")
                throw NSError(domain: "ReminderManager",
                              code: 403,
                              userInfo: [NSLocalizedDescriptionKey: "EventKit permission not granted"])
            }
        } else {
            guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else {
                print("❌ EventKit permission not granted")
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
            print("❌ No default calendar available for reminders")
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
        ekReminder.priority = 1 // High priority
        
        do {
            // Save the reminder
            try eventStore.save(ekReminder, commit: true)
            print("✅ Successfully saved EventKit reminder")
            return ekReminder.calendarItemIdentifier
        } catch {
            print("❌ Failed to save reminder: \(error)")
            throw error
        }
    }
    
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
    
    private func cancelNotification(for reminderID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
