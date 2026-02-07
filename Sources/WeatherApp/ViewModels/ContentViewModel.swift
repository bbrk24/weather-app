import SCUIDependiject
import SwiftCrossUI

@MainActor
protocol ContentViewModel {
    func searchLocationInfo(lat: Float, long: Float) async throws -> LocationInfo
}

final class ContentViewModelImplementation: ContentViewModel, ObservableObject {
    private let locationInfoRepository: LocationInfoRepository

    init(locationInfoRepository: LocationInfoRepository) {
        self.locationInfoRepository = locationInfoRepository
    }

    func searchLocationInfo(lat: Float, long: Float) async throws -> LocationInfo {
        try await locationInfoRepository.getLocationInfo(lat: lat, long: long)
    }
}

