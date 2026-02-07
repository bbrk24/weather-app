import Foundation

protocol LocationInfoRepository: Sendable {
    func getLocationInfo(
        lat: Float,
        long: Float
    ) async throws -> LocationInfo
}

struct LocationInfoRepositoryImplementation: LocationInfoRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    func getLocationInfo(
        lat: Float,
        long: Float
    ) async throws -> LocationInfo {
        let response = try await requester.sendRequest(
            to: String(format: "https://api.weather.gov/points/%.4f,%.4f", lat, long),
            headers: ["Accept": "application/ld+json"]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(LocationInfo.self, from: response.body)
        return result
    }
}
