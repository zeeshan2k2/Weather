//
//  ContentView.swift
//  Weather
//
//  Created by Zeeshan Waheed on 24/03/2026.
//

import SwiftUI

struct day: Identifiable {
    let id: String
    var dayOfWeek: String
    var imageName: String
    var temperature: Int
}

struct ContentView: View {
    
    // Views are recreated on state changes, so local variables don’t persist.
    // @State stores the value outside the view and keeps it alive across re-renders.
    @State private var isNight = false
    @State private var weatherData: [day] = []
    @State private var currentTemp = 0
    @State private var currentWeatherCode = 0
    @State private var currentIsDay = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var useCelsius = false
    
    /// Hero icon follows the API (conditions + is_day). Theme only changes the background gradient.
    private var mainHeroSymbol: String {
        WeatherService.symbolName(for: currentWeatherCode, isDay: currentIsDay)
    }
    
    private func displayTemperature(fahrenheit: Int) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
    }
    
    private var unitSuffix: String {
        useCelsius ? "C" : "F"
    }
    
    @ViewBuilder
    private var bottomControlsBar: some View {
        VStack(spacing: 14) {
            if errorMessage != nil {
                Button {
                    Task { await loadWeather() }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.22))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
            
            HStack(alignment: .center) {
                Button {
                    useCelsius.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("°")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text(useCelsius ? "C" : "F")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                            )
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 12)
                    .padding(.trailing, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.42), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(useCelsius ? "Use Fahrenheit" : "Use Celsius")
                
                Spacer(minLength: 24)
                
                Button {
                    // Action: What the button does
                    isNight.toggle()
                } label: {
                    Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isNight ? Color(red: 0.25, green: 0.32, blue: 0.55) : Color.orange)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isNight ? "Switch to light theme" : "Switch to dark theme")
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    var body: some View {
        // layers of VStack
        ZStack {
            BackgroundView(isNight: $isNight)
                // ignoring the safe area such that the entire view is filled
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                }
                
                CityTextView(cityName: "Cupertino, CA")
                
                Group {
                    if isLoading && weatherData.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Updating weather…")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .frame(minHeight: 220)
                    } else if !weatherData.isEmpty {
                        MainWeatherView(
                            imageName: mainHeroSymbol,
                            temperature: displayTemperature(fahrenheit: currentTemp),
                            unit: unitSuffix
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                
                                // ForEach is used instead of a normal for loop because SwiftUI's body uses @ViewBuilder,
                                // which does not support traditional control flow like 'for'.
                                //
                                // ForEach is a special SwiftUI view that represents a dynamic collection of child views.
                                // It allows SwiftUI to:
                                // - track each item using identity (Identifiable)
                                // - efficiently update only the views that change
                                // - maintain a declarative view structure
                                //
                                // Each element in weatherData becomes a separate WeatherDayView,
                                // and SwiftUI uses the 'id' of each item to diff and re-render correctly.
                                ForEach(weatherData) { weather in
                                    WeatherDayView(
                                        dayOfWeek: weather.dayOfWeek,
                                        imageName: weather.imageName,
                                        temperature: displayTemperature(fahrenheit: weather.temperature),
                                        unit: unitSuffix
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomControlsBar
            }
        }
        .task {
            await loadWeather()
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let forecast = try await WeatherService.fetchCupertinoForecast()
            currentTemp = forecast.currentTempF
            currentWeatherCode = forecast.currentCode
            currentIsDay = forecast.currentIsDay
            weatherData = forecast.daily.map { item in
                day(
                    id: item.id,
                    dayOfWeek: item.weekdayAbbrev,
                    imageName: WeatherService.symbolName(for: item.weatherCode, isDay: true),
                    temperature: item.highTempF
                )
            }
        } catch {
            errorMessage = "Couldn’t load weather. Check your connection and try again."
        }
    }
}

struct WeatherDayView: View {
    
    var dayOfWeek: String
    var imageName: String
    var temperature: Int
    var unit: String = "F"
    
    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }
    
    var body: some View {
        VStack {
            Text(dayOfWeek)
                .foregroundStyle(Color.white)
            
            Image(systemName: imageName)
                .symbolRenderingMode(.multicolor)
                // almost always have to use the resizable
                .resizable()
                // defines the colors of the symbol; multiple colors are used if the rendering mode supports layered symbols
//                .foregroundStyle(.pink, .orange, .green)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(.white)
            
            Text("\(temperature)°\(unit)")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background {
            cellShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            cellShape
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
        }
    }
}

struct BackgroundView: View {
    
    // only using binding when whatever view ure passing the value to changes the variable.
    @Binding var isNight: Bool
    
    var body: some View {
        // adding gradients
//        LinearGradient(
//            gradient: Gradient(colors: [isNight ? .black : .blue, isNight ? .gray : .lightBlue]),
//            startPoint: .topLeading,
//            endPoint: .bottomTrailing
//        )
//        .ignoresSafeArea()
        
        ContainerRelativeShape()
            .fill(isNight ? Color.black.gradient : Color.blue.gradient)
            .ignoresSafeArea()
    }
}

struct CityTextView: View {
    
    var cityName: String
    
    var body: some View {
        Text(cityName)
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
            .padding()
    }
}

struct MainWeatherView: View {
    
    var imageName: String
    var temperature: Int
    var unit: String = "F"
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: imageName)
                .renderingMode(.original)
            // almost always have to use the resizable
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("\(temperature)°\(unit)")
                .font(.system(size: 68, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            
            
        }
        .padding(.bottom, 40)
    }
}


#Preview {
    ContentView()
}
