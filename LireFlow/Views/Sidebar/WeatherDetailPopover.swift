import SwiftUI

struct WeatherDetailPopover: View {
    let weather: WeatherService.WeatherData
    let dailyForecasts: [WeatherService.DailyForecast]
    let locationName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Current conditions header
            HStack(spacing: 12) {
                Image(systemName: weather.conditionIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(weather.conditionColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(weather.temperature))°")
                        .font(.system(size: 42, weight: .light))
                    Text(weather.conditionDescription)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Location
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                Text(locationName)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailItem(icon: "thermometer.medium", label: "Feels Like", value: "\(Int(weather.apparentTemperature))°")
                DetailItem(icon: "wind", label: "Wind", value: "\(Int(weather.windSpeed)) km/h")
                DetailItem(icon: "humidity", label: "Humidity", value: "\(weather.humidity)%")
            }
            
            Divider()
            
            // 7-day forecast
            VStack(alignment: .leading, spacing: 8) {
                Text("7-Day Forecast")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(dailyForecasts) { day in
                    HStack {
                        Text(day.dayName)
                            .frame(width: 40, alignment: .leading)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: day.icon)
                            .foregroundStyle(day.iconColor)
                            .frame(width: 24)
                        
                        Spacer()
                        
                        Text("\(Int(day.temperatureMin))°")
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                        
                        // Temperature bar
                        GeometryReader { geo in
                            let range = maxTemp - minTemp
                            let lowOffset = range > 0 ? CGFloat(day.temperatureMin - minTemp) / CGFloat(range) : 0
                            let highOffset = range > 0 ? CGFloat(day.temperatureMax - minTemp) / CGFloat(range) : 1
                            
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.quaternary)
                                    .frame(height: 4)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .green, .yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * (highOffset - lowOffset), height: 4)
                                    .offset(x: geo.size.width * lowOffset)
                            }
                        }
                        .frame(width: 80, height: 4)
                        
                        Text("\(Int(day.temperatureMax))°")
                            .frame(width: 36, alignment: .trailing)
                    }
                    .font(.system(size: 13))
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.regularMaterial)
    }
    
    private var minTemp: Double {
        dailyForecasts.map(\.temperatureMin).min() ?? 0
    }
    
    private var maxTemp: Double {
        dailyForecasts.map(\.temperatureMax).max() ?? 30
    }
}

struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.system(size: 15, weight: .medium))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
