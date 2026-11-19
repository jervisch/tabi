import Foundation

/// Chronological trip cluster for Memories (Year → Trip).
struct Trip: Identifiable, Equatable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let prefecture: String?
    let city: String?
    let memories: [Memory]

    var year: Int {
        Calendar.current.component(.year, from: startDate)
    }
}

enum TripGrouper {
    /// Gap > 2 days starts a new trip; region change with gap > 12h also splits.
    static func group(
        _ memories: [Memory],
        calendar: Calendar = .current,
        dayGap: Int = 2,
        regionGapHours: Double = 12
    ) -> [Trip] {
        let sorted = memories.sorted { $0.capturedAt < $1.capturedAt }
        guard !sorted.isEmpty else { return [] }

        var trips: [Trip] = []
        var current: [Memory] = [sorted[0]]

        for memory in sorted.dropFirst() {
            let previous = current.last!
            let hours = memory.capturedAt.timeIntervalSince(previous.capturedAt) / 3600.0
            let days = calendar.dateComponents([.day], from: previous.capturedAt, to: memory.capturedAt).day ?? 0
            let regionChanged =
                previous.prefecture != memory.prefecture ||
                previous.city != memory.city
            let shouldSplit =
                days > dayGap ||
                (regionChanged && hours > regionGapHours)

            if shouldSplit {
                trips.append(makeTrip(from: current))
                current = [memory]
            } else {
                current.append(memory)
            }
        }
        trips.append(makeTrip(from: current))
        return trips
    }

    private static func makeTrip(from memories: [Memory]) -> Trip {
        let first = memories.first!
        let last = memories.last!
        let place = first.city ?? first.prefecture ?? "Memories"
        return Trip(
            id: UUID(),
            title: place,
            startDate: first.capturedAt,
            endDate: last.capturedAt,
            prefecture: first.prefecture,
            city: first.city,
            memories: memories
        )
    }
}
