import SwiftCrossUI
import Foundation

struct AlertView: View {
    var alert: AlertProperties
    
    @State var expanded = false

    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone
    @Environment(\.deviceClass) var deviceClass

    var dateTimeFormatter: Date.FormatStyle {
        Date.FormatStyle(locale: .init(identifier: "en-US"), timeZone: timeZone)
            .month().day().hour().minute()
    }

    var timeOnlyFormatter: Date.FormatStyle {
        Date.FormatStyle(locale: .init(identifier: "en-US"), timeZone: timeZone)
            .hour().minute()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(alert.event)
                    .font(.headline)

                Spacer()

                Text(expanded ? "v" : ">")
                    .padding(.horizontal)
            }

            switch (alert.onset, alert.ends) {
            case (let onset?, let ends?):
                if calendar.isDate(onset, inSameDayAs: ends) {
                    Text(
                        "\(dateTimeFormatter.format(onset)) to \(timeOnlyFormatter.format(ends))"
                    )
                } else {
                    Text(
                        "\(dateTimeFormatter.format(onset)) to \(dateTimeFormatter.format(ends))"
                    )
                }
            case (let onset?, nil):
                Text("Starting \(dateTimeFormatter.format(onset))")
            case (nil, let ends?):
                Text("Until \(dateTimeFormatter.format(ends))")
            case (nil, nil):
                Text("–")
            }

            if expanded {
                Divider()

                Text("Certainty: \(alert.certainty)")
                Text("Severity: \(alert.severity)")
                Text("Urgency: \(alert.urgency)")

                Divider()

                Text("Description")
                    .font(.subheadline)
                
                Text(alert.description)
                    .fontDesign(.monospaced)

                if let instruction = alert.instruction {
                    Divider()
                    
                    Text("Instructions")
                        .font(.subheadline)

                    Text(instruction)
                        .fontDesign(.monospaced)
                }
            }
        }
        .if(deviceClass == .desktop) {
            $0
                .frame(idealWidth: 555)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(15)
        .background(Color.gray.opacity(0.3))
        .onTapGesture {
            expanded.toggle()
        }
        .cornerRadius(10)
    }
}
