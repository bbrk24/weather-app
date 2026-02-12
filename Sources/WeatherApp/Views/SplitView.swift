import SwiftCrossUI

#if canImport(UIKitBackend)
import UIKitBackend
import UIKit

struct IconButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.onTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.action = action
    }
    
    final class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func onTap() {
            action()
        }
    }
}

struct SplitView<Sidebar: View, Detail: View>: View {
    var sidebar: Sidebar
    var detail: Detail
    @State var showSidebar = false
    
    init(@ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
        self.sidebar = sidebar()
        self.detail = detail()
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            IconButton { showSidebar = true }
                .fixedSize(horizontal: true, vertical: true)
                .padding(.trailing)
            
            detail
        }
        .sheet(isPresented: $showSidebar) {
            sidebar
        }
    }
}
#else
typealias SplitView<Sidebar: View, Detail: View> = NavigationSplitView<Sidebar, EmptyView, Detail>
#endif
