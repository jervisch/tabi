import Foundation
import SwiftData

enum SeedData {
    /// Inject demo memories + confirmed visits (DEBUG / -seedDemo).
    @MainActor
    static func load(into context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<Memory>())
        guard existing.isEmpty else { return }

        let calendar = Calendar(identifier: .gregorian)
        let day = { (y: Int, m: Int, d: Int, h: Int) -> Date in
            calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h)) ?? Date()
        }

        struct Seed {
            let city: String
            let prefecture: String
            let prefectureID: String
            let place: String
            let lat: Double
            let lon: Double
            let date: Date
        }

        let seeds: [Seed] = [
            Seed(city: "Kyoto", prefecture: "Kyoto", prefectureID: "26", place: "Gion", lat: 35.0037, lon: 135.7788, date: day(2026, 3, 18, 14)),
            Seed(city: "Kyoto", prefecture: "Kyoto", prefectureID: "26", place: "Kiyomizu", lat: 34.9949, lon: 135.7850, date: day(2026, 3, 18, 16)),
            Seed(city: "Kyoto", prefecture: "Kyoto", prefectureID: "26", place: "Arashiyama", lat: 35.0170, lon: 135.6710, date: day(2026, 3, 19, 10)),
            Seed(city: "Osaka", prefecture: "Osaka", prefectureID: "27", place: "Dotonbori", lat: 34.6687, lon: 135.5013, date: day(2026, 3, 20, 19)),
            Seed(city: "Tokyo", prefecture: "Tokyo", prefectureID: "13", place: "Shibuya", lat: 35.6595, lon: 139.7005, date: day(2026, 3, 21, 12)),
        ]

        var visitIDs: [String: UUID] = [:]

        for seed in seeds {
            let visitKey = "\(seed.prefecture)/\(seed.city)"
            let visitID: UUID
            if let existingID = visitIDs[visitKey] {
                visitID = existingID
            } else {
                let visit = Visit(
                    placeName: seed.place,
                    city: seed.city,
                    prefecture: seed.prefecture,
                    startedAt: seed.date,
                    endedAt: seed.date.addingTimeInterval(3600),
                    confidence: 0.95,
                    status: .confirmed
                )
                context.insert(visit)
                visitIDs[visitKey] = visit.id
                visitID = visit.id
            }

            let memory = Memory(
                imageData: Self.placeholderImageData(),
                capturedAt: seed.date,
                latitude: seed.lat,
                longitude: seed.lon,
                accuracy: 8,
                placeName: seed.place,
                city: seed.city,
                prefecture: seed.prefecture,
                country: "Japan",
                visitID: visitID
            )
            context.insert(memory)
        }

        try context.save()
    }

    /// Tiny solid JPEG-ish PNG bytes so galleries have something to show in seed mode.
    private static func placeholderImageData() -> Data {
        // 1x1 light gray PNG
        let bytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
            0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
            0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
        ]
        return Data(bytes)
    }
}
