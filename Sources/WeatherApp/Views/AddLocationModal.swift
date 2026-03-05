import SwiftCrossUI

struct AddLocationModal: View {
    var error: String?
    var onSubmit: (Float, Float) async -> Void
    var hide: @MainActor () -> Void
    @State var lat: Float? = nil
    @State var long: Float? = nil
    @State var task: Task<Void, Never>? = nil

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                HStack {
                    // TODO: Figure out the layout bug that puts this button in the wrong place
                    // Button("x", action: hide)

                    Spacer()
                }

                Text("Add a location")
                    .font(.title)
            }
            
            Text(
                """
                The first 4 decimal places are sent to the NWS API to retrieve information about the location.
                This information is stored locally; the location itself is discarded.
                """
            )
            .multilineTextAlignment(.center)
            .font(.caption)

            FloatInputView(placeholder: "Latitude", value: $lat)

            FloatInputView(placeholder: "Longitude", value: $long)

            if task != nil {
                ProgressView()
            } else if let error {
                Text(error)
                    .font(.body)
                    .foregroundColor(.red)
            }

            Button("Go!") {
                if let lat, let long {
                    task = Task {
                        defer { task = nil }
                        await onSubmit(lat, long)
                    }
                }
            }
            .disabled(
                (lat.map { $0 < -90.0 || $0 > 90.0 || $0.isNaN } ?? true)
                || (long.map { $0 <= -180.0 || $0 > 180.0 || $0.isNaN } ?? true)
                || task != nil
            )
        }
        .padding()
        .onDisappear {
            task?.cancel()
        }
    }
}
