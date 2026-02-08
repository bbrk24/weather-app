import Foundation

protocol ObservationRepository: Sendable {
    func getLatestObservation(station: String) async throws -> Observation
}

struct ObservationRepositoryImplementation: ObservationRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    func getLatestObservation(station: String) async throws -> Observation {
        let response = try await requester.sendRequest(
            to: "https://api.weather.gov/stations/\(station)/observations/latest?require_qc=false",
            headers: ["Accept": "application/ld+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(Observation.self, from: response.body)
        return result
    }
}
