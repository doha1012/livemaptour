import Foundation
import CoreLocation

struct TourItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var country: String
    var addressName: String
    var latitude: Double
    var longitude: Double
    var videoId: String
    var thumbnailName: String
}


