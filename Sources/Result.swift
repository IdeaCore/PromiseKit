/**
 The underlying resolved state of a promise.
 - Remark: Same as `Resolution<T>` but without the associated `ErrorConsumptionToken`.
 */
public enum Result<T> {
    /// Fulfillment
    case fulfilled(T)
    /// Rejection
    case rejected(Error)

    init(_ resolution: Resolution<T>) {
        switch resolution {
        case .fulfilled(let value):
            self = .fulfilled(value)
        case .rejected(let error, _):
            self = .rejected(error)
        }
    }

    /**
     - Returns: `true` if the result is `fulfilled` or `false` if it is `rejected`.
     */
    public var boolValue: Bool {
        switch self {
        case .fulfilled:
            return true
        case .rejected:
            return false
        }
    }
}
