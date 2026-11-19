import Foundation
import CoreLocation

struct PrefectureShape: Identifiable {
    /// JIS prefecture code as string, e.g. "26"
    let id: String
    let nameEn: String
    let nameJa: String
    /// Exterior rings (one or more polygons). Each ring is closed (first == last).
    let rings: [[CLLocationCoordinate2D]]
}

struct CityPoint: Identifiable {
    let id: String
    let nameEn: String
    let nameJa: String
    let prefectureID: String
    let coordinate: CLLocationCoordinate2D
}

enum JapanGeographyError: Error {
    case missingResource
    case decodeFailed
}
