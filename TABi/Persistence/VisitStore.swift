import Foundation
import SwiftData

struct AtlasStats: Equatable {
    let prefectures: Int
    let cities: Int

    var caption: String {
        "\(prefectures) / 47 prefectures · \(cities) cities"
    }

    static let empty = AtlasStats(prefectures: 0, cities: 0)
}

@MainActor
final class VisitStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func insert(_ visit: Visit) throws {
        context.insert(visit)
        try context.save()
    }

    func all() throws -> [Visit] {
        try context.fetch(FetchDescriptor<Visit>())
    }

    func confirmed() throws -> [Visit] {
        try all().filter(\.isConfirmed)
    }

    func confirmedStats() throws -> AtlasStats {
        let visits = try confirmed()
        let prefectures = Set(visits.map(\.prefecture))
        let cities = Set(visits.map { "\($0.prefecture)/\($0.city)" })
        return AtlasStats(prefectures: prefectures.count, cities: cities.count)
    }

    func confirmedPrefectureIDs() throws -> Set<String> {
        Set(try confirmed().map(\.prefecture))
    }

    func openVisit(city: String, prefecture: String, within interval: TimeInterval = 12 * 3600) throws -> Visit? {
        let cutoff = Date().addingTimeInterval(-interval)
        return try all().first {
            $0.city == city &&
            $0.prefecture == prefecture &&
            $0.status != .rejected &&
            ($0.endedAt ?? $0.startedAt) >= cutoff
        }
    }

    func save() throws {
        try context.save()
    }

    func update(_ visit: Visit) throws {
        try context.save()
    }
}
