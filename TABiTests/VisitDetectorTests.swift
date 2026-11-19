import XCTest
import SwiftData
@testable import TABi

@MainActor
final class VisitDetectorTests: XCTestCase {
    private func makeEnv() throws -> VisitStore {
        let container = try ModelContainerFactory.make(inMemory: true)
        return VisitStore(context: ModelContext(container))
    }

    private var kyoto: PlaceComponents {
        PlaceComponents(prefecture: "Kyoto", city: "Kyoto", placeName: "Gion", country: "Japan")
    }

    func testHighAccuracyConfirmedVisit() throws {
        let store = try makeEnv()
        let memory = Memory(
            imageData: Data([1]),
            latitude: 35.0116,
            longitude: 135.7681,
            accuracy: 8,
            placeName: "Gion",
            city: "Kyoto",
            prefecture: "Kyoto",
            country: "Japan"
        )
        let visit = try VisitDetector.attach(
            memory: memory,
            components: kyoto,
            accuracy: 8,
            dwellSeconds: 2 * 3600,
            store: store
        )
        XCTAssertEqual(visit?.status, .confirmed)
        XCTAssertEqual(visit?.confidence ?? 0, 1.0, accuracy: 0.001)
        XCTAssertEqual(memory.visitID, visit?.id)
        XCTAssertEqual(try store.confirmedStats().prefectures, 1)
    }

    func testPoorAccuracyLowConfidenceBecomesCandidate() throws {
        let store = try makeEnv()
        let memory = Memory(
            imageData: Data([1]),
            latitude: 35.0,
            longitude: 135.0,
            accuracy: 250,
            city: "Kyoto",
            prefecture: "Kyoto",
            country: "Japan"
        )
        let visit = try VisitDetector.attach(
            memory: memory,
            components: PlaceComponents(prefecture: "Kyoto", city: "Kyoto", placeName: nil, country: "Japan"),
            accuracy: 250,
            dwellSeconds: 0,
            store: store
        )
        // 0.55 only → candidate
        XCTAssertEqual(visit?.status, .candidate)
        XCTAssertEqual(try store.confirmedStats().prefectures, 0)
    }

    func testSecondPhotoExtendsSameVisit() throws {
        let store = try makeEnv()
        let first = Memory(imageData: Data([1]), latitude: 35, longitude: 135, accuracy: 8, city: "Kyoto", prefecture: "Kyoto", country: "Japan")
        let second = Memory(imageData: Data([2]), latitude: 35, longitude: 135, accuracy: 8, city: "Kyoto", prefecture: "Kyoto", country: "Japan")

        let v1 = try VisitDetector.attach(memory: first, components: kyoto, accuracy: 8, dwellSeconds: 1200, store: store)
        let v2 = try VisitDetector.attach(memory: second, components: kyoto, accuracy: 8, dwellSeconds: 1200, store: store)

        XCTAssertEqual(v1?.id, v2?.id)
        XCTAssertEqual(try store.all().count, 1)
    }

    func testOutsideJapanDoesNotCreateJapanVisit() throws {
        let store = try makeEnv()
        let memory = Memory(imageData: Data([1]), latitude: 48.8, longitude: 2.3, accuracy: 10, country: "France")
        let visit = try VisitDetector.attach(
            memory: memory,
            components: PlaceComponents(country: "France"),
            accuracy: 10,
            dwellSeconds: 0,
            store: store
        )
        XCTAssertNil(visit)
        XCTAssertEqual(try store.confirmedStats().prefectures, 0)
    }

    func testEvaluateFormula() {
        let (conf, trackable) = VisitDetector.evaluate(components: kyoto, accuracy: 8, dwellSeconds: 2 * 3600)
        XCTAssertTrue(trackable)
        XCTAssertEqual(conf, 1.0, accuracy: 0.001)

        let (low, trackable2) = VisitDetector.evaluate(components: kyoto, accuracy: 200, dwellSeconds: 0)
        XCTAssertTrue(trackable2)
        XCTAssertEqual(low, 0.55, accuracy: 0.001)

        XCTAssertEqual(VisitDetector.status(for: 0.7), .confirmed)
        XCTAssertEqual(VisitDetector.status(for: 0.69), .candidate)
    }
}
