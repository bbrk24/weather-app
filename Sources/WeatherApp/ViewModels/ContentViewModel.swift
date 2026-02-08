import SCUIDependiject
import SwiftCrossUI

@MainActor
protocol ContentViewModel {
    func searchLocationInfo(lat: Float, long: Float) async throws -> (LocationInfo, StationProperties?)
}

final class ContentViewModelImplementation: ContentViewModel, ObservableObject {
    private let locationInfoRepository: LocationInfoRepository
    private let stationRepository: StationRepository

    init(
        locationInfoRepository: LocationInfoRepository,
        stationRepository: StationRepository
    ) {
        self.locationInfoRepository = locationInfoRepository
        self.stationRepository = stationRepository
    }

    func searchLocationInfo(lat: Float, long: Float) async throws -> (LocationInfo, StationProperties?) {
        let locationInfo = try await locationInfoRepository.getLocationInfo(lat: lat, long: long)
        let station = try await stationRepository.getClosestStation(office: locationInfo.gridId, x: locationInfo.gridX, y: locationInfo.gridY)

        return (locationInfo, station)
    }
}

