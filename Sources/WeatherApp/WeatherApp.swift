import SwiftCrossUI
import SCUIDependiject
import Foundation

#if os(Android)
// https://github.com/moreSwift/swift-cross-ui/issues/608
import AndroidBackend
#else
import DefaultBackend
#endif

extension EnvironmentValues {
    @Entry
    var deviceClass: DeviceClass = .desktop
}

#if os(Android)
import SwiftJava

struct WeatherActivityDelegate: ActivityDelegate {
    func onCreate(of activity: FragmentActivity, env: JNIEnvironment?) {
        Factory.register {
            Service(constant: LocationHandler(activity, environment: env), LocationHandler.self)
        }
    }
}
#endif

@main
public struct WeatherApp: App {
    #if os(Android)
    public let backend = AndroidBackend(delegate: WeatherActivityDelegate())
    #endif
    
    public init() {
        setupDI()
    }
    
    public var body: some Scene {
        WindowGroup("Weather App") {
            ContentView()
                .environment(\.deviceClass, backend.deviceClass)
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
                    observationRepository: r.resolve(),
                    locationInfoRepository: r.resolve()
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
            
            #if os(Android)
            Service(.weak, LocationViewModel.self) { r in
                LocationViewModelImplementation(
                    handler: r.resolve()
                )
            }
            #else
            Service(.weak, LocationViewModel.self) { _ in
                LocationViewModelImplementation()
            }
            #endif
        }
    }
}
