import Foundation

protocol ObservationRepository: Sendable {
    func getLatestObservation(station: String) async throws -> Observation?
}

struct ObservationRepositoryImplementation: ObservationRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    func getLatestObservation(station: String) async throws -> Observation? {
        // /stations/{station}/observations/latest can 404 if the most recent observation is long enough ago,
        // so hit /stations/{station}/observations with a limit of 1 instead
        let response = try await requester.sendRequest(
            to: "https://api.weather.gov/stations/\(station)/observations?limit=1",
            headers: ["Accept": "application/geo+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(GeoJson<Observation>.self, from: response.body)
        return result.features.first?.properties
    }
}
