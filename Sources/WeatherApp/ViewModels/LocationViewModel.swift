import Foundation

struct LocationError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    var underlyingError: NSError?
    var description: String
    
    var debugDescription: String {
        underlyingError?.debugDescription ?? description
    }
}

@MainActor
protocol LocationViewModel {
    var showCurrentLocationButton: Bool { get }
    var enableCurrentLocationButton: Bool { get }
    func getCurrentLocation() async throws(LocationError) -> (lat: Float, long: Float)
}

#if canImport(CoreLocation)
import CoreLocation

nonisolated final class LocationViewModelImplementation: NSObject, LocationViewModel, CLLocationManagerDelegate {
    let showCurrentLocationButton = true
    @MainActor var enableCurrentLocationButton: Bool {
        if permissionContinuation != nil || locationContinuation != nil || !CLLocationManager.locationServicesEnabled() {
            return false
        }
        
        let status = _locationManager?.authorizationStatus
        switch status {
        case .denied, .restricted:
            return false
        default:
            return true
        }
    }
    
    @MainActor private var _locationManager: CLLocationManager?
    @MainActor private var locationManager: CLLocationManager {
        if let _locationManager {
            return _locationManager
        } else {
            let manager = CLLocationManager()
            manager.activityType = .other
            manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            manager.delegate = self
            _locationManager = manager
            return manager
        }
    }
    
    private var permissionContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    @MainActor func getCurrentLocation() async throws(LocationError) -> (lat: Float, long: Float) {
        do {
            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                break
            case .denied, .restricted:
                throw CLError(.promptDeclined)
            default: // .notDetermined, @unknown
                try await withCheckedThrowingContinuation {
                    self.permissionContinuation = $0
                    locationManager.requestWhenInUseAuthorization()
                }
            }
            
            let location = try await withCheckedThrowingContinuation {
                self.locationContinuation = $0
                locationManager.requestLocation()
            }
            
            return (
                Float(location.coordinate.latitude),
                Float(location.coordinate.longitude)
            )
        } catch let error as CLError {
            throw LocationError(
                underlyingError: error as NSError,
                description: "Unable to retrieve your location: \(getErrorString(error.code))"
            )
        } catch {
            throw LocationError(
                underlyingError: error as NSError,
                description: "An unexpected error occurred while retrieving your location."
            )
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted, .denied:
            permissionContinuation?.resume(throwing: CLError(.promptDeclined))
            permissionContinuation = nil
        case .authorizedAlways, .authorizedWhenInUse:
            permissionContinuation?.resume()
            permissionContinuation = nil
        case .notDetermined:
            break
        @unknown default:
            fatalError("Unexpected authorization status \(manager.authorizationStatus)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last ?? manager.location {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    private func getErrorString(_ errorCode: CLError.Code) -> String {
        switch errorCode {
        case .locationUnknown:
            "Unknown location"
        case .denied, .regionMonitoringDenied, .promptDeclined:
            "Permission denied"
        case .network:
            "Network error"
        case .headingFailure:
            "Unable to determine heading"
        case .regionMonitoringFailure, .regionMonitoringSetupDelayed, .regionMonitoringResponseDelayed:
            "Failed to monitor region"
        case .geocodeFoundNoResult, .geocodeFoundPartialResult:
            "Geocode not found"
        case .geocodeCanceled, .deferredCanceled:
            "Cancelled"
        case .deferredFailed:
            "GPS unavailable, try again later"
        case .deferredNotUpdatingLocation:
            "Location updates disabled"
        case .deferredAccuracyTooLow:
            "Insufficient accuracy"
        case .deferredDistanceFiltered:
            "Inappropriate distance filter"
        case .rangingUnavailable:
            "Ranging unavailable, try again later"
        case .rangingFailure:
            "Ranging failed"
        case .historicalLocationError:
            "CLError.Code.historicalLocationError"
        @unknown default:
            "An unknown error occurred."
        }
    }
}
#elseif os(Android)
import AndroidBackend
import AndroidLocation
import SwiftJava

@JavaClass("com.bbrk24.weatherapp.LocationHandler")
class LocationHandler: JavaObject {
    @JavaMethod
    convenience init(
        _ activity: FragmentActivity!,
        environment: JNIEnvironment? = nil
    )
    
    @JavaMethod
    func hasLocationFeature() -> Bool
    
    @JavaMethod
    func shouldEnableButton() -> Bool
    
    @JavaMethod
    func requestLocation()
    
    @JavaMethod
    func getSwiftCallbackPointer() -> Int64
    
    @JavaMethod
    func setSwiftCallbackPointer(_ value: Int64)
}

@JavaImplementation("com.bbrk24.weatherapp.LocationHandler")
extension LocationHandler {
    @JavaMethod
    func onLocationResult(
        _ location: AndroidLocation.Location?,
        _ error: JavaString?
    ) {
        let ptrInt = getSwiftCallbackPointer()
        let ptr = UnsafeMutablePointer<(AndroidLocation.Location?, String?) -> Void>(bitPattern: Int(ptrInt))
        ptr?.pointee(location, error?.toString())
    }

    @JavaMethod
    func nativeFinalize() {
        let ptrInt = getSwiftCallbackPointer()
        if let ptr = UnsafeMutablePointer<(AndroidLocation.Location?, String?) -> Void>(bitPattern: Int(ptrInt)) {
            ptr.deinitialize(count: 1)
            ptr.deallocate()
        }
    }
}

extension LocationHandler {
    func setCallback(_ body: ((AndroidLocation.Location?, String?) -> Void)?) {
        nativeFinalize()
        guard let body else {
            setSwiftCallbackPointer(0)
            return
        }
        let ptr = UnsafeMutablePointer<(AndroidLocation.Location?, String?) -> Void>.allocate(capacity: 1)
        ptr.initialize(to: body)
        setSwiftCallbackPointer(Int64(Int(bitPattern: ptr)))
    }
}

final class LocationViewModelImplementation: LocationViewModel {
    private let handler: LocationHandler
    
    init(handler: LocationHandler) {
        self.handler = handler
    }
    
    var showCurrentLocationButton: Bool { handler.hasLocationFeature() }
    
    var enableCurrentLocationButton: Bool { handler.shouldEnableButton() }
    
    func getCurrentLocation() async throws(LocationError) -> (lat: Float, long: Float) {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                handler.setCallback { location, errorText in
                    if let location {
                        continuation.resume(
                            returning: (
                                lat: Float(location.getLatitude()),
                                long: Float(location.getLongitude())
                            )
                        )
                    } else {
                        continuation.resume(
                            throwing: LocationError(
                                description: errorText ?? "Location unavailable."
                            )
                        )
                    }
                }
                
                handler.requestLocation()
            }
        } catch {
            throw error as! LocationError
        }
    }
}
#else
final class LocationViewModelImplementation: LocationViewModel {
    let showCurrentLocationButton = false
    let enableCurrentLocationButton = false
    func getCurrentLocation() async throws(LocationError) -> (lat: Float, long: Float) {
        throw LocationError(description: "Location services are not available on this device.")
    }
}
#endif
