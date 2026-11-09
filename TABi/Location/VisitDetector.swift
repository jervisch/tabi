import Foundation
import CoreLocation

struct VisitCandidate: Equatable {
    let visit: Visit?
    let confidence: Double
    let components: PlaceComponents
}

enum VisitDetector {
    /// Deterministic V1 heuristics (see engineering guide §4).
    static func evaluate(
        components: PlaceComponents,
        accuracy: Double,
        dwellSeconds: TimeInterval,
        timestamp: Date = Date()
    ) -> (confidence: Double, shouldTrack: Bool) {
        let inJapanAdmin = components.hasJapanAdmin || components.isInJapan
        guard inJapanAdmin || components.country == "Japan" else {
            // Outside Japan: still allow memory, but no Japan visit confidence path
            return (0, false)
        }

        var confidence = 0.55
        if accuracy > 0 && accuracy <= 50 { confidence += 0.25 }
        if dwellSeconds >= 15 * 60 { confidence += 0.20 }
        confidence = min(max(confidence, 0), 1)

        let trackable = components.city != nil && components.prefecture != nil
        return (confidence, trackable)
    }

    static func status(for confidence: Double) -> VisitStatus {
        confidence >= 0.7 ? .confirmed : .candidate
    }

    @MainActor
    static func attach(
        memory: Memory,
        components: PlaceComponents,
        accuracy: Double,
        dwellSeconds: TimeInterval,
        store: VisitStore
    ) throws -> Visit? {
        let (confidence, trackable) = evaluate(
            components: components,
            accuracy: accuracy,
            dwellSeconds: dwellSeconds
        )
        guard trackable,
              let city = components.city,
              let prefecture = components.prefecture else {
            return nil
        }

        if let open = try store.openVisit(city: city, prefecture: prefecture) {
            open.endedAt = memory.capturedAt
            open.confidence = max(open.confidence, confidence)
            if confidence >= 0.7 { open.status = .confirmed }
            memory.visitID = open.id
            try store.update(open)
            return open
        }

        let visit = Visit(
            placeName: components.placeName,
            city: city,
            prefecture: prefecture,
            country: components.country ?? "Japan",
            startedAt: memory.capturedAt,
            endedAt: memory.capturedAt,
            confidence: confidence,
            status: status(for: confidence)
        )
        try store.insert(visit)
        memory.visitID = visit.id
        return visit
    }
}
