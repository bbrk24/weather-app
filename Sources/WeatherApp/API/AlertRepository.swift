import Foundation

protocol AlertRepository: Sendable {
    func getAlerts(zone: String) async throws -> [AlertProperties]
}

struct AlertRepositoryImplementation: AlertRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    func getAlerts(zone: String) async throws -> [AlertProperties] {
        let response = try await requester.sendRequest(
            to: "https://api.weather.gov/alerts/active/zone/\(zone)",
            headers: ["Accept": "application/geo+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(GeoJson<AlertProperties>.self, from: response.body)

        return result.features.map(\.properties)
    }
}
