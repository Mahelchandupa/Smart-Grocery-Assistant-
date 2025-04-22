import Foundation
import WeatherKit
import CoreLocation

struct DayForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let temperature: String
    let high: String
    let low: String
    let condition: String
    let conditionIcon: String
}

class WeatherManager: NSObject, ObservableObject {
    private let service = WeatherService()
    private let locationManager = CLLocationManager()
    private let openWeatherAPIKey = "8b7675d1c0cbf658324a749f114d6aae"
    
    @Published var temperature: String = "--"
    @Published var condition: String = "Loading..."
    @Published var source: String = ""
    @Published var forecasts: [DayForecast] = []
    @Published var isLoading: Bool = true

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    private func fetchWeatherKitData(for location: CLLocation) {
        Task {
            do {
                let weather = try await service.weather(for: location)
                let dailyForecast = try await service.weather(
                    for: location,
                    including: .daily
                )
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "E" // Day name abbreviation
                
                var newForecasts: [DayForecast] = []
                
                // Current day + next 3 days = 4 days total
                for i in 0..<min(4, dailyForecast.count) {
                    let forecast = dailyForecast[i]
                    let dayName = i == 0 ? "Today" : dateFormatter.string(from: forecast.date)
                    
                    let dayForecast = DayForecast(
                        date: forecast.date,
                        dayName: dayName,
                        temperature: String(format: "%.0f℃", forecast.highTemperature.value),
                        high: String(format: "%.0f℃", forecast.highTemperature.value),
                        low: String(format: "%.0f℃", forecast.lowTemperature.value),
                        condition: forecast.condition.description,
                        conditionIcon: getIconName(for: forecast.condition)
                    )
                    newForecasts.append(dayForecast)
                }
                
                DispatchQueue.main.async {
                    self.temperature = String(format: "%.0f℃", weather.currentWeather.temperature.value)
                    self.condition = weather.currentWeather.condition.description
                    self.source = "WeatherKit"
                    self.forecasts = newForecasts
                    self.isLoading = false
                }
            } catch {
                print("WeatherKit error: \(error.localizedDescription)")
                self.fetchOpenWeatherData(for: location)
            }
        }
    }

    private func getIconName(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return "cloud.fill"
        case .rain, .heavyRain, .drizzle:
            return "cloud.rain.fill"
        case .snow, .flurries, .sleet, .freezingRain, .wintryMix:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    private func fetchOpenWeatherData(for location: CLLocation) {
        // Current weather
        let currentUrlString = """
        https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&units=metric&appid=\(openWeatherAPIKey)
        """
        
        // Forecast
        let forecastUrlString = """
        https://api.openweathermap.org/data/2.5/forecast?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&units=metric&appid=\(openWeatherAPIKey)
        """
        
        guard let currentUrl = URL(string: currentUrlString),
              let forecastUrl = URL(string: forecastUrlString) else { return }

        // Fetch current weather
        URLSession.shared.dataTask(with: currentUrl) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let weatherArray = json["weather"] as? [[String: Any]],
                   let temp = main["temp"] as? Double,
                   let description = weatherArray.first?["description"] as? String {
                    
                    DispatchQueue.main.async {
                        self.temperature = "\(Int(temp))℃"
                        self.condition = description.capitalized
                        self.source = "OpenWeather"
                    }
                }
            } catch {
                print("OpenWeather parse error: \(error.localizedDescription)")
            }
        }.resume()
        
        // Fetch forecast
        URLSession.shared.dataTask(with: forecastUrl) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let list = json["list"] as? [[String: Any]] {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    
                    let dayFormatter = DateFormatter()
                    dayFormatter.dateFormat = "E"
                    
                    // Group forecast data by day
                    var dailyForecasts: [String: (high: Double, low: Double, condition: String, icon: String)] = [:]
                    var dates: [String: Date] = [:]
                    
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    // Initialize with today
                    let todayString = "Today"
                    dailyForecasts[todayString] = (high: -100, low: 100, condition: "", icon: "")
                    dates[todayString] = today
                    
                    for item in list {
                        if let dtString = item["dt_txt"] as? String,
                           let date = dateFormatter.date(from: dtString),
                           let main = item["main"] as? [String: Any],
                           let temp = main["temp"] as? Double,
                           let weatherArray = item["weather"] as? [[String: Any]],
                           let weather = weatherArray.first,
                           let description = weather["description"] as? String,
                           let iconCode = weather["icon"] as? String {
                            
                            let dayStart = calendar.startOfDay(for: date)
                            let dayDiff = calendar.dateComponents([.day], from: today, to: dayStart).day ?? 0
                            
                            // Only consider days 0-3 (today + 3 more days)
                            if dayDiff >= 0 && dayDiff <= 3 {
                                let dayKey = dayDiff == 0 ? "Today" : dayFormatter.string(from: date)
                                
                                // Update high and low temperatures
                                if let existing = dailyForecasts[dayKey] {
                                    let high = max(existing.high, temp)
                                    let low = min(existing.low, temp)
                                    dailyForecasts[dayKey] = (high: high, low: low, condition: description, icon: self.getOpenWeatherIcon(code: iconCode))
                                } else {
                                    dailyForecasts[dayKey] = (high: temp, low: temp, condition: description, icon: self.getOpenWeatherIcon(code: iconCode))
                                    dates[dayKey] = dayStart
                                }
                            }
                        }
                    }
                    
                    // Convert to DayForecast objects
                    var forecasts: [DayForecast] = []
                    
                    // Sort days with "Today" first, then the rest by date
                    let sortedDays = dailyForecasts.keys.sorted { key1, key2 in
                        if key1 == "Today" { return true }
                        if key2 == "Today" { return false }
                        guard let date1 = dates[key1], let date2 = dates[key2] else { return false }
                        return date1 < date2
                    }
                    
                    for day in sortedDays {
                        if let forecast = dailyForecasts[day], let date = dates[day] {
                            forecasts.append(DayForecast(
                                date: date,
                                dayName: day,
                                temperature: "\(Int(forecast.high))℃",
                                high: "\(Int(forecast.high))℃",
                                low: "\(Int(forecast.low))℃",
                                condition: forecast.condition.capitalized,
                                conditionIcon: forecast.icon
                            ))
                        }
                    }
                    
                    // Take only the first 4 days if we have more
                    let limitedForecasts = Array(forecasts.prefix(4))
                    
                    DispatchQueue.main.async {
                        self.forecasts = limitedForecasts
                        self.isLoading = false
                    }
                }
            } catch {
                print("OpenWeather forecast parse error: \(error.localizedDescription)")
                self.isLoading = false
            }
        }.resume()
    }
    
    private func getOpenWeatherIcon(code: String) -> String {
        // Map OpenWeather icon codes to SF Symbols
        switch code {
        case "01d", "01n": return "sun.max.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n", "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

extension WeatherManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            fetchWeatherKitData(for: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
