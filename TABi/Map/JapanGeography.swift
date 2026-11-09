import Foundation
import CoreLocation

enum JapanGeography {
    private static let japanNorth: Double = 45.6
    private static let japanSouth: Double = 20.4
    private static let japanWest: Double = 122.9
    private static let japanEast: Double = 153.99

    /// Major city points for V1 drill-down markers (expandable).
    private static let seedCities: [CityPoint] = [
        CityPoint(id: "tokyo", nameEn: "Tokyo", nameJa: "東京", prefectureID: "13", coordinate: .init(latitude: 35.6762, longitude: 139.6503)),
        CityPoint(id: "yokohama", nameEn: "Yokohama", nameJa: "横浜", prefectureID: "14", coordinate: .init(latitude: 35.4437, longitude: 139.6380)),
        CityPoint(id: "osaka", nameEn: "Osaka", nameJa: "大阪", prefectureID: "27", coordinate: .init(latitude: 34.6937, longitude: 135.5023)),
        CityPoint(id: "kyoto", nameEn: "Kyoto", nameJa: "京都", prefectureID: "26", coordinate: .init(latitude: 35.0116, longitude: 135.7681)),
        CityPoint(id: "nagoya", nameEn: "Nagoya", nameJa: "名古屋", prefectureID: "23", coordinate: .init(latitude: 35.1815, longitude: 136.9066)),
        CityPoint(id: "sapporo", nameEn: "Sapporo", nameJa: "札幌", prefectureID: "01", coordinate: .init(latitude: 43.0618, longitude: 141.3545)),
        CityPoint(id: "fukuoka", nameEn: "Fukuoka", nameJa: "福岡", prefectureID: "40", coordinate: .init(latitude: 33.5904, longitude: 130.4017)),
        CityPoint(id: "hiroshima", nameEn: "Hiroshima", nameJa: "広島", prefectureID: "34", coordinate: .init(latitude: 34.3853, longitude: 132.4553)),
        CityPoint(id: "sendai", nameEn: "Sendai", nameJa: "仙台", prefectureID: "04", coordinate: .init(latitude: 38.2682, longitude: 140.8694)),
        CityPoint(id: "nara", nameEn: "Nara", nameJa: "奈良", prefectureID: "29", coordinate: .init(latitude: 34.6851, longitude: 135.8048)),
        CityPoint(id: "kobe", nameEn: "Kobe", nameJa: "神戸", prefectureID: "28", coordinate: .init(latitude: 34.6901, longitude: 135.1956)),
        CityPoint(id: "kanazawa", nameEn: "Kanazawa", nameJa: "金沢", prefectureID: "17", coordinate: .init(latitude: 36.5613, longitude: 136.6562)),
        CityPoint(id: "takamatsu", nameEn: "Takamatsu", nameJa: "高松", prefectureID: "37", coordinate: .init(latitude: 34.3401, longitude: 134.0434)),
        CityPoint(id: "matsuyama", nameEn: "Matsuyama", nameJa: "松山", prefectureID: "38", coordinate: .init(latitude: 33.8392, longitude: 132.7657)),
        CityPoint(id: "naha", nameEn: "Naha", nameJa: "那覇", prefectureID: "47", coordinate: .init(latitude: 26.2124, longitude: 127.6809)),
        CityPoint(id: "niigata", nameEn: "Niigata", nameJa: "新潟", prefectureID: "15", coordinate: .init(latitude: 37.9161, longitude: 139.0364)),
        CityPoint(id: "okayama", nameEn: "Okayama", nameJa: "岡山", prefectureID: "33", coordinate: .init(latitude: 34.6551, longitude: 133.9195)),
        CityPoint(id: "kumamoto", nameEn: "Kumamoto", nameJa: "熊本", prefectureID: "43", coordinate: .init(latitude: 32.7898, longitude: 130.7417)),
        CityPoint(id: "nagasaki", nameEn: "Nagasaki", nameJa: "長崎", prefectureID: "42", coordinate: .init(latitude: 32.7503, longitude: 129.8779)),
        CityPoint(id: "toyama", nameEn: "Toyama", nameJa: "富山", prefectureID: "16", coordinate: .init(latitude: 36.6953, longitude: 137.2113)),
    ]

    private static let cache = GeometryCache()

    static func prefectures() -> [PrefectureShape] {
        cache.prefectures()
    }

    static func prefecture(id: String) -> PrefectureShape? {
        cache.prefectures().first { $0.id == id }
    }

    static func cityPoints(prefectureID: String? = nil) -> [CityPoint] {
        if let prefectureID {
            return seedCities.filter { $0.prefectureID == prefectureID }
        }
        return seedCities
    }

    static func cityPoint(id: String) -> CityPoint? {
        seedCities.first { $0.id == id }
    }

    /// Rough Japan + surrounding waters bounding box (for visit / outside-Japan UI).
    static func containsJapan(latitude: Double, longitude: Double) -> Bool {
        latitude >= japanSouth && latitude <= japanNorth &&
        longitude >= japanWest && longitude <= japanEast
    }

    static func resetCacheForTesting() {
        cache.reset()
    }

    /// Parse GeoJSON data into prefecture shapes (used by loader and tests).
    static func parse(data: Data) throws -> [PrefectureShape] {
        try GeometryCache.parse(data: data)
    }
}

private final class GeometryCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cached: [PrefectureShape]?

    func prefectures() -> [PrefectureShape] {
        lock.lock()
        defer { lock.unlock() }
        if let cached { return cached }
        let loaded = (try? Self.load()) ?? []
        cached = loaded
        return loaded
    }

    func reset() {
        lock.lock()
        cached = nil
        lock.unlock()
    }

    private static func load() throws -> [PrefectureShape] {
        guard let url = Bundle.main.url(forResource: "japan_prefectures", withExtension: "geojson") else {
            // Test bundles may not link app resources the same way — try module bundle.
            guard let alt = Bundle(for: GeometryMarker.self).url(forResource: "japan_prefectures", withExtension: "geojson")
            else { throw JapanGeographyError.missingResource }
            return try load(url: alt)
        }
        return try load(url: url)
    }

    private static func load(url: URL) throws -> [PrefectureShape] {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    static func parse(data: Data) throws -> [PrefectureShape] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = root["features"] as? [[String: Any]] else {
            throw JapanGeographyError.decodeFailed
        }

        var shapes: [PrefectureShape] = []
        for feature in features {
            guard let props = feature["properties"] as? [String: Any],
                  let geom = feature["geometry"] as? [String: Any],
                  let type = geom["type"] as? String,
                  let coords = geom["coordinates"] else { continue }

            let id: String
            if let idNum = props["id"] as? Int {
                id = String(format: "%02d", idNum)
            } else if let idStr = props["id"] as? String {
                id = idStr
            } else { continue }

            let nameEn = props["nameEn"] as? String ?? ""
            let nameJa = props["nameJa"] as? String ?? ""
            let rings = ringsFrom(geometryType: type, coordinates: coords)
            guard !rings.isEmpty else { continue }
            shapes.append(PrefectureShape(id: id, nameEn: nameEn, nameJa: nameJa, rings: rings))
        }
        shapes.sort { $0.id < $1.id }
        return shapes
    }

    private static func ringsFrom(geometryType: String, coordinates: Any) -> [[CLLocationCoordinate2D]] {
        var rings: [[CLLocationCoordinate2D]] = []
        if geometryType == "Polygon", let polys = coordinates as? [[[Any]]] {
            for poly in polys {
                if let outer = poly.first {
                    rings.append(coords(outer))
                }
            }
        } else if geometryType == "MultiPolygon", let multi = coordinates as? [[[[Any]]]] {
            for poly in multi {
                if let outer = poly.first {
                    rings.append(coords(outer))
                }
            }
        }
        return rings
    }

    private static func coords(_ ring: [Any]) -> [CLLocationCoordinate2D] {
        ring.compactMap { pair in
            guard let pair = pair as? [Any], pair.count >= 2,
                  let lon = pair[0] as? Double,
                  let lat = pair[1] as? Double else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

/// Marker type for bundle lookup in tests.
final class GeometryMarker {}
