import Foundation

public struct StoredLocation: Codable, Identifiable, Sendable {
    public var id: String
    public var forecast: URL
    public var cityName: String
    public var customName: String
    public var zone: String

    var displayName: String {
        if customName.contains(/\S/) {
            customName
        } else {
            cityName
        }
    }

    init(locationInfo: LocationInfo) {
        self.zone = locationInfo.forecastZone.lastPathComponent
        self.id = "\(locationInfo.gridId);\(locationInfo.gridX),\(locationInfo.gridY);\(self.zone)"
        self.forecast = locationInfo.forecast
        self.cityName = "\(locationInfo.relativeLocation.city), \(locationInfo.relativeLocation.state)"
        self.customName = ""
    }
}
