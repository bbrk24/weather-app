import SwiftCrossUI
import SCUIDependiject
import Foundation
import OptimizedMath

struct ForecastView: View {
    @Binding var location: StoredLocation
    @Store var viewModel = Factory.shared.resolve(ForecastViewModel.self)
    @State var modalAlerts: [AlertProperties] = []

    @Environment(\.suggestedForegroundColor) var foregroundColor

    static let hourFormatter = Date.FormatStyle().hour()
    static let timeFormatter = Date.FormatStyle().hour().minute()

    static let dayBackgroundColor = Color.adaptive(light: Color.blue, dark: Color(red: 0.0, green: 0.0, blue: 0.8))
    static let nightBackgroundColor = Color(red: 0.1, green: 0.1, blue: 0.2)

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        TextField("Nickname", text: $location.customName)

                        Text(location.cityName)
                            .padding(.top)
                    }
                    .font(.largeTitle)

                    HStack {
                        Spacer()

                        Button("Refresh") {
                            viewModel.loadForecasts(location: location)
                        }
                        .disabled(viewModel.isLoading)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }

                    if let error = viewModel.error {
                        Text("\(error)")
                            .foregroundColor(.red)
                            .padding()
                    }

                    if
                        let observation = viewModel.latestObservation,
                        let temperature = observation.temperature.value
                    {
                        VStack(spacing: 0) {
                            Text(
                                "Conditions at \(observation.stationName) as of \(ForecastView.timeFormatter.format(observation.timestamp))"
                            )
                                .font(.caption)

                            // TODO: Add symbol based on presentWeather and skyLayers

                            Text(String(format: "%.1f℉", tempCToF(temperature)))
                                .font(.largeTitle)
                                .padding(.vertical)

                            if let windChill = observation.windChill.value {
                                Text(String(format: "Wind chill: %.1f℉", tempCToF(windChill)))
                            }

                            if let heatIndex = observation.heatIndex.value {
                                Text(String(format: "Heat index: %.1f℉", tempCToF(heatIndex)))
                            }

                            if
                                observation.windChill.value == nil && observation.heatIndex.value == nil,
                                let windSpeedKMH = observation.windSpeed.value,
                                let humidity = observation.relativeHumidity.value
                            {
                                Text(
                                    String(
                                        format: "Feels like %.0f℉",
                                        tempCToF(
                                            australianApparentTemperature(
                                                temperature,
                                                windSpeedKMH / 3.6,
                                                humidity
                                            )
                                        )
                                    )
                                )
                            }

                            if let pressurePa = observation.barometricPressure.value {
                                Text(String(format: "Air pressure: %.2f mbar", pressurePa / 100.0))
                            }
                        }
                        .padding(11)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    foregroundColor,
                                    style: StrokeStyle(width: 1.5, cap: .round, join: .round)
                                )
                        )
                        .padding(.vertical)
                    }
                }
                .padding([.horizontal, .top])

                if let hourlyForecast = viewModel.hourlyForecast {
                    ScrollView(.horizontal) {
                        HStack(alignment: .bottom, spacing: 0) {
                            VStack {
                                Text("🌡️")
                                Text("🌧️")
                                Text("🤒")
                            }
                            .padding(6)

                            ForEach(hourlyForecast.periods.prefix(24), id: \.startTime) { period in
                                VStack {
                                    Text(ForecastView.hourFormatter.format(period.startTime))

                                    Text(String(format: "%.0f℉", tempCToF(period.temperature.value)))

                                    Text(String(format: "%.0f%%", period.probabilityOfPrecipitation.value))

                                    Text(String(format: "%.0f℉", feelsLikeTemperature(period: period)))
                                }
                                .padding(6)
                                .background(period.isDaytime ? ForecastView.dayBackgroundColor : ForecastView.nightBackgroundColor)
                                .foregroundColor(period.isDaytime ? foregroundColor : .white)
                            }
                        }
                        .background(Color.gray)
                        .cornerRadius(5)
                        .padding(.horizontal)
                    }
                }

                if
                    let alerts = viewModel.alerts,
                    !alerts.isEmpty
                {
                    Text(
                        alerts.count == 1
                            ? "Alert: \(alerts[0].event)"
                            : "\(alerts.count) alerts"
                    )
                        .font(.title3)
                        .padding()
                        .background(Color.system(.orange))
                        .onTapGesture {
                            modalAlerts = alerts
                        }
                        .cornerRadius(10)
                }

                if let dailyForecast = viewModel.dailyForecast {
                    VStack(alignment: .leading) {
                        ForEach(dailyForecast.periods, id: \.startTime) { period in
                            VStack(alignment: .leading) {
                                Text(period.name)
                                    .font(.headline)

                                ZStack {
                                    ZStack(alignment: .leading) {
                                        Color.clear

                                        Text(period.shortForecast)
                                    }

                                    ZStack(alignment: .trailing) {
                                        Color.clear

                                        Text(String(format: "%.0f℉", tempCToF(period.temperature.value)))
                                    }
                                }
                                .font(.callout)
                            }
                            .padding()
                            .background(period.isDaytime ? ForecastView.dayBackgroundColor : ForecastView.nightBackgroundColor)
                            .foregroundColor(period.isDaytime ? foregroundColor : .white)
                            .cornerRadius(10)
                            .frame(width: 450)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .onChange(of: location.id, initial: true) {
                viewModel.loadForecasts(location: location)
                modalAlerts = []
            }

            if !modalAlerts.isEmpty {
                ZStack {
                    Color.gray.opacity(0.5)
                        .onTapGesture {
                            modalAlerts = []
                        }
                    
                    VStack(alignment: .leading) {
                        Button("x") {
                            modalAlerts = []
                        }

                        ScrollView {
                            ForEach(modalAlerts) { alert in
                                AlertView(alert: alert)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxHeight: 500)
                    .background(Color.adaptive(light: .white, dark: .black))
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
    }
}
