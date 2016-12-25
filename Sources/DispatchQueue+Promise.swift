import Dispatch

extension DispatchQueue {
    /**
     Submits a block for asynchronous execution on a dispatch queue.

         DispatchQueue.global().promise {
            try md5(input)
         }.then { md5 in
            //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new promise resolved by the result of the provided closure.
     - SeeAlso: `DispatchQueue.async(group:qos:flags:execute:)`
     */
    public final func promise<ReturnType: Chainable>(group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> ReturnType) -> Promise<ReturnType.Value> {

        return Promise(sealant: { resolve in
            async(group: group, qos: qos, flags: flags) {
                do {
                    try body().promise.state.pipe(resolve)
                } catch {
                    resolve(Resolution(error))
                }
            }
        })
    }

    /**
     The default queue for all handlers.

     Defaults to `DispatchQueue.main`.

     - Important: Must be set before *any* other PromiseKit function.
     - SeeAlso: `PMKDefaultDispatchQueue()`
     - SeeAlso: `PMKSetDefaultDispatchQueue()`
     */
    class public final var `default`: DispatchQueue {
        get {
            return __PMKDefaultDispatchQueue()
        }
        set {
            __PMKSetDefaultDispatchQueue(newValue)
        }
    }
}
