import Foundation
import CoreGraphics
import CoreLocation

/// Projects geographic coordinates into a view rect.
///
/// Mode `.fill` maps bounds linearly across the rect (non-uniform).
/// Main-island bounds are **calibrated against the artwork** (`japan_map_base.png`):
/// GeoJSON outlines were fitted to the illustration so markers and prefecture
/// fills land on the painted geography. The geographic dataset remains
/// authoritative for hit-testing.
struct JapanMapProjection {
    enum Mode {
        /// Linear lat/lon mapping across the full rect (artwork alignment).
        case fill
    }

    /// Mainland bounds — calibrated to `japan_map_base.png` (fit verified by
    /// overlaying GeoJSON prefecture outlines on the artwork).
    static let mainMinLat: Double = 27.7
    static let mainMaxLat: Double = 45.9
    static let mainMinLon: Double = 129.2
    static let mainMaxLon: Double = 146.3

    /// Okinawa inset bounds (app-defined inset card).
    static let insetMinLat: Double = 24.0
    static let insetMaxLat: Double = 28.5
    static let insetMinLon: Double = 122.5
    static let insetMaxLon: Double = 131.5

    let bounds: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)
    let rect: CGRect
    let mode: Mode

    init(rect: CGRect, mainIsland: Bool = true, mode: Mode = .fill) {
        self.rect = rect
        self.mode = mode
        if mainIsland {
            bounds = (Self.mainMinLat, Self.mainMaxLat, Self.mainMinLon, Self.mainMaxLon)
        } else {
            bounds = (Self.insetMinLat, Self.insetMaxLat, Self.insetMinLon, Self.insetMaxLon)
        }
    }

    static func isInMainBounds(_ lat: Double, _ lon: Double) -> Bool {
        lat >= mainMinLat && lat <= mainMaxLat && lon >= mainMinLon && lon <= mainMaxLon
    }

    static func isInOkinawaBounds(_ lat: Double, _ lon: Double) -> Bool {
        lat >= insetMinLat && lat <= insetMaxLat && lon >= insetMinLon && lon <= insetMaxLon
    }

    static func centroid(of ring: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !ring.isEmpty else { return nil }
        var lat = 0.0
        var lon = 0.0
        for c in ring {
            lat += c.latitude
            lon += c.longitude
        }
        let n = Double(ring.count)
        return CLLocationCoordinate2D(latitude: lat / n, longitude: lon / n)
    }

    /// Largest-area ring centroid (stable anchor for stamps).
    static func primaryCentroid(of shape: PrefectureShape) -> CLLocationCoordinate2D? {
        var best: (centroid: CLLocationCoordinate2D, area: Double)?
        for ring in shape.rings {
            guard let c = centroid(of: ring) else { continue }
            let area = abs(polygonArea(ring))
            if best == nil || area > best!.area {
                best = (c, area)
            }
        }
        return best?.centroid
    }

    private static func polygonArea(_ ring: [CLLocationCoordinate2D]) -> Double {
        guard ring.count > 2 else { return 0 }
        var sum = 0.0
        for i in 0..<ring.count {
            let a = ring[i]
            let b = ring[(i + 1) % ring.count]
            sum += a.longitude * b.latitude - b.longitude * a.latitude
        }
        return sum / 2
    }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        let lonSpan = bounds.maxLon - bounds.minLon
        let latSpan = bounds.maxLat - bounds.minLat
        guard lonSpan > 0, latSpan > 0 else { return CGPoint(x: rect.midX, y: rect.midY) }

        let x = rect.minX + CGFloat((coordinate.longitude - bounds.minLon) / lonSpan) * rect.width
        // Latitude increases upward; screen Y increases downward.
        let y = rect.minY + CGFloat((bounds.maxLat - coordinate.latitude) / latSpan) * rect.height
        return CGPoint(x: x, y: y)
    }

    func path(for ring: [CLLocationCoordinate2D]) -> CGPath {
        let path = CGMutablePath()
        guard let first = ring.first else { return path }
        let start = point(for: first)
        path.move(to: start)
        for coord in ring.dropFirst() {
            path.addLine(to: point(for: coord))
        }
        path.closeSubpath()
        return path
    }

    /// Geographic hit-test: prefecture ring contains the point (main map).
    static func prefecture(containing point: CGPoint, in rect: CGRect, shapes: [PrefectureShape]) -> PrefectureShape? {
        let projection = JapanMapProjection(rect: rect, mainIsland: true)
        for shape in shapes.reversed() {
            for ring in shape.rings {
                guard let centroid = Self.centroid(of: ring),
                      Self.isInMainBounds(centroid.latitude, centroid.longitude)
                else { continue }
                let path = projection.path(for: ring)
                if path.contains(point) {
                    return shape
                }
            }
        }
        return nil
    }
}
