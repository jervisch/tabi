import Foundation
import SwiftData

@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var placeName: String?
    var city: String
    var prefecture: String
    var country: String
    var startedAt: Date
    var endedAt: Date?
    var confidence: Double
    var statusRaw: String

    init(
        id: UUID = UUID(),
        placeName: String? = nil,
        city: String,
        prefecture: String,
        country: String = "Japan",
        startedAt: Date,
        endedAt: Date? = nil,
        confidence: Double,
        status: VisitStatus = .candidate
    ) {
        self.id = id
        self.placeName = placeName
        self.city = city
        self.prefecture = prefecture
        self.country = country
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.confidence = confidence
        self.statusRaw = status.rawValue
    }

    var status: VisitStatus {
        get { VisitStatus(rawValue: statusRaw) ?? .candidate }
        set { statusRaw = newValue.rawValue }
    }

    var isConfirmed: Bool { status == .confirmed }
}
