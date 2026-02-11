import SwiftCrossUI
import DefaultBackend
import SCUIDependiject
import Foundation

@main
public struct WeatherApp: App {
    public init() {
        setupDI()
    }
    
    public var body: some Scene {
        WindowGroup("Weather App") {
            ContentView()
        }
    }
    
    static var version: String {
        metadata?.version ?? "1.0"
    }
}

extension WeatherApp {
    func setupDI() {
        Factory.register {
            Service(.singleton, Requester.self) { _ in
                RequesterImplementation()
            }

            Service(.singleton, JSONDecoder.self) { _ in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return decoder
            }

            Service(.transient, LocationInfoRepository.self) { r in
                LocationInfoRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }

            Service(.weak, ContentViewModel.self) { r in 
                ContentViewModelImplementation(
                    locationInfoRepository: r.resolve(),
                    stationRepository: r.resolve()
                )
            }

            Service(.transient, ForecastRepository.self) { r in
                ForecastRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }

            Service(.weak, ForecastViewModel.self) { r in
                ForecastViewModelImplementation(
                    forecastRepository: r.resolve(),
                    alertRepository: r.resolve(),
                    observationRepository: r.resolve()
                )
            }

            Service(.transient, AlertRepository.self) { r in
                AlertRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }

            Service(.transient, ObservationRepository.self) { r in
                ObservationRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }

            Service(.transient, StationRepository.self) { r in
                StationRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }
        }
    }
}
