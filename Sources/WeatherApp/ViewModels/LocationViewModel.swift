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
#else
final class LocationViewModelImplementation: LocationViewModel {
    let showCurrentLocationButton = false
    let enableCurrentLocationButton = false
    func getCurrentLocation() async throws(LocationError) -> (lat: Float, long: Float) {
        throw LocationError(description: "Location services are not available on this device.")
    }
}
#endif
