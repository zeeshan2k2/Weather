import Combine
import CoreLocation
import Foundation

enum WeatherLocationError: LocalizedError {
    case accessDenied
    case locationUnknown

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Location access is off. Enable it in Settings to use your current location."
        case .locationUnknown:
            return "Couldn’t determine your location. Try again."
        }
    }
}

struct WeatherResolvedPlace: Sendable {
    var latitude: Double
    var longitude: Double
    var cityLine: String
    var timeZoneIdentifier: String
}

@MainActor
final class WeatherLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var authContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func resolveCurrentPlace() async throws -> WeatherResolvedPlace {
        try await ensureWhenInUseAuthorized()
        let location = try await requestOneShotLocation()
        return try await reverseGeocode(location)
    }

    private func ensureWhenInUseAuthorized() async throws {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied, .restricted:
            throw WeatherLocationError.accessDenied
        case .notDetermined:
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                return
            default:
                throw WeatherLocationError.accessDenied
            }
        @unknown default:
            throw WeatherLocationError.accessDenied
        }
    }

    private func requestOneShotLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> WeatherResolvedPlace {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<WeatherResolvedPlace, Error>) in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                Task { @MainActor in
                    let coord = location.coordinate
                    if error != nil {
                        continuation.resume(
                            returning: WeatherResolvedPlace(
                                latitude: coord.latitude,
                                longitude: coord.longitude,
                                cityLine: "Current location",
                                timeZoneIdentifier: TimeZone.current.identifier
                            )
                        )
                        return
                    }
                    guard let placemark = placemarks?.first else {
                        continuation.resume(
                            returning: WeatherResolvedPlace(
                                latitude: coord.latitude,
                                longitude: coord.longitude,
                                cityLine: "Current location",
                                timeZoneIdentifier: TimeZone.current.identifier
                            )
                        )
                        return
                    }
                    let label = Self.cityLabel(from: placemark)
                    let tzId = placemark.timeZone?.identifier ?? TimeZone.current.identifier
                    continuation.resume(
                        returning: WeatherResolvedPlace(
                            latitude: coord.latitude,
                            longitude: coord.longitude,
                            cityLine: label,
                            timeZoneIdentifier: tzId
                        )
                    )
                }
            }
        }
    }

    private static func cityLabel(from placemark: CLPlacemark) -> String {
        if let locality = placemark.locality, let country = placemark.country {
            return "\(locality), \(country)"
        }
        if let locality = placemark.locality {
            return locality
        }
        if let name = placemark.name, let country = placemark.country {
            return "\(name), \(country)"
        }
        if let admin = placemark.administrativeArea, let country = placemark.country {
            return "\(admin), \(country)"
        }
        return placemark.name ?? "Current location"
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            handleAuthorizationChange()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let continuation = locationContinuation else { return }
            locationContinuation = nil
            if let cl = error as? CLError {
                switch cl.code {
                case .denied:
                    continuation.resume(throwing: WeatherLocationError.accessDenied)
                case .locationUnknown:
                    continuation.resume(throwing: WeatherLocationError.locationUnknown)
                default:
                    continuation.resume(throwing: error)
                }
            } else {
                continuation.resume(throwing: error)
            }
        }
    }

    private func handleAuthorizationChange() {
        guard let continuation = authContinuation else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authContinuation = nil
            continuation.resume()
        case .denied, .restricted:
            authContinuation = nil
            continuation.resume(throwing: WeatherLocationError.accessDenied)
        case .notDetermined:
            break
        @unknown default:
            authContinuation = nil
            continuation.resume(throwing: WeatherLocationError.accessDenied)
        }
    }
}
