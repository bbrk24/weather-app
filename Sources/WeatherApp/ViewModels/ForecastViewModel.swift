import SCUIDependiject
import SwiftCrossUI
import Foundation
import Alamofire

@MainActor
protocol ForecastViewModel {
    var hourlyForecast: Forecast? { get }
    var dailyForecast: Forecast? { get }
    var alerts: [AlertProperties]? { get }
    var latestObservation: Observation? { get }
    var error: Error? { get }
    var isLoading: Bool { get }

    func loadForecasts(location: StoredLocation)
}

final class ForecastViewModelImplementation: ForecastViewModel, ObservableObject {
    private let forecastRepository: ForecastRepository
    private let alertRepository: AlertRepository
    private let observationRepository: ObservationRepository

    @Published var hourlyForecast: Forecast?
    @Published var dailyForecast: Forecast?
    @Published var error: Error?
    @Published var alerts: [AlertProperties]?
    @Published var latestObservation: Observation?
    private var task: Task<Void, Never>?
    var isLoading: Bool { task != nil }

    init(
        forecastRepository: ForecastRepository,
        alertRepository: AlertRepository,
        observationRepository: ObservationRepository
    ) {
        self.forecastRepository = forecastRepository
        self.alertRepository = alertRepository
        self.observationRepository = observationRepository
    }

    func loadForecasts(location: StoredLocation) {
        task?.cancel()

        hourlyForecast = nil
        dailyForecast = nil
        error = nil
        alerts = nil
        latestObservation = nil

        task = Task {
            async let hourlyForecast = forecastRepository.getHourlyForecast(office: location.office, x: location.gridX, y: location.gridY)
            async let dailyForecast = forecastRepository.getDailyForecast(office: location.office, x: location.gridX, y: location.gridY)
            async let alerts = alertRepository.getAlerts(zone: location.zone)
            async let latestObservation = observationRepository.getLatestObservation(station: location.station)

            do {
                (self.hourlyForecast, self.dailyForecast, self.alerts, self.latestObservation) = try await (hourlyForecast, dailyForecast, alerts, latestObservation)
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
