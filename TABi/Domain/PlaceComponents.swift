import Foundation

struct PlaceComponents: Equatable, Sendable {
    var prefecture: String?
    var city: String?
    var placeName: String?
    var country: String?

    var isInJapan: Bool {
        guard let country else { return false }
        let lowered = country.lowercased()
        return lowered == "japan" || lowered == "日本"
    }

    var hasJapanAdmin: Bool {
        prefecture != nil || city != nil
    }
}
