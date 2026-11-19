import XCTest
import SwiftData
@testable import TABi

@MainActor
final class DomainStoreTests: XCTestCase {
    private func makeStores() throws -> (MemoryStore, VisitStore) {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        return (MemoryStore(context: context), VisitStore(context: context))
    }

    private func sampleMemory(
        city: String = "Kyoto",
        prefecture: String = "Kyoto",
        accuracy: Double = 8,
        date: Date = Date()
    ) -> Memory {
        Memory(
            imageData: Data([0x00]),
            capturedAt: date,
            latitude: 35.0116,
            longitude: 135.7681,
            accuracy: accuracy,
            placeName: "Gion",
            city: city,
            prefecture: prefecture,
            country: "Japan"
        )
    }

    func testInsertAndFetchMemory() throws {
        let (memories, _) = try makeStores()
        let memory = sampleMemory()
        try memories.insert(memory)
        let fetched = try memories.all()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.city, "Kyoto")
        XCTAssertEqual(fetched.first?.placeName, "Gion")
    }

    func testVisitStatusRoundTrip() throws {
        let status = VisitStatus.confirmed
        XCTAssertEqual(VisitStatus(rawValue: status.rawValue), .confirmed)
        XCTAssertEqual(VisitStatus(rawValue: "candidate"), .candidate)
        XCTAssertEqual(VisitStatus(rawValue: "rejected"), .rejected)
        XCTAssertNil(VisitStatus(rawValue: "nope"))
    }

    func testConfirmedStatsCountUniquePrefecturesAndCities() throws {
        let (_, visits) = try makeStores()
        let now = Date()
        try visits.insert(Visit(placeName: "Gion", city: "Kyoto", prefecture: "Kyoto", startedAt: now, confidence: 0.9, status: .confirmed))
        try visits.insert(Visit(placeName: "Gion", city: "Kyoto", prefecture: "Kyoto", startedAt: now, confidence: 0.9, status: .confirmed))
        try visits.insert(Visit(placeName: "Dotonbori", city: "Osaka", prefecture: "Osaka", startedAt: now, confidence: 0.9, status: .confirmed))
        try visits.insert(Visit(city: "Shibuya", prefecture: "Tokyo", startedAt: now, confidence: 0.4, status: .candidate))

        let stats = try visits.confirmedStats()
        XCTAssertEqual(stats.prefectures, 2)
        XCTAssertEqual(stats.cities, 2)
        XCTAssertEqual(stats.caption, "2 / 47 prefectures · 2 cities")
    }

    func testTripGroupingSplitsOnLongGap() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 10))!
        let day5 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 22, hour: 10))!
        let memories = [
            sampleMemory(date: day1),
            sampleMemory(date: day5)
        ]
        let trips = TripGrouper.group(memories, calendar: calendar)
        XCTAssertEqual(trips.count, 2)
        XCTAssertEqual(trips[0].year, 2026)
        XCTAssertEqual(trips[0].title, "Kyoto")
    }

    func testTripGroupingKeepsSameCityOvernight() throws {
        let calendar = Calendar(identifier: .gregorian)
        let evening = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 21))!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 9))!
        let memories = [
            sampleMemory(date: evening),
            sampleMemory(date: morning)
        ]
        let trips = TripGrouper.group(memories, calendar: calendar)
        XCTAssertEqual(trips.count, 1)
        XCTAssertEqual(trips[0].memories.count, 2)
    }

    func testTripGroupingSplitsOnRegionChange() throws {
        let calendar = Calendar(identifier: .gregorian)
        let morning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 9))!
        let afternoon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 15))!

        // Same-day cross-region excursion (< 12h gap) stays one trip —
        // documented rule: "date gap > 2 days OR region change with gap > 12h".
        let dayTrip = [
            sampleMemory(city: "Tokyo", prefecture: "Tokyo", date: morning),
            sampleMemory(city: "Kyoto", prefecture: "Kyoto", date: afternoon)
        ]
        XCTAssertEqual(TripGrouper.group(dayTrip, calendar: calendar).count, 1)

        // Region change with gap > 12h starts a new trip.
        let nextMorning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 9))!
        let splitTrip = [
            sampleMemory(city: "Tokyo", prefecture: "Tokyo", date: morning),
            sampleMemory(city: "Kyoto", prefecture: "Kyoto", date: nextMorning)
        ]
        XCTAssertEqual(TripGrouper.group(splitTrip, calendar: calendar).count, 2)
    }

    func testPlaceComponentsJapanDetection() {
        XCTAssertTrue(PlaceComponents(prefecture: "Kyoto", city: "Kyoto", placeName: nil, country: "Japan").isInJapan)
        XCTAssertFalse(PlaceComponents(prefecture: nil, city: nil, placeName: nil, country: "France").isInJapan)
        XCTAssertTrue(PlaceComponents(prefecture: nil, city: "Kyoto", placeName: nil, country: "Japan").hasJapanAdmin)
    }
}
