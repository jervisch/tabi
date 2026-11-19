import Foundation
import CoreLocation

/// Foreground-only location: samples while the app is using location (V1 policy).
final class RealLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let continuationBox = ContinuationBox()
    private var lastSample: LocationSample?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = true
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestWhenInUseAuthorization() async {
        switch manager.authorizationStatus {
        case .notDetermined:
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                continuationBox.start = cont
                manager.requestWhenInUseAuthorization()
            }
        default:
            break
        }
        manager.startUpdatingLocation()
    }

    func currentSample() async -> LocationSample? {
        if let lastSample, Date().timeIntervalSince(lastSample.timestamp) < 30 {
            return lastSample
        }
        return await withCheckedContinuation { (cont: CheckedContinuation<LocationSample?, Never>) in
            continuationBox.sample = cont
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.startUpdatingLocation()
            }
            self.continuationBox.resumeAuthIfNeeded()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let sample = LocationSample(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: max(location.horizontalAccuracy, 0),
            timestamp: location.timestamp
        )
        RecentLocationStore.shared.append(sample)
        Task { @MainActor in
            self.lastSample = sample
            self.continuationBox.resumeSample(with: sample)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuationBox.resumeSample(with: nil)
        }
    }
}

private final class ContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    var start: CheckedContinuation<Void, Never>?
    var sample: CheckedContinuation<LocationSample?, Never>?

    func resumeAuthIfNeeded() {
        lock.lock()
        let cont = start
        start = nil
        lock.unlock()
        cont?.resume()
    }

    func resumeSample(with sample: LocationSample?) {
        lock.lock()
        let cont = self.sample
        self.sample = nil
        lock.unlock()
        cont?.resume(returning: sample)
    }
}
