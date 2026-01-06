import SwiftUI

struct WeatherWidget: View {
    @StateObject private var weatherService = WeatherService()
    @ObservedObject private var configService = ConfigService.shared
    @State private var showingDetail = false
    @State private var animateGradient = false
    
    var body: some View {
        Group {
            if weatherService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(NSLocalizedString("Loading...", comment: "Weather loading state"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let weather = weatherService.currentWeather {
                VStack(alignment: .leading, spacing: 12) {
                    // Greeting text
                    Text(String(format: NSLocalizedString("Hi, the temperature is %lld°", comment: "Weather greeting"), Int(weather.temperature)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(String(format: NSLocalizedString("and we are %@", comment: "Weather day"), Date().formatted(.dateTime.weekday(.wide))))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    HStack {
                        Image(systemName: weather.conditionIcon)
                            .font(.title2)
                            .symbolEffect(.bounce, value: weather.conditionIcon)
                        
                        Text(weatherService.locationName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(weather.conditionDescription)
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    ZStack {
                        LinearGradient(
                            colors: weather.conditionGradient,
                            startPoint: animateGradient ? .topLeading : .bottomLeading,
                            endPoint: animateGradient ? .bottomTrailing : .topTrailing
                        )
                        .hueRotation(.degrees(animateGradient ? 10 : 0))
                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: animateGradient)
                        
                        WeatherAnimationView(weatherCode: weather.weatherCode, isDay: weather.isDay)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .contentShape(Rectangle())
                .onAppear {
                    animateGradient = true
                }
                .onTapGesture {
                    showingDetail = true
                }
                .sheet(isPresented: $showingDetail) {
                    WeatherDetailPopover(
                        weather: weather,
                        dailyForecasts: weatherService.dailyForecasts,
                        locationName: weatherService.locationName
                    )
                    #if os(macOS)
                    .frame(width: 400, height: 600)
                    #endif
                }
            } else if let error = weatherService.error {
                 HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.platformSecondaryBackground)
                }
                .onTapGesture {
                    weatherService.requestLocation()
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "cloud")
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("Weather", comment: "Weather placeholder"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.platformSecondaryBackground)
                }
                .onTapGesture {
                    weatherService.requestLocation()
                }
            }
        }
        .onAppear {
            weatherService.requestLocation()
        }
    }

}

#Preview {
    WeatherWidget()
        .padding()
}



