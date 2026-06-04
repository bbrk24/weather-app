import SwiftCrossUI

#if canImport(UIKitBackend) || canImport(AndroidBackend)
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
#else
import AndroidBackend
import AndroidKit
import SwiftJava

@JavaClass(
    "com.bbrk24.weatherapp.CustomOnClickListener",
    implements: AndroidKit.View.OnClickListener.self
)
class CustomOnClickListener: JavaObject {
    @JavaMethod
    convenience init(rawPointer: Int64, environment: JNIEnvironment? = nil)
    
    @JavaMethod
    func getRawPointer() -> Int64
}

@JavaImplementation("com.bbrk24.weatherapp.CustomOnClickListener")
extension CustomOnClickListener {
    @JavaMethod
    func nativeOnClick() {
        let ptrInt = getRawPointer()
        let ptr = UnsafePointer<() -> Void>(bitPattern: Int(ptrInt))
        ptr?.pointee()
    }
    
    @JavaMethod
    func nativeFinalize() {
        let ptrInt = getRawPointer()
        if let ptr = UnsafeMutablePointer<() -> Void>(bitPattern: Int(ptrInt)) {
            ptr.deinitialize(count: 1)
            ptr.deallocate()
        }
    }
}

extension CustomOnClickListener {
    convenience init(_ env: JNIEnvironment?, body: @escaping () -> Void) {
        let ptr = UnsafeMutablePointer<() -> Void>.allocate(capacity: 1)
        ptr.initialize(to: body)
        self.init(rawPointer: Int64(Int(bitPattern: ptr)), environment: env)
    }
}

struct IconButton: AndroidViewRepresentable {
    var action: () -> Void
    
    func makeAndroidView(context: Self.Context) -> AndroidKit.ImageButton {
        let button = AndroidKit.ImageButton(
            context.environment.androidActivity,
            environment: context.environment.jniEnv
        )
        
        let Rdrawable = try! JavaClass<AndroidKit.R.drawable>()
        button.setImageResource(Rdrawable.ic_dialog_map)
        
        return button
    }
    
    func updateAndroidView(
        _ view: AndroidKit.ImageButton,
        context: Self.Context
    ) {
        view.setOnClickListener(
            CustomOnClickListener(
                context.environment.jniEnv,
                body: action
            ).as(AndroidKit.View.OnClickListener.self)
        )
    }
}
#endif

struct SplitView<Sidebar: SwiftCrossUI.View, Detail: SwiftCrossUI.View>: SwiftCrossUI.View {
    var sidebar: Sidebar
    var detail: Detail
    @State var showSidebar = false
    
    init(@ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
        self.sidebar = sidebar()
        self.detail = detail()
    }
    
    var body: some SwiftCrossUI.View {
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
