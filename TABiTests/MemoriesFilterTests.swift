import XCTest
@testable import TABi

final class MemoriesFilterTests: XCTestCase {
    private func mem(city: String, date: Date) -> Memory {
        Memory(
            imageData: Data([1]),
            capturedAt: date,
            latitude: 0,
            longitude: 0,
            accuracy: 10,
            city: city,
            prefecture: city == "Kyoto" ? "Kyoto" : "Osaka",
            country: "Japan"
        )
    }

    func testFilterByCityAndDateRange() {
        let cal = Calendar(identifier: .gregorian)
        let d1 = cal.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let d2 = cal.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let d3 = cal.date(from: DateComponents(year: 2026, month: 4, day: 5))!
        let memories = [
            mem(city: "Kyoto", date: d1),
            mem(city: "Kyoto", date: d2),
            mem(city: "Osaka", date: d3)
        ]

        let kyotoOnly = MemoriesFilterLogic.filter(memories, prefecture: nil, city: "Kyoto", from: nil, to: nil)
        XCTAssertEqual(kyotoOnly.count, 2)

        let march = MemoriesFilterLogic.filter(
            memories,
            prefecture: nil,
            city: nil,
            from: cal.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            to: cal.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        )
        XCTAssertEqual(march.count, 2)

        let kyotoMarch = MemoriesFilterLogic.filter(
            memories,
            prefecture: "Kyoto",
            city: nil,
            from: cal.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            to: cal.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        )
        XCTAssertEqual(kyotoMarch.count, 2)
    }
}
