import SwiftCrossUI
import SCUIDependiject

struct ContentView: View {
    @Store var viewModel = Factory.shared.resolve(ContentViewModel.self)
    @AppStorage("locations") var locations: [StoredLocation] = []
    @State var showModal = false
    @State var error: String?
    @State var selectedIndex = 0

    var body: some View {
        ZStack {
            NavigationSplitView {
                ScrollView {
                    VStack(alignment: .trailing) {
                        ForEach(locations.enumerated(), id: \.element.id) { index, location in
                            HStack {
                                ZStack(alignment: .leading) {
                                    Color.clear

                                    Text(location.displayName)
                                }

                                Button("-") {
                                    locations.remove(at: index)
                                    if selectedIndex >= locations.count {
                                        selectedIndex -= 1
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                index == selectedIndex ? Color.system(.yellow) : Color.system(.gray)
                            )
                            .cornerRadius(10)
                            .onTapGesture {
                                selectedIndex = index
                            }
                            .padding(.horizontal, 10)
                        }

                        Button("+") {
                            showModal = true
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.vertical)
                }
            } detail: {
                if selectedIndex < locations.count {
                    ForecastView(location: $locations[selectedIndex])
                }
            }

            if (showModal) {
                ZStack {
                    Color.gray.opacity(0.5)
                        .onTapGesture {
                            showModal = false
                            error = nil
                        }

                    AddLocationModal(
                        error: error,
                        onSubmit: { lat, long in
                            Task {
                                error = nil
                                do {
                                    let (newLocation, station) = try await viewModel.searchLocationInfo(lat: lat, long: long)
                                    guard let station else {
                                        error = "Could not determine nearest observation station to given location."
                                        return
                                    }

                                    let stored = StoredLocation(locationInfo: newLocation, station: station.stationIdentifier)
                                    if locations.contains(where: { $0.id == stored.id }) {
                                        error = "This location has already been added."
                                    } else {
                                        locations.append(stored)
                                        selectedIndex = locations.count - 1
                                        showModal = false
                                    }
                                } catch {
                                    debugPrint(error)
                                    if let he = error as? HttpError,
                                        he.response.code == 404 {
                                        self.error = "Invalid coordinates. Only locations inside the US are accepted."
                                    } else {
                                        self.error = "\(error)"
                                    }
                                }
                            }
                        },
                        hide: {
                            showModal = false
                            error = nil
                        }
                    )
                        .frame(maxWidth: 500)
                }
            }
        }
    }
}
