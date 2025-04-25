import SwiftUI
import Foundation

/// A model representing a single day's weather forecast.
/// This includes temperature, condition, and presentation data for display.
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