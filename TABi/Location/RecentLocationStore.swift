import Foundation
import CoreLocation

/// Lightweight foreground dwell buffer. V1: no background tracking.
final class RecentLocationStore: @unchecked Sendable {
    static let shared = RecentLocationStore()

    private let lock = NSLock()
    private var samples: [LocationSample] = []
    private let maxCount = 500
    private let maxAge: TimeInterval = 24 * 3600

    init() {}

    func append(_ sample: LocationSample) {
        lock.lock()
        defer { lock.unlock() }
        samples.append(sample)
        let cutoff = sample.timestamp.addingTimeInterval(-maxAge)
        samples.removeAll { $0.timestamp < cutoff }
        if samples.count > maxCount {
            samples.removeFirst(samples.count - maxCount)
        }
    }

    func samples(since date: Date) -> [LocationSample] {
        lock.lock()
        defer { lock.unlock() }
        return samples.filter { $0.timestamp >= date }
    }

    func allSamples() -> [LocationSample] {
        lock.lock()
        defer { lock.unlock() }
        return samples
    }

    /// Dwell time (seconds) near a coordinate within radius meters while app open.
    func dwellSeconds(near coordinate: CLLocationCoordinate2D, radiusMeters: Double = 500) -> TimeInterval {
        let recent = allSamples().filter {
            $0.timestamp >= Date().addingTimeInterval(-12 * 3600)
        }
        guard recent.count >= 2 else { return 0 }
        let sorted = recent.sorted { $0.timestamp < $1.timestamp }
        var total: TimeInterval = 0
        for i in 1..<sorted.count {
            let a = sorted[i - 1]
            let b = sorted[i]
            let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
            let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
            guard locA.distance(from: locB) <= radiusMeters else { continue }
            let gap = b.timestamp.timeIntervalSince(a.timestamp)
            if gap > 0, gap < 30 * 60 {
                total += gap
            }
        }
        return total
    }

    func removeAll() {
        lock.lock()
        samples = []
        lock.unlock()
    }
}
