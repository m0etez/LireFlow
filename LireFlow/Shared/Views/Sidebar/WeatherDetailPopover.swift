import SwiftUI

struct WeatherDetailPopover: View {
    let weather: WeatherService.WeatherData
    let dailyForecasts: [WeatherService.DailyForecast]
    let locationName: String
    
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: weather.conditionGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                // Header
                VStack(spacing: 8) {
                    Text(locationName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    
                    HStack(alignment: .center, spacing: 16) {
                        Image(systemName: weather.conditionIcon)
                            .font(.system(size: 64))
                            .symbolEffect(.bounce, value: weather.conditionIcon)
                            .foregroundStyle(.white)
                        
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundStyle(.white)
                    }
                    
                    Text(weather.conditionDescription)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Details Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailItem(icon: "thermometer.medium", label: NSLocalizedString("Feels Like", comment: ""), value: "\(Int(weather.apparentTemperature))°")
                    DetailItem(icon: "wind", label: NSLocalizedString("Wind", comment: ""), value: "\(Int(weather.windSpeed)) km/h")
                    DetailItem(icon: "humidity", label: NSLocalizedString("Humidity", comment: ""), value: "\(weather.humidity)%")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Forecast
                VStack(alignment: .leading, spacing: 12) {
                    Label(NSLocalizedString("7-Day Forecast", comment: ""), systemImage: "calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    VStack(spacing: 0) {
                        ForEach(dailyForecasts.prefix(5)) { day in
                            HStack {
                                Text(day.dayName)
                                    .frame(width: 50, alignment: .leading)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Image(systemName: day.icon)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.title3)
                                
                                Spacer()
                                
                                Text("\(Int(day.temperatureMin))°")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 30)
                                
                                // Bar
                                Capsule()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 4)
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(.white)
                                            .frame(width: 40, height: 4)
                                    }
                                
                                Text("\(Int(day.temperatureMax))°")
                                    .foregroundStyle(.white)
                                    .frame(width: 30)
                            }
                            .padding(.vertical, 8)
                            if day.id != dailyForecasts.prefix(5).last?.id {
                                Divider().background(.white.opacity(0.2))
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Button {
                    #if targetEnvironment(simulator)
                    let query = "weather \(locationName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "weather"
                    if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                        openURL(url)
                    }
                    #else
                    if let url = URL(string: "weather://") {
                        openURL(url)
                    }
                    #endif
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right")
                        Text(NSLocalizedString("Open in Weather", comment: ""))
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}


#Preview {
    WeatherDetailPopover(
        weather: WeatherService.WeatherData(
            temperature: 18,
            apparentTemperature: 16,
            weatherCode: 2,
            isDay: true,
            windSpeed: 12,
            humidity: 65
        ),
        dailyForecasts: [
            WeatherService.DailyForecast(date: Date(), temperatureMax: 20, temperatureMin: 12, weatherCode: 0),
            WeatherService.DailyForecast(date: Date().addingTimeInterval(86400), temperatureMax: 22, temperatureMin: 14, weatherCode: 1),
            WeatherService.DailyForecast(date: Date().addingTimeInterval(172800), temperatureMax: 18, temperatureMin: 10, weatherCode: 61)
        ],
        locationName: "Paris"
    )
}


