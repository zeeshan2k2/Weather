import Foundation

enum TemperatureUnitDisplay {
    static func displayValue(fahrenheit: Int, useCelsius: Bool) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
    }
}
