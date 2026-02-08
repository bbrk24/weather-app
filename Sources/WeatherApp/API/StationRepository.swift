import Foundation

protocol StationRepository: Sendable {
    func getClosestStation(office: String, x: UInt, y: UInt) async throws -> StationProperties?
}

struct StationRepositoryImplementation: StationRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    func getClosestStation(office: String, x: UInt, y: UInt) async throws -> StationProperties? {
        let response = try await requester.sendRequest(
            to: "https://api.weather.gov/gridpoints/\(office)/\(x),\(y)/stations?limit=1",
            headers: ["Accept": "application/geo+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(GeoJson<StationProperties>.self, from: response.body)

        return result.features.first?.properties
    }
}
