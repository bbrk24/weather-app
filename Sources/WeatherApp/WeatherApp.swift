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
                    locationInfoRepository: r.resolve()
                )
            }

            Service(.transient, ForecastRepository.self) { r in
                ForecastRepositoryImplementaiton(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }

            Service(.weak, ForecastViewModel.self) { r in
                ForecastViewModelImplementation(
                    forecastRepository: r.resolve(),
                    alertRepository: r.resolve()
                )
            }

            Service(.transient, AlertRepository.self) { r in
                AlertRepositoryImplementation(
                    requester: r.resolve(),
                    decoder: r.resolve()
                )
            }
        }
    }
}
