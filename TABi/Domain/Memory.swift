import Foundation
import SwiftData

@Model
final class Memory {
    @Attribute(.unique) var id: UUID
    var imageData: Data
    var capturedAt: Date
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var placeName: String?
    var city: String?
    var prefecture: String?
    var country: String?
    var visitID: UUID?
    var imageFileName: String?

    init(
        id: UUID = UUID(),
        imageData: Data,
        capturedAt: Date = Date(),
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        placeName: String? = nil,
        city: String? = nil,
        prefecture: String? = nil,
        country: String? = nil,
        visitID: UUID? = nil,
        imageFileName: String? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.placeName = placeName
        self.city = city
        self.prefecture = prefecture
        self.country = country
        self.visitID = visitID
        self.imageFileName = imageFileName
    }

    var placeComponents: PlaceComponents {
        PlaceComponents(
            prefecture: prefecture,
            city: city,
            placeName: placeName,
            country: country
        )
    }
}
