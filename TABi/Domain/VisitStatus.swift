import Foundation

enum VisitStatus: String, Codable, CaseIterable, Sendable {
    case candidate
    case confirmed
    case rejected
}
