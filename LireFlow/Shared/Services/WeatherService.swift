import Foundation
import CoreLocation
import SwiftUI

/// Weather service using Open-Meteo API (free, no API key required)
@MainActor
class WeatherService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published var currentWeather: WeatherData?
    @Published var dailyForecasts: [DailyForecast] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var locationName: String = "Loading..."
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    
    // Geocoding rate limit protection
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeTime: Date?
    private let geocoder = CLGeocoder()
    
    struct WeatherData {
        let temperature: Double
        let apparentTemperature: Double
        let weatherCode: Int
        let isDay: Bool
        let windSpeed: Double
        let humidity: Int
        
        var conditionIcon: String {
            switch weatherCode {
            case 0: return isDay ? "sun.max.fill" : "moon.fill"
            case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
            case 3: return "cloud.fill"
            case 45, 48: return "cloud.fog.fill"
            case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
            case 61, 63, 65, 66, 67: return "cloud.rain.fill"
            case 71, 73, 75, 77: return "cloud.snow.fill"
            case 80, 81, 82: return "cloud.heavyrain.fill"
            case 85, 86: return "cloud.snow.fill"
            case 95, 96, 99: return "cloud.bolt.rain.fill"
            default: return "cloud.fill"
            }
        }
        
        var conditionDescription: String {
            switch weatherCode {
            case 0: return "Clear"
            case 1: return "Mainly Clear"
            case 2: return "Partly Cloudy"
            case 3: return "Overcast"
            case 45, 48: return "Foggy"
            case 51, 53, 55: return "Drizzle"
            case 56, 57: return "Freezing Drizzle"
            case 61, 63, 65: return "Rain"
            case 66, 67: return "Freezing Rain"
            case 71, 73, 75: return "Snow"
            case 77: return "Snow Grains"
            case 80, 81, 82: return "Showers"
            case 85, 86: return "Snow Showers"
            case 95: return "Thunderstorm"
            case 96, 99: return "Thunderstorm with Hail"
            default: return "Unknown"
            }
        }
        
        var conditionColor: Color {
            switch weatherCode {
            case 0: return isDay ? .orange : .indigo           // Clear - orange sun, indigo moon
            case 1, 2: return isDay ? .yellow : .purple        // Partly cloudy
            case 3: return .gray                                // Overcast
            case 45, 48: return .gray.opacity(0.7)              // Fog
            case 51, 53, 55, 56, 57: return .cyan               // Drizzle
            case 61, 63, 65, 66, 67: return .blue               // Rain
            case 71, 73, 75, 77: return .mint                   // Snow
            case 80, 81, 82: return .blue                       // Heavy rain
            case 85, 86: return .mint                           // Snow showers
            case 95, 96, 99: return .purple                     // Thunderstorm
            default: return .gray
            }
        }
    }
    
    struct DailyForecast: Identifiable {
        let id = UUID()
        let date: Date
        let temperatureMax: Double
        let temperatureMin: Double
        let weatherCode: Int
        
        var dayName: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
        
        var icon: String {
            switch weatherCode {
            case 0: return "sun.max.fill"
            case 1, 2: return "cloud.sun.fill"
            case 3: return "cloud.fill"
            case 45, 48: return "cloud.fog.fill"
            case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
            case 61, 63, 65, 66, 67: return "cloud.rain.fill"
            case 71, 73, 75, 77: return "cloud.snow.fill"
            case 80, 81, 82: return "cloud.heavyrain.fill"
            case 85, 86: return "cloud.snow.fill"
            case 95, 96, 99: return "cloud.bolt.rain.fill"
            default: return "cloud.fill"
            }
        }
        
        var iconColor: Color {
            switch weatherCode {
            case 0: return .orange
            case 1, 2: return .yellow
            case 3: return .gray
            case 45, 48: return .gray.opacity(0.7)
            case 51, 53, 55, 56, 57: return .cyan
            case 61, 63, 65, 66, 67: return .blue
            case 71, 73, 75, 77: return .mint
            case 80, 81, 82: return .blue
            case 85, 86: return .mint
            case 95, 96, 99: return .purple
            default: return .gray
            }
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        // Skip if already have weather
        guard currentWeather == nil else { return }
        
        isLoading = true
        error = nil
        
        // Start location request
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        // Fallback to Paris after 3 seconds if location fails
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if isLoading && currentWeather == nil {
                locationName = "Paris"
                await fetchWeather(latitude: 48.8566, longitude: 2.3522)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Stop updates after first location - we only need one for weather
        locationManager.stopUpdatingLocation()
        
        // Skip if we already have weather data
        guard currentWeather == nil else { return }
        
        lastLocation = location
        
        // Only geocode if:
        // 1. We haven't geocoded before, OR
        // 2. The location has changed significantly (>1km), AND
        // 3. At least 2 seconds have passed since last geocode
        let shouldGeocode: Bool = {
            guard let lastGeocoded = lastGeocodedLocation else { return true }
            let distance = location.distance(from: lastGeocoded)
            let timeSinceLastGeocode = lastGeocodeTime.map { Date().timeIntervalSince($0) } ?? .infinity
            return distance > 1000 && timeSinceLastGeocode > 2.0
        }()
        
        if shouldGeocode {
            lastGeocodeTime = Date()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self = self else { return }
                if let placemark = placemarks?.first {
                    Task { @MainActor in
                        self.locationName = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                        self.lastGeocodedLocation = location
                    }
                } else if error != nil {
                    // Fallback to coordinates if geocoding fails
                    Task { @MainActor in
                        self.locationName = String(format: "%.2f, %.2f", location.coordinate.latitude, location.coordinate.longitude)
                    }
                }
            }
        }
        
        // Fetch weather
        Task {
            await fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        self.error = "Location unavailable"
        
        // Fall back to Paris if location fails
        Task {
            locationName = "Paris"
            await fetchWeather(latitude: 48.8566, longitude: 2.3522)
        }
    }
    
    private func fetchWeather(latitude: Double, longitude: Double) async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m,relative_humidity_2m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            
            currentWeather = WeatherData(
                temperature: response.current.temperature_2m,
                apparentTemperature: response.current.apparent_temperature,
                weatherCode: response.current.weather_code,
                isDay: response.current.is_day == 1,
                windSpeed: response.current.wind_speed_10m,
                humidity: response.current.relative_humidity_2m
            )
            
            // Parse daily forecasts
            if let daily = response.daily {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                dailyForecasts = zip(daily.time.indices, daily.time).compactMap { index, dateString in
                    guard let date = dateFormatter.date(from: dateString),
                          index < daily.temperature_2m_max.count,
                          index < daily.temperature_2m_min.count,
                          index < daily.weather_code.count else { return nil }
                    
                    return DailyForecast(
                        date: date,
                        temperatureMax: daily.temperature_2m_max[index],
                        temperatureMin: daily.temperature_2m_min[index],
                        weatherCode: daily.weather_code[index]
                    )
                }
            }
            
            isLoading = false
        } catch {
            self.error = "Failed to fetch weather"
            isLoading = false
        }
    }
}

// MARK: - API Response Models

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather?
    
    struct CurrentWeather: Codable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
        let is_day: Int
        let wind_speed_10m: Double
        let relative_humidity_2m: Int
    }
    
    struct DailyWeather: Codable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let weather_code: [Int]
    }
}
