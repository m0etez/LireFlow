import SwiftUI

struct WeatherWidget: View {
    @StateObject private var weatherService = WeatherService()
    @State private var showingDetail = false
    @State private var animateGradient = false
    
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
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let weather = weatherService.currentWeather {
                VStack(alignment: .leading, spacing: 12) {
                    // Greeting
                    Text("Hi, the temperature is \(Int(weather.temperature))°")
                        .font(.system(size: 24, weight: .bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white)
                    
                    Text("and we are \(Date().formatted(.dateTime.weekday(.wide)))")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    HStack {
                        Image(systemName: weather.conditionIcon)
                            .font(.title2)
                            .symbolEffect(.bounce, value: weather.conditionIcon)
                        Text(weatherService.locationName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    LinearGradient(colors: weather.conditionGradient, startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing)
                        .hueRotation(.degrees(animateGradient ? 15 : 0)) // Reduced rotation to keep colors consistent with condition
                        .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: animateGradient)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    weatherService.requestLocation()
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "cloud")
                        .foregroundStyle(.secondary)
                    Text("Weather")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
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

