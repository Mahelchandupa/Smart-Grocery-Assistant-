import SwiftUI

struct ReminderCard: View {
    let reminder: ShoppingReminder
    let toggleReminderStatus: (String) -> Void
    let deleteReminder: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Icon
                reminderTypeIcon
                
                // Title and Date
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .fontWeight(.semibold)
                    
                    if reminder.type == .item, let listName = reminder.listName {
                        Text("From list: \(listName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(reminder.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        Text(reminder.formattedTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Toggle and Delete buttons
                HStack {
                    Toggle("", isOn: Binding(
                        get: { reminder.isActive },
                        set: { _ in toggleReminderStatus(reminder.id) }
                    ))
                    .labelsHidden()
                    .tint(.green)
                    
                    Button(action: {
                        deleteReminder(reminder.id)
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Text(reminder.message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var reminderTypeIcon: some View {
        let iconSize: CGFloat = 40
        
        switch reminder.type {
        case .list:
            return ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "cart")
                    .foregroundColor(.blue)
            }
            .frame(width: iconSize, height: iconSize)
        case .item:
            return ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "cube")
                    .foregroundColor(.purple)
            }
            .frame(width: iconSize, height: iconSize)
        case .expiry:
            return ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            }
            .frame(width: iconSize, height: iconSize)
        }
    }
}
