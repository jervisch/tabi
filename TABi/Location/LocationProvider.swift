import Foundation
import CoreLocation

struct LocationSample: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@MainActor
protocol LocationProvider: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization() async
    func currentSample() async -> LocationSample?
}
