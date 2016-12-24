public protocol PromiseConvertible {
    associatedtype Value
    var promise: Promise<Value> { get }
}

extension Promise: PromiseConvertible {
    public var promise: Promise { return self }
}

extension Bool: PromiseConvertible {
    public var promise: Promise<Bool> { return Promise(self) }
}

extension Int: PromiseConvertible {
    public var promise: Promise<Int> { return Promise(self) }
}

extension UInt32: PromiseConvertible {
    public var promise: Promise<UInt32> { return Promise(self) }
}

extension String: PromiseConvertible {
    public var promise: Promise<String> { return Promise(self) }
}

extension Data: PromiseConvertible {
    public var promise: Promise<Data> { return Promise(self) }
}

extension Optional: PromiseConvertible {
    public var promise: Promise<Optional> { return Promise(self) }
}

extension AnyPromise: PromiseConvertible {
    public var promise: Promise<Any?> { return asPromise() }
}
