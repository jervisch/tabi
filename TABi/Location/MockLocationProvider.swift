import Foundation
import CoreLocation

/// Scripted location timeline for tests and previews.
final class MockLocationProvider: LocationProvider {
    private var timeline: [LocationSample]
    private var index = 0
    var authorizationStatus: CLAuthorizationStatus
    private(set) var requestedAuthorization = false

    init(
        timeline: [LocationSample] = [],
        authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    ) {
        self.timeline = timeline
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() async {
        requestedAuthorization = true
        if authorizationStatus == .notDetermined {
            authorizationStatus = .authorizedWhenInUse
        }
    }

    func currentSample() async -> LocationSample? {
        guard !timeline.isEmpty else { return nil }
        let sample = timeline[min(index, timeline.count - 1)]
        if index < timeline.count - 1 { index += 1 }
        return sample
    }

    func append(_ sample: LocationSample) {
        timeline.append(sample)
    }

    static func sample(
        lat: Double,
        lon: Double,
        accuracy: Double = 8,
        at date: Date = Date()
    ) -> LocationSample {
        LocationSample(latitude: lat, longitude: lon, accuracy: accuracy, timestamp: date)
    }
}
