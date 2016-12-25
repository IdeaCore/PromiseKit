extension Thennable {
    /// - Returns: The value with which this promise was fulfilled or `nil` if this promise is pending or rejected.
    final public var value: Value? {
        switch state.get() {
        case .none:
            return nil
        case .some(.fulfilled(let value)):
            return value
        case .some(.rejected):
            return nil
        }
    }

    /// - Returns: The error with which this promise was rejected; `nil` if this promise is not rejected.
    final public var error: Error? {
        switch state.get() {
        case .none:
            return nil
        case .some(.fulfilled):
            return nil
        case .some(.rejected(let error, _)):
            return error
        }
    }

    final public var result: Result<Value>? {
        switch state.get() {
        case .none:
            return nil
        case .some(.fulfilled(let value)):
            return .fulfilled(value)
        case .some(.rejected(let error, _)):
            return .rejected(error)
        }
    }

    /// - Returns: `true` if the promise has not yet resolved.
    final public var isPending: Bool {
        return state.get() == nil
    }

    /// - Returns: `true` if the promise has resolved.
    final public var isResolved: Bool {
        return !isPending
    }

    /// - Returns: `true` if the promise was fulfilled.
    final public var isFulfilled: Bool {
        return value != nil
    }

    /// - Returns: `true` if the promise was rejected.
    final public var isRejected: Bool {
        return error != nil
    }
}
