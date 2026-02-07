import SwiftCrossUI

struct FloatInputView: View {
    var placeholder: String?
    @Binding var value: Float?
    @State var text: String = ""

    var body: some View {
        TextField(placeholder ?? "", text: $text)
            .onChange(of: text, initial: false) {
                value = Float(text)
            }
            .onChange(of: value, initial: true) {
                if let value {
                    if Float(text) != value {
                        text = "\(value)"
                    }
                } else {
                    text = ""
                }
            }
    }
}
