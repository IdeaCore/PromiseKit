//TODO name Chainable?

public protocol Chainable {
    associatedtype Value

    // convert this type into a `Promise`
    var promise: Promise<Value> { get }
}

extension Promise: Chainable {
    public var promise: Promise { return self }
}

extension Bool: Chainable {
    public var promise: Promise<Bool> { return Promise(self) }
}

extension Int: Chainable {
    public var promise: Promise<Int> { return Promise(self) }
}

extension UInt32: Chainable {
    public var promise: Promise<UInt32> { return Promise(self) }
}

extension String: Chainable {
    public var promise: Promise<String> { return Promise(self) }
}

extension Data: Chainable {
    public var promise: Promise<Data> { return Promise(self) }
}

extension Optional: Chainable {
    public var promise: Promise<Optional> { return Promise(self) }
}

extension AnyPromise: Chainable {
    public var promise: Promise<Any?> { return Promise(sealant: state.pipe) }
}

//TODO sucks
public protocol Promisey {}
extension Promise: Promisey {}
extension AnyPromise: Promisey {}

extension Optional where Wrapped: Promisey, Wrapped: Chainable {
    public var promise: Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            fatalError("Cannot figure this out")  //FIXME!
        }
    }
}

extension ImplicitlyUnwrappedOptional where Wrapped: Promisey, Wrapped: Chainable {
    public var promise: Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            fatalError("Cannot figure this out")  //FIXME!
        }
    }
}
