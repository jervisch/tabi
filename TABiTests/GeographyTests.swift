import XCTest
import CoreLocation
@testable import TABi

final class GeographyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        JapanGeography.resetCacheForTesting()
    }

    func testLoadsFortySevenPrefectures() {
        let shapes = JapanGeography.prefectures()
        XCTAssertEqual(shapes.count, 47, "Expected 47 prefectures, got \(shapes.count)")
        XCTAssertEqual(Set(shapes.map(\.id)).count, 47)
        XCTAssertTrue(shapes.contains { $0.nameEn.lowercased().contains("kyoto") })
        XCTAssertTrue(shapes.contains { $0.nameJa == "京都府" })
    }

    func testPrefectureRingsAreNonEmpty() {
        for shape in JapanGeography.prefectures() {
            XCTAssertFalse(shape.rings.isEmpty, "\(shape.id) missing rings")
            for ring in shape.rings {
                XCTAssertGreaterThanOrEqual(ring.count, 3, "\(shape.id) ring too small")
            }
        }
    }

    func testContainsJapan() {
        XCTAssertTrue(JapanGeography.containsJapan(latitude: 35.0116, longitude: 135.7681), "Kyoto")
        XCTAssertFalse(JapanGeography.containsJapan(latitude: 48.8566, longitude: 2.3522), "Paris")
        XCTAssertFalse(JapanGeography.containsJapan(latitude: 40.7128, longitude: -74.0060), "NYC")
    }

    func testCityPointsByPrefecture() {
        let kyotoCities = JapanGeography.cityPoints(prefectureID: "26")
        XCTAssertTrue(kyotoCities.contains { $0.id == "kyoto" })
        XCTAssertFalse(kyotoCities.contains { $0.id == "osaka" })
        XCTAssertGreaterThanOrEqual(JapanGeography.cityPoints().count, 15)
    }

    func testParseSampleFeature() throws {
        let json = """
        {"type":"FeatureCollection","features":[
          {"type":"Feature","properties":{"id":26,"nameEn":"Kyoto Fu","nameJa":"京都府"},
           "geometry":{"type":"Polygon","coordinates":[[[135.0,35.0],[135.1,35.0],[135.1,35.1],[135.0,35.0]]]}}
        ]}
        """
        let shapes = try JapanGeography.parse(data: Data(json.utf8))
        XCTAssertEqual(shapes.count, 1)
        XCTAssertEqual(shapes[0].id, "26")
        XCTAssertEqual(shapes[0].rings.first?.count, 4)
    }
}
