import Foundation

protocol ForecastRepository: Sendable {
    func getDailyForecast(url: URL) async throws -> Forecast
    func getHourlyForecast(url baseUrl: URL) async throws -> Forecast
}

struct ForecastRepositoryImplementaiton: ForecastRepository {
    private let requester: Requester
    private let decoder: JSONDecoder

    init(requester: Requester, decoder: JSONDecoder) {
        self.requester = requester
        self.decoder = decoder
    }

    private func sendRequest(url: URL) async throws -> Forecast {
        let response = try await requester.sendRequest(
            to: url.appending(queryItems: [.init(name: "units", value: "us")]),
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

    func getDailyForecast(url: URL) async throws -> Forecast {
        try await sendRequest(url: url)
    }

    func getHourlyForecast(url baseUrl: URL) async throws -> Forecast {
        try await sendRequest(url: baseUrl.appending(component: "hourly"))
    }
}
