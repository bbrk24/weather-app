import SCUIDependiject
import SwiftCrossUI
import Foundation
import Alamofire

@MainActor
protocol ForecastViewModel {
    var hourlyForecast: Forecast? { get }
    var dailyForecast: Forecast? { get }
    var alerts: [AlertProperties]? { get }
    var error: Error? { get }
    var isLoading: Bool { get }

    func loadForecasts(location: StoredLocation)
}

final class ForecastViewModelImplementation: ForecastViewModel, ObservableObject {
    private let forecastRepository: ForecastRepository
    private let alertRepository: AlertRepository

    @Published var hourlyForecast: Forecast?
    @Published var dailyForecast: Forecast?
    @Published var error: Error?
    @Published var alerts: [AlertProperties]?
    private var task: Task<Void, Never>?
    var isLoading: Bool { task != nil }

    init(
        forecastRepository: ForecastRepository,
        alertRepository: AlertRepository
    ) {
        self.forecastRepository = forecastRepository
        self.alertRepository = alertRepository
    }

    func loadForecasts(location: StoredLocation) {
        task?.cancel()

        hourlyForecast = nil
        dailyForecast = nil
        error = nil
        alerts = nil

        task = Task {
            async let hourlyForecast = forecastRepository.getHourlyForecast(url: location.forecast)
            async let dailyForecast = forecastRepository.getDailyForecast(url: location.forecast)
            async let alerts = alertRepository.getAlerts(zone: location.zone)

            do {
                (self.hourlyForecast, self.dailyForecast, self.alerts) = try await (hourlyForecast, dailyForecast, alerts)
            } catch AFError.explicitlyCancelled {
                return
            } catch {
                self.error = error
                debugPrint(error)
            }

            task = nil
        }
    }
}
