import SwiftCrossUI

@propertyWrapper
public struct Store<ObjectType> {
    /// The underlying object being stored.
    public let wrappedValue: ObjectType
    
    /// A projected value which has the same properties as the wrapped value, but presented as
    /// bindings.
    ///
    /// Use this to pass bindings down the view hierarchy:
    /// ```swift
    /// struct ExampleView: View {
    ///     @Store var viewModel = Factory.shared.resolve(ViewModelProtocol.self)
    ///
    ///     var body: some View {
    ///         TextField("username", text: $viewModel.username)
    ///     }
    /// }
    /// ```
    public var projectedValue: Wrapper {
        return Wrapper(self)
    }
    
    @MainActor
    public init(wrappedValue: ObjectType) {
        self.wrappedValue = wrappedValue
    }
    
    /// An equivalent to SwiftUI's
    /// [`ObservedObject.Wrapper`](https://developer.apple.com/documentation/swiftui/observedobject/wrapper)
    /// type.
    @dynamicMemberLookup
    public struct Wrapper {
        private var store: Store
        
        internal init(_ store: Store<ObjectType>) {
            self.store = store
        }
        
        /// Returns a binding to the resulting value of a given key path.
        public subscript<Subject>(
            dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>
        ) -> Binding<Subject> {
            return Binding {
                self.store.wrappedValue[keyPath: keyPath]
            } set: {
                self.store.wrappedValue[keyPath: keyPath] = $0
            }
        }
    }
}

extension Store: ObservableProperty {
    public var didChange: Publisher {
        if let observable = wrappedValue as? any ObservableObject {
            observable.didChange
        } else {
            preconditionFailure(
                "Only use the Store property wrapper with objects conforming to ObservableObject."
            )
        }
    }

    public func update(with environment: EnvironmentValues, previousValue: Store<ObjectType>?) {
        // no-op
    }
}
