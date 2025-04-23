import SwiftUI
import Foundation

/// A model representing a single day's weather forecast.
/// This includes temperature, condition, and presentation data for display.
struct DayForecast: Identifiable {
    /// Unique identifier for the forecast day
    let id = UUID()
    
    /// The date of this forecast
    let date: Date
    
    /// Display name for the day (e.g., "Today", "Mon", "Tue")
    let dayName: String
    
    /// Current temperature formatted as a string with units
    let temperature: String
    
    /// High temperature for the day formatted as a string with units
    let high: String
    
    /// Low temperature for the day formatted as a string with units
    let low: String
    
    /// Weather condition description (e.g., "Clear", "Cloudy")
    let condition: String
    
    /// SF Symbol name for the icon representing the weather condition
    let conditionIcon: String
}