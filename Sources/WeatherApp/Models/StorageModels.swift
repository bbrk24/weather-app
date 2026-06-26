import Foundation

struct StoredLocation: Codable, Identifiable, Sendable {
    var cityName: String
    var customName: String
    var zone: String
    var county: String
    var station: String
    var office: String
    var gridX: UInt
    var gridY: UInt

    var id: String {
        "\(office);\(gridX),\(gridY);\(zone);\(county)"
    }

    var displayName: String {
        if customName.contains(/\S/) {
            customName
        } else {
            cityName
        }
    }

    init(locationInfo: LocationInfo, station: String) {
        self.zone = locationInfo.forecastZone.lastPathComponent
        self.county = locationInfo.county.lastPathComponent
        self.office = locationInfo.gridId
        self.gridX = locationInfo.gridX
        self.gridY = locationInfo.gridY
        self.cityName = "\(locationInfo.relativeLocation.city), \(locationInfo.relativeLocation.state)"
        self.customName = ""
        self.station = station
    }
}
