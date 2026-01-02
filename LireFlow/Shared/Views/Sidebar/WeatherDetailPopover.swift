import SwiftUI

struct WeatherDetailPopover: View {
    let weather: WeatherService.WeatherData
    let dailyForecasts: [WeatherService.DailyForecast]
    let locationName: String
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: weather.conditionGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
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
                .padding(.top, 20)
                
                // Details Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DetailItem(icon: "thermometer.medium", label: "Feels Like", value: "\(Int(weather.apparentTemperature))°")
                    DetailItem(icon: "wind", label: "Wind", value: "\(Int(weather.windSpeed)) km/h")
                    DetailItem(icon: "humidity", label: "Humidity", value: "\(weather.humidity)%")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Forecast
                VStack(alignment: .leading, spacing: 12) {
                    Label("7-Day Forecast", systemImage: "calendar")
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
                                            .frame(width: 40, height: 4) // Simplified bar for now
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
                
                Link(destination: URL(string: "https://weather.apple.com")!) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                        Text("Open in Weather")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
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
    .padding()
}
