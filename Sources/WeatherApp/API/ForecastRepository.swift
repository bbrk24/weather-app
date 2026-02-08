import Foundation

protocol ForecastRepository: Sendable {
    func getDailyForecast(office: String, x: UInt, y: UInt) async throws -> Forecast
    func getHourlyForecast(office: String, x: UInt, y: UInt) async throws -> Forecast
}

struct ForecastRepositoryImplementation: ForecastRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    private static let baseUrl = URL(string: "https://api.weather.gov/gridpoints/")

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    private func sendRequest(relativePath: String) async throws -> Forecast {
        let response = try await requester.sendRequest(
            to: URL(string: relativePath, relativeTo: Self.baseUrl)!.appending(queryItems: [.init(name: "units", value: "us")]),
            headers: [
                "Accept": "application/ld+json",
                "Feature-Flags": "forecast_temperature_qv"
            ]
        )

        if response.code != 200 {
            throw HttpError(response: response)
        }

        let result = try decoder.decode(Forecast.self, from: response.body)
        return result
    }

    func getDailyForecast(office: String, x: UInt, y: UInt) async throws -> Forecast {
        try await sendRequest(relativePath: "\(office)/\(x),\(y)/forecast")
    }

    func getHourlyForecast(office: String, x: UInt, y: UInt) async throws -> Forecast {
        try await sendRequest(relativePath: "\(office)/\(x),\(y)/forecast/hourly")
    }
}
