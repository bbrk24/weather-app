import Foundation
import Alamofire

protocol AlertRepository: Sendable {
    func getAlerts(zone: String, county: String) async throws -> [AlertProperties]
}

struct AlertRepositoryImplementation: AlertRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    private func getAlertProperties(zoneOrCounty: String) async throws -> [AlertProperties] {
        let response = try await requester.sendRequest(
            to: "https://api.weather.gov/alerts/active/zone/\(zoneOrCounty)",
            headers: ["Accept": "application/geo+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(GeoJson<Empty, AlertProperties>.self, from: response.body)

        return result.features.map(\.properties)
    }

    func getAlerts(zone: String, county: String) async throws -> [AlertProperties] {
        async let countyProperties = getAlertProperties(zoneOrCounty: county)
        async let zoneProperties = getAlertProperties(zoneOrCounty: zone)

        return try await (countyProperties + zoneProperties).unique(by: \.id)
    }
}
