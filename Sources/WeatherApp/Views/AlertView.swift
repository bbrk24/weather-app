import SwiftCrossUI
import Foundation

struct AlertView: View {
    var alert: AlertProperties
    @State var expanded = false

    static let dateTimeFormatter = Date.FormatStyle(locale: .init(identifier: "en-US"))
        .month().day().hour()
    
    static let timeOnlyFormatter = Date.FormatStyle(locale: .init(identifier: "en-US"))
        .hour()

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
                if Calendar.current.isDate(onset, inSameDayAs: ends) {
                    Text(
                        "\(AlertView.dateTimeFormatter.format(onset)) to \(AlertView.timeOnlyFormatter.format(ends))"
                    )
                } else {
                    Text(
                        "\(AlertView.dateTimeFormatter.format(onset)) to \(AlertView.dateTimeFormatter.format(ends))"
                    )
                }
            case (let onset?, nil):
                Text("Starting \(AlertView.dateTimeFormatter.format(onset))")
            case (nil, let ends?):
                Text("Until \(AlertView.dateTimeFormatter.format(ends))")
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
        .frame(minWidth: 500)
        .fixedSize(horizontal: true, vertical: false)
        .padding()
        .background(Color.gray.opacity(0.3))
        .onTapGesture {
            expanded.toggle()
        }
        .cornerRadius(10)
    }
}
