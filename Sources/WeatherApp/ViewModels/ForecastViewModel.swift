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

final class ForecastViewModelImplementation: ForecastViewModel, SwiftCrossUI.ObservableObject {
    nonisolated private let forecastRepository: ForecastRepository
    nonisolated private let alertRepository: AlertRepository
    nonisolated private let observationRepository: ObservationRepository

    @SwiftCrossUI.Published var hourlyForecast: Forecast?
    @SwiftCrossUI.Published var dailyForecast: Forecast?
    @SwiftCrossUI.Published var error: Error?
    @SwiftCrossUI.Published var alerts: [AlertProperties]?
    @SwiftCrossUI.Published var latestObservation: Observation?
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
            await withTaskGroup(of: Error?.self) { group in
                group.addTask {
                    do {
                        let hourlyForecast = try await self.forecastRepository.getHourlyForecast(office: location.office, x: location.gridX, y: location.gridY)
                        await MainActor.run {
                            self.hourlyForecast = hourlyForecast
                        }
                        return nil
                    } catch {
                        return error
                    }
                }

                group.addTask {
                    do {
                        let dailyForecast = try await self.forecastRepository.getDailyForecast(office: location.office, x: location.gridX, y: location.gridY)
                        await MainActor.run {
                            self.dailyForecast = dailyForecast
                        }
                        return nil
                    } catch {
                        return error
                    }
                }

                group.addTask {
                    do {
                        let alerts = try await self.alertRepository.getAlerts(zone: location.zone)
                        await MainActor.run {
                            self.alerts = alerts
                        }
                        return nil
                    } catch {
                        return error
                    }
                }

                group.addTask {
                    do {
                        let latestObservation = try await self.observationRepository.getLatestObservation(station: location.station)
                        await MainActor.run {
                            self.latestObservation = latestObservation
                        }
                        return nil
                    } catch {
                        return error
                    }
                }

                var error: Error?
                for await maybeError in group {
                    error = error ?? maybeError
                }

                if let error {
                    switch error {
                    case AFError.explicitlyCancelled:
                        // Task was cancelled, don't continue
                        return
                    default:
                        debugPrint(error)
                        self.error = error
                    }
                }

                task = nil
            }
        }
    }
}
