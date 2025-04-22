import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var navPath: NavigationPath
    @StateObject private var weatherManager = WeatherManager()
    
    @State private var lists: [ShoppingList] = []
    @State private var activeListCount = 0
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Lists")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(activeListCount) active lists")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "E8F5E9"))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            navPath.append(Route.reminder)
                        }) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            navPath.append(Route.profile)
                        }) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 8)
            }
            .frame(height: 120)
            .background(Color(hex: "4CAF50"))
            
            // Main Content
            ScrollView {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "4CAF50")))
                        .scaleEffect(1.5)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        // Quick Actions
                        quickActionsSection()
                        
                        // Your Shopping Lists
                        shoppingListsSection()
                            .padding(.top, 16)
                        
                        suggestionsSection()
                            .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 20) {
                                     // Header
                                     Text("Weather Forecast")
                                       .font(.system(size: 18, weight: .semibold))
                                       .foregroundColor(Color(hex: "424242"))
                                                                          
                                     if weatherManager.isLoading {
                                         HStack {
                                             Spacer()
                                             ProgressView()
                                                 .progressViewStyle(CircularProgressViewStyle())
                                                 .scaleEffect(1.5)
                                                 .padding()
                                             Spacer()
                                         }
                                     } else {
                                         // Daily forecast cards - horizontal scroll
                                         ScrollView(.horizontal, showsIndicators: false) {
                                             HStack(spacing: 16) {
                                                 ForEach(weatherManager.forecasts) { forecast in
                                                     DayForecastCard(forecast: forecast)
                                                 }
                                             }
                                             .padding(.horizontal, 16)
                                             .padding(.bottom, 8)
                                         }
                                     }
                                     
                                     Spacer()
                                 }
                                 .padding()
                        
            
                        // Suggestions
//                        weatherForecastSection()
//                            .padding(.bottom, 16)
                    }
                }
            }
            .background(Color(hex: "F5F7FA"))
            .refreshable {
                await fetchLists()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .task {
            await fetchLists()
        }
    }
    
    private func getWeatherIcon(for condition: String) -> String {
          let condition = condition.lowercased()
          
          if condition.contains("clear") || condition.contains("sunny") {
              return "sun.max.fill"
          } else if condition.contains("cloud") {
              return "cloud.fill"
          } else if condition.contains("rain") || condition.contains("shower") {
              return "cloud.rain.fill"
          } else if condition.contains("snow") || condition.contains("sleet") {
              return "cloud.snow.fill"
          } else if condition.contains("thunder") || condition.contains("lightning") {
              return "cloud.bolt.fill"
          } else if condition.contains("fog") || condition.contains("mist") {
              return "cloud.fog.fill"
          } else {
              return "questionmark.circle.fill"
          }
      }
    
    struct DayForecastCard: View {
        let forecast: DayForecast
        
        var body: some View {
            VStack(alignment: .center, spacing: 12) {
                // Day name
                Text(forecast.dayName)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "424242"))
                
                // Weather icon
                Image(systemName: forecast.conditionIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "4CAF50"))
                    .padding(.vertical, 8)
                
                // Temperature
                Text(forecast.temperature)
                    .font(.title2.bold())
                    .foregroundColor(Color(hex: "4CAF50"))
                
                // High/Low
                HStack(spacing: 8) {
                    VStack(alignment: .center) {
                        Text("High")
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                        Text(forecast.high)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "FF5722"))
                    }
                    
                    Rectangle()
                        .frame(width: 1, height: 24)
                        .foregroundColor(Color(hex: "E0E0E0"))
                    
                    VStack(alignment: .center) {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                        Text(forecast.low)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "4CAF50"))
                    }
                }
                
                // Condition
                Text(forecast.condition)
                    .font(.caption)
                    .foregroundColor(Color(hex: "616161"))
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
            .frame(width: 120, height: 200)
            .padding()
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    
    // View Components
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "616161"))
            
            HStack(spacing: 0) {
                Spacer()
                
                quickActionButton(
                    icon: "plus.circle.fill",
                    color: Color(hex: "4CAF50"),
                    bgColor: Color(hex: "E8F5E9"),
                    label: "New List",
                    action: {
                        navPath.append(Route.createNewList)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "cart.fill",
                    color: Color(hex: "2196F3"),
                    bgColor: Color(hex: "E3F2FD"),
                    label: "Buy Groceries",
                    action: {
                        navPath.append(Route.buy)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "fork.knife",
                    color: Color(hex: "FF9800"),
                    bgColor: Color(hex: "FFF3E0"),
                    label: "Recipes",
                    action: {
                        navPath.append(Route.recipes)
                    }
                )
                
                Spacer()
                
                quickActionButton(
                    icon: "clock.fill",
                    color: Color(hex: "7e22ce"),
                    bgColor: Color(hex: "F3E5F5"),
                    label: "History",
                    action: {
                        navPath.append(Route.history)
                    }
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    private func shoppingListsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Shopping Lists")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "424242"))
                .padding(.horizontal, 16)
            
            if lists.isEmpty {
                // Placeholder when no lists are available
                VStack {
                    Text("No shopping lists yet")
                        .foregroundColor(.gray)
                        .padding()
                }
                .frame(minHeight: 80 - 30) // Subtract the header height and padding
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            } else {
                ForEach(lists) { list in
                    shoppingListItem(list)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(minHeight: 80) // Set minimum height for the entire section
        .padding(.bottom, 16)
    }
    
    
    private func suggestionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested For You")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "424242"))
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You're running low on:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "616161"))
                
                HStack(spacing: 8) {
                    ForEach(["Milk", "Eggs", "Bread"], id: \.self) { item in
                        Button(action: {
                            // Add item to list
                        }) {
                            HStack(spacing: 2) {
                                Text("+ \(item)")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "616161"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading) // Take full width
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
    
    private func formattedForecastDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date) // "Mon", "Tue"
    }

    private func systemSymbol(for condition: String) -> String {
        // Map WeatherKit symbols to SF Symbols (rough match)
        switch condition {
        case "cloud.sun": return "cloud.sun.fill"
        case "cloud.rain": return "cloud.rain.fill"
        case "sun.max": return "sun.max.fill"
        case "cloud.bolt": return "cloud.bolt.fill"
        case "cloud.snow": return "cloud.snow.fill"
        default: return "cloud.fill"
        }
    }

    
    // Helper Views   
    private func quickActionButton(icon: String, color: Color, bgColor: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(bgColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "757575"))
            }
        }
    }
    
    private func shoppingListItem(_ list: ShoppingList) -> some View {
        Button(action: {
            navPath.append(Route.listDetail(id: list.id))
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color(hex: list.color))
                    .frame(height: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(list.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "424242"))
                    
                    HStack {
                        Text("\(list.completedItems)/\(list.totalItems) items")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "6B7280"))
                        
                        Spacer()
                        
                        Text("Due: \(list.dueDate != nil ? formattedDate(list.dueDate!) : "No due date")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "6B7280"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F3F4F6"))
                            .cornerRadius(16)
                    }
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "EEEEEE"))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        let progress = CGFloat(list.completedItems) / CGFloat(list.totalItems)
                        Rectangle()
                            .fill(Color(hex: list.color))
                            .frame(width: progress * (UIScreen.main.bounds.width - 64), height: 8)
                            .cornerRadius(4)
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
//        .padding(.bottom, 16)
    }
    
    private func fetchLists() async {
        isLoading = true
        do {
            let fetchedLists = try await authManager.getUserLists()
            self.lists = Array(fetchedLists.prefix(3))
            self.activeListCount = fetchedLists.count
        } catch {
            print("Error fetching lists: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Example: "Apr 20"
        return formatter.string(from: date)
    }

}
