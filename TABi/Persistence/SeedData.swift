import Foundation
import SwiftData
import CoreLocation

enum SeedData {
    /// Bump when seed contents change so existing demo stores re-sync.
    private static let seedVersion = 2
    private static let seedVersionKey = "tabi.seedVersion"

    /// Inject demo memories + confirmed visits (DEBUG / -seedDemo).
    @MainActor
    static func load(into context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<Memory>())
        let defaults = UserDefaults.standard

        if !existing.isEmpty {
            // Never touch a store that contains real captures — real saves
            // always carry an image file name; seeds never do.
            if existing.contains(where: { $0.imageFileName != nil }) { return }
            // Placeholder-only demo store already at the current seed: done.
            if defaults.integer(forKey: seedVersionKey) == seedVersion { return }
            // Older demo seed — wipe memories + visits, then reseed below.
            for memory in existing { context.delete(memory) }
            for visit in try context.fetch(FetchDescriptor<Visit>()) {
                context.delete(visit)
            }
        }

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

        // All 47 Japanese prefectures with at least one major city
        let seeds: [Seed] = [
            // Hokkaido region
            Seed(city: "Sapporo", prefecture: "Hokkaido", prefectureID: "01", place: "Odori", lat: 43.0621, lon: 141.3548, date: day(2026, 1, 15, 11)),

            // Tohoku region
            Seed(city: "Aomori", prefecture: "Aomori", prefectureID: "02", place: "Rassunodai", lat: 40.8231, lon: 140.7423, date: day(2026, 1, 17, 10)),
            Seed(city: "Morioka", prefecture: "Iwate", prefectureID: "03", place: "Morioka-castle", lat: 39.7036, lon: 141.1527, date: day(2026, 1, 19, 11)),
            Seed(city: "Sendai", prefecture: "Miyagi", prefectureID: "04", place: "Aoba-dori", lat: 38.2688, lon: 140.8694, date: day(2026, 1, 21, 12)),
            Seed(city: "Akita", prefecture: "Akita", prefectureID: "05", place: "Takashimizu", lat: 39.7189, lon: 140.1099, date: day(2026, 1, 23, 11)),
            Seed(city: "Yamagata", prefecture: "Yamagata", prefectureID: "06", place: "Kajo-park", lat: 38.2452, lon: 140.3657, date: day(2026, 1, 25, 13)),
            Seed(city: "Fukushima", prefecture: "Fukushima", prefectureID: "07", place: "Ouchi-juku", lat: 37.7494, lon: 140.4681, date: day(2026, 1, 27, 12)),

            // Kanto region
            Seed(city: "Mito", prefecture: "Ibaraki", prefectureID: "08", place: "Kairaku-en", lat: 36.3418, lon: 140.4468, date: day(2026, 1, 29, 10)),
            Seed(city: "Utsunomiya", prefecture: "Tochigi", prefectureID: "09", place: "Futaarayama-jinja", lat: 36.5551, lon: 139.8828, date: day(2026, 1, 31, 11)),
            Seed(city: "Maebashi", prefecture: "Gunma", prefectureID: "10", place: "Maebashi-kaku", lat: 36.3912, lon: 139.0609, date: day(2026, 2, 2, 13)),
            Seed(city: "Saitama", prefecture: "Saitama", prefectureID: "11", place: "Omiya", lat: 35.9032, lon: 139.6098, date: day(2026, 2, 4, 10)),
            Seed(city: "Chiba", prefecture: "Chiba", prefectureID: "12", place: "Chiba-station", lat: 35.6047, lon: 140.1088, date: day(2026, 2, 6, 12)),
            Seed(city: "Tokyo", prefecture: "Tokyo", prefectureID: "13", place: "Shibuya", lat: 35.6595, lon: 139.7005, date: day(2026, 2, 8, 12)),
            Seed(city: "Yokohama", prefecture: "Kanagawa", prefectureID: "14", place: "Minato Mirai", lat: 35.4433, lon: 139.6382, date: day(2026, 2, 10, 11)),

            // Chubu region
            Seed(city: "Niigata", prefecture: "Niigata", prefectureID: "15", place: "Kosen", lat: 37.9159, lon: 139.0358, date: day(2026, 2, 12, 11)),
            Seed(city: "Toyama", prefecture: "Toyama", prefectureID: "16", place: "Toyama-port", lat: 36.6613, lon: 137.2151, date: day(2026, 2, 14, 12)),
            Seed(city: "Kanazawa", prefecture: "Ishikawa", prefectureID: "17", place: "Higashi-chaya", lat: 36.5946, lon: 136.6254, date: day(2026, 2, 16, 13)),
            Seed(city: "Echizen", prefecture: "Fukui", prefectureID: "18", place: "Echizen-sanso", lat: 36.0692, lon: 136.2168, date: day(2026, 2, 18, 12)),
            Seed(city: "Kofu", prefecture: "Yamanashi", prefectureID: "19", place: "Kofu-castle", lat: 35.6639, lon: 138.5789, date: day(2026, 2, 20, 10)),
            Seed(city: "Nagano", prefecture: "Nagano", prefectureID: "20", place: "Togakushi", lat: 36.6528, lon: 138.1824, date: day(2026, 2, 22, 11)),
            Seed(city: "Gifu", prefecture: "Gifu", prefectureID: "21", place: "Gifu-castle", lat: 35.4230, lon: 136.7498, date: day(2026, 2, 24, 12)),
            Seed(city: "Shizuoka", prefecture: "Shizuoka", prefectureID: "22", place: "Sun-en", lat: 35.2358, lon: 138.3813, date: day(2026, 2, 26, 11)),
            Seed(city: "Nagoya", prefecture: "Aichi", prefectureID: "23", place: "Osu", lat: 35.1733, lon: 136.8818, date: day(2026, 2, 28, 13)),
            Seed(city: "Ise", prefecture: "Mie", prefectureID: "24", place: "Ise-jingu", lat: 34.4544, lon: 136.7264, date: day(2026, 3, 2, 10)),

            // Kansai region
            Seed(city: "Otsu", prefecture: "Shiga", prefectureID: "25", place: "Biwa-ko", lat: 35.2550, lon: 135.8500, date: day(2026, 3, 4, 11)),
            Seed(city: "Kyoto", prefecture: "Kyoto", prefectureID: "26", place: "Gion", lat: 35.0037, lon: 135.7788, date: day(2026, 3, 6, 14)),
            Seed(city: "Osaka", prefecture: "Osaka", prefectureID: "27", place: "Dotonbori", lat: 34.6687, lon: 135.5013, date: day(2026, 3, 8, 19)),
            Seed(city: "Kobe", prefecture: "Hyogo", prefectureID: "28", place: "Kobe-port", lat: 34.6901, lon: 135.1951, date: day(2026, 3, 10, 11)),
            Seed(city: "Nara", prefecture: "Nara", prefectureID: "29", place: "Nara-park", lat: 34.6851, lon: 135.8026, date: day(2026, 3, 12, 10)),
            Seed(city: "Wakayama", prefecture: "Wakayama", prefectureID: "30", place: "Wakayama-castle", lat: 34.2260, lon: 135.1710, date: day(2026, 3, 14, 12)),

            // Chugoku region
            Seed(city: "Tottori", prefecture: "Tottori", prefectureID: "31", place: "Tottori-sakyu", lat: 35.5406, lon: 134.2287, date: day(2026, 3, 16, 11)),
            Seed(city: "Matsue", prefecture: "Shimane", prefectureID: "32", place: "Izumo-taisha", lat: 35.4019, lon: 132.6854, date: day(2026, 3, 18, 13)),
            Seed(city: "Okayama", prefecture: "Okayama", prefectureID: "33", place: "Korakuen", lat: 34.6457, lon: 133.9321, date: day(2026, 3, 20, 11)),
            Seed(city: "Hiroshima", prefecture: "Hiroshima", prefectureID: "34", place: "Hiroshima-castle", lat: 34.3852, lon: 132.4546, date: day(2026, 3, 22, 12)),
            Seed(city: "Yamaguchi", prefecture: "Yamaguchi", prefectureID: "35", place: "Kintai-kyo", lat: 34.0686, lon: 132.2082, date: day(2026, 3, 24, 11)),

            // Shikoku region
            Seed(city: "Tokushima", prefecture: "Tokushima", prefectureID: "36", place: "Tokushima-station", lat: 34.0657, lon: 134.5594, date: day(2026, 3, 26, 10)),
            Seed(city: "Takamatsu", prefecture: "Kagawa", prefectureID: "37", place: "Takamatsu-port", lat: 34.3399, lon: 134.0300, date: day(2026, 3, 28, 12)),
            Seed(city: "Matsuyama", prefecture: "Ehime", prefectureID: "38", place: "Matsuyama-castle", lat: 33.8394, lon: 132.7657, date: day(2026, 3, 30, 11)),
            Seed(city: "Kochi", prefecture: "Kochi", prefectureID: "39", place: "Kochi-castle", lat: 33.5594, lon: 133.5312, date: day(2026, 4, 1, 12)),

            // Kyushu region
            Seed(city: "Fukuoka", prefecture: "Fukuoka", prefectureID: "40", place: "Canal-city", lat: 33.5889, lon: 130.3997, date: day(2026, 4, 3, 11)),
            Seed(city: "Saga", prefecture: "Saga", prefectureID: "41", place: "Saga-city", lat: 33.2496, lon: 130.2935, date: day(2026, 4, 5, 10)),
            Seed(city: "Nagasaki", prefecture: "Nagasaki", prefectureID: "42", place: "Glover-garden", lat: 32.7512, lon: 129.8717, date: day(2026, 4, 7, 12)),
            Seed(city: "Kumamoto", prefecture: "Kumamoto", prefectureID: "43", place: "Kumamoto-castle", lat: 32.7825, lon: 130.7223, date: day(2026, 4, 9, 11)),
            Seed(city: "Oita", prefecture: "Oita", prefectureID: "44", place: "Oita-port", lat: 33.2295, lon: 131.6078, date: day(2026, 4, 11, 13)),
            Seed(city: "Miyazaki", prefecture: "Miyazaki", prefectureID: "45", place: "Miyazaki-jingugao", lat: 31.9172, lon: 131.4250, date: day(2026, 4, 13, 11)),
            Seed(city: "Kagoshima", prefecture: "Kagoshima", prefectureID: "46", place: "Sakurajima", lat: 31.5834, lon: 130.5613, date: day(2026, 4, 15, 12)),

            // Okinawa region
            Seed(city: "Naha", prefecture: "Okinawa", prefectureID: "47", place: "Kokusai-dori", lat: 26.2124, lon: 127.6808, date: day(2026, 4, 17, 12)),
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
        defaults.set(seedVersion, forKey: seedVersionKey)
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