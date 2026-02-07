import Foundation

// MARK: Points
struct RelativeLocation: Decodable {
    var city: String
    var state: String
}

struct LocationInfo: Decodable {
    var forecast: URL
    var relativeLocation: RelativeLocation
    var gridId: String
    var gridX: UInt
    var gridY: UInt
    var forecastZone: URL
}

// MARK: Forecast
struct ValueWithUnit: Decodable {
    var unitCode: String
    var value: Float
}

struct ForecastPeriod: Decodable {
    var name: String
    var startTime: Date
    var isDaytime: Bool
    var temperature: ValueWithUnit
    var probabilityOfPrecipitation: ValueWithUnit
    var windSpeed: String
    var windDirection: String
    var shortForecast: String
    var dewPoint: ValueWithUnit?
    var relativeHumidity: ValueWithUnit?
}

struct Forecast: Decodable {
    var periods: [ForecastPeriod]
}

// MARK: Alerts
struct Feature<Properties: Decodable>: Decodable {
    var properties: Properties
}

struct GeoJson<Properties: Decodable>: Decodable {
    var features: [Feature<Properties>]
}

struct AlertProperties: Decodable, Identifiable {
    var id: String
    var onset: Date?
    var ends: Date?
    var severity: String
    var certainty: String
    var urgency: String
    var event: String
    var description: String
    var instruction: String?
}
