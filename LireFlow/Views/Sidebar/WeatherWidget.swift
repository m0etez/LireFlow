import SwiftUI

struct WeatherWidget: View {
    @StateObject private var weatherService = WeatherService()
    @ObservedObject private var configService = ConfigService.shared
    @State private var showingDetail = false
    @State private var hasLoaded = false
    
    var body: some View {
        Group {
            if weatherService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let weather = weatherService.currentWeather {
                HStack(spacing: 8) {
                    Image(systemName: weather.conditionIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(weather.conditionColor)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(Int(weather.temperature))°C")
                            .font(.system(size: 14, weight: .medium))
                        Text(weatherService.locationName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingDetail = true
                }
                .popover(isPresented: $showingDetail, arrowEdge: .bottom) {
                    WeatherDetailPopover(
                        weather: weather,
                        dailyForecasts: weatherService.dailyForecasts,
                        locationName: weatherService.locationName
                    )
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "cloud")
                        .foregroundStyle(.secondary)
                    Text("Weather")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .onTapGesture {
                    weatherService.requestLocation()
                }
            }
        }
        .task(id: configService.config.weatherLocation) {
            guard hasLoaded else {
                hasLoaded = true
                weatherService.requestLocation()
                return
            }
            // Location edited in Settings: wait for typing to settle, then refetch
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            weatherService.reload()
        }
    }
}

#Preview {
    WeatherWidget()
        .padding()
}

