import Foundation
import CoreLocation

protocol PlaceGeocoding: Sendable {
    func reverse(latitude: Double, longitude: Double) async -> PlaceComponents
}

struct CLPlaceGeocoder: PlaceGeocoding {
    func reverse(latitude: Double, longitude: Double) async -> PlaceComponents {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            guard let mark = marks.first else {
                return PlaceComponents(country: JapanGeography.containsJapan(latitude: latitude, longitude: longitude) ? "Japan" : nil)
            }
            return PlaceComponents(
                prefecture: mark.administrativeArea ?? mark.subAdministrativeArea,
                city: mark.locality ?? mark.subLocality ?? mark.name,
                placeName: mark.thoroughfare ?? mark.name,
                country: mark.country
            )
        } catch {
            let inJapan = JapanGeography.containsJapan(latitude: latitude, longitude: longitude)
            return PlaceComponents(country: inJapan ? "Japan" : nil)
        }
    }
}

struct PlaceResolver {
    let geocoder: any PlaceGeocoding

    init(geocoder: any PlaceGeocoding = CLPlaceGeocoder()) {
        self.geocoder = geocoder
    }

    func resolve(sample: LocationSample) async -> PlaceComponents {
        var components = await geocoder.reverse(latitude: sample.latitude, longitude: sample.longitude)
        if components.country == nil {
            components.country = JapanGeography.containsJapan(latitude: sample.latitude, longitude: sample.longitude) ? "Japan" : nil
        }
        return components
    }
}
