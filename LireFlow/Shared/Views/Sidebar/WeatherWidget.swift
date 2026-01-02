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
                    ZStack {
                        LinearGradient(colors: weather.conditionGradient, startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing)
                            .hueRotation(.degrees(animateGradient ? 15 : 0))
                            .animation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true), value: animateGradient)
                        
                        WeatherAnimationView(weatherCode: weather.weatherCode, isDay: weather.isDay)
                    }
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


// MARK: - Weather Animation View

struct WeatherAnimationView: View {
    let weatherCode: Int
    let isDay: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base atmospheric effects
                switch weatherCode {
                case 0: // Clear
                    if isDay {
                        SunEffect(geometry: geometry)
                    } else {
                        MoonEffect(geometry: geometry)
                    }
                case 1, 2: // Partly Cloudy
                    CloudEffect(geometry: geometry, count: 2, speed: 10)
                    if isDay { SunEffect(geometry: geometry).opacity(0.5) }
                case 3, 45, 48: // Overcast / Fog
                    CloudEffect(geometry: geometry, count: 5, speed: 20)
                case 51...57, 61...67, 80...82: // Rain
                    CloudEffect(geometry: geometry, count: 6, speed: 15).opacity(0.7)
                    RainEffect(geometry: geometry)
                case 71...77, 85, 86: // Snow
                    CloudEffect(geometry: geometry, count: 4, speed: 10).opacity(0.5)
                    SnowEffect(geometry: geometry)
                case 95...99: // Thunderstorm
                    CloudEffect(geometry: geometry, count: 6, speed: 25)
                    RainEffect(geometry: geometry)
                    ThunderEffect()
                default:
                    EmptyView()
                }
            }
        }
        .allowsHitTesting(false) // Pass touches through
    }
}

// MARK: - Effects

struct SunEffect: View {
    let geometry: GeometryProxy
    @State private var rotate = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Sun glint
            Circle()
                .fill(
                    RadialGradient(colors: [.white.opacity(0.3), .yellow.opacity(0.0)], center: .center, startRadius: 0, endRadius: 100)
                )
                .frame(width: 200, height: 200)
                .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                .scaleEffect(pulse ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)
            
            // Rays
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 300)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .offset(y: -150)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotate = true
            }
            withAnimation {
                pulse = true
            }
        }
    }
}

struct MoonEffect: View {
    let geometry: GeometryProxy
    @State private var shine = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [.white.opacity(0.2), .clear], center: .center, startRadius: 10, endRadius: 80)
                )
                .frame(width: 100, height: 100)
                .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.25)
                .opacity(shine ? 0.8 : 0.4)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: shine)
            
            // Stars
            ForEach(0..<10) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height * 0.6)
                    )
                    .opacity(shine ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...3))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: shine
                    )
            }
        }
        .onAppear {
            shine = true
        }
    }
}

struct CloudEffect: View {
    let geometry: GeometryProxy
    let count: Int
    let speed: Double
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Image(systemName: "cloud.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: CGFloat.random(in: 50...120))
                    .foregroundStyle(.white.opacity(Double.random(in: 0.1...0.25)))
                    .position(
                        x: geometry.size.width * (Double(i) / Double(count)) + (i % 2 == 0 ? 50 : -50),
                        y: CGFloat.random(in: 20...geometry.size.height * 0.6)
                    )
                    .offset(x: offset * (i % 2 == 0 ? 1 : -1) * CGFloat(i + 1))
                    .blur(radius: 5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: speed).repeatForever(autoreverses: true)) {
                offset = 30
            }
        }
    }
}

struct RainEffect: View {
    let geometry: GeometryProxy
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<30 {
                    let speed = Double(200 + (i * 5))
                    let y = (Double(i) * 50 + time * speed).truncatingRemainder(dividingBy: size.height + 100) - 50
                    let x = (Double(i * 37)).truncatingRemainder(dividingBy: size.width)
                    
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: y))
                        p.addLine(to: CGPoint(x: x - 5, y: y + 20))
                    }
                    
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1.5)
                }
            }
        }
    }
}

struct SnowEffect: View {
    let geometry: GeometryProxy
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<40 {
                    let speed = Double(50 + (i * 2))
                    let y = (Double(i) * 20 + time * speed).truncatingRemainder(dividingBy: size.height + 50) - 20
                    let xOffset = sin(time + Double(i)) * 20
                    let x = (Double(i * 29)).truncatingRemainder(dividingBy: size.width) + xOffset
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3)),
                        with: .color(.white.opacity(0.6))
                    )
                }
            }
        }
    }
}

struct ThunderEffect: View {
    @State private var flash = false
    
    var body: some View {
        Rectangle()
            .fill(.white)
            .opacity(flash ? 0.3 : 0.0)
            .ignoresSafeArea()
            .onAppear {
                runFlashCycle()
            }
    }
    
    func runFlashCycle() {
        let randomDelay = Double.random(in: 4...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            // Flash on
            withAnimation(.easeIn(duration: 0.1)) {
                flash = true
            }
            
            // Flash off quickly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.1)) {
                    flash = false
                }
                // Double flash sometimes
                if Bool.random() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeIn(duration: 0.05)) {
                            flash = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                flash = false
                            }
                        }
                    }
                }
                
                runFlashCycle()
            }
        }
    }
}
