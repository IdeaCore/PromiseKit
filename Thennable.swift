protocol Thennable {
    associatedtype Value

    var state: State<Value> { get }

    init(sealant: (@escaping (Resolution<Value>) -> Void) -> Void)
}

extension Thennable {
    /**
     The provided closure executes when this promise resolves.

     This variant of `then` allows chaining promises, the promise returned by the provided closure is resolved before the promise returned by this closure resolves.

     For example:
     
         URLSession.GET(url1).then { data in
             return CLLocationManager.promise()
         }.then { location in
             //…
         }

     If you return a tuple of promises, all promises are waited on using `when(fulfilled:)`:
     
         login().then { userUrl, avatarUrl in
             (URLSession.GET(userUrl), URLSession.dataTask(with: avatarUrl).asImage())
         }.then { userData, avatarImage in
             //…
         }
     
     If you need to wait on an array of promises, use `when(fulfilled:)`.
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise fulfills.
     - Returns: A new promise that resolves once the promise returned by `execute` resolves.
     - Important: The default queue is the main queue. If you therefore are already on the main queue, what will happen? The answer is: PromiseKit will *dispatch* so that your handler is executed at the next available queue runloop iteration. The reason for this is the phenomenon known as “Zalgo” in the promises community.
     - Remark: `ReturnPromise` name chosen for clarity in compile error messages.
     */
    public func then<ReturnPromise: PromiseConvertible, Return: Thennable>(on q: DispatchQueue = .default, execute body: @escaping (Value) throws -> ReturnPromise) -> Return where Return.Value == ReturnPromise.Value {
        var rv: Return!
        rv = Return(sealant: { resolve in
            state.then(on: q, else: resolve) { value in
                let promise = try body(value).promise
                //guard promise !== rv else { throw PMKError.returnedSelf }
                promise.state.pipe(resolve)
            }
        })
        return rv
    }

    /**
      `then` but for `Void` return from your closure.
 
      - Returns: A `Promise<Void>` that fulfills once your closure returns.
      - Remark: This function only exists because Swift, as yet, does not allow protocol extension to `Void`, thus in order to prevent complexity to `then` (we are not afraid of complexity in our sources, but are in fact afraid of less usability for you (closure return types are less easily inferred by the compiler) and due to persisting issues with the Swift compiler returning *incorrect* errors when it involves a closure, thus misleading error messages. Thus you have to decide between this and `then` actively :(
    */
    public func done(on q: DispatchQueue = .default, _ body: @escaping (Value) throws -> Void) -> Promise<Void> {
        return Promise<Void> { resolve in
            state.then(on: q, else: resolve) { value in
                try body(value)
                resolve(.fulfilled())
            }
        }
    }

    /**
     The provided closure executes when this promise rejects.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - Returns: `self`
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     - Important: The promise that is returned is `self`. `catch` cannot affect the chain, in PromiseKit 3 no promise was returned to strongly imply this, however for PromiseKit 4 we started returning a promise so that you can `always` after a catch or return from a function that has an error handler.
     */
    public func `catch`(on q: DispatchQueue = .default, policy: CatchPolicy = .allErrorsExceptCancellation, handler body: @escaping (Error) -> Void) {
        state.catch(on: q, policy: policy, execute: body)
    }

    /**
     The provided closure executes when this promise is rejected.
     
     Unlike `catch`, `recover` continues the chain provided the closure does not throw. Use `recover` in circumstances where recovering the chain from certain errors is a possibility. For example:
     
         CLLocationManager.promise().recover { error in
             guard error == CLError.unknownLocation else { throw error }
             return CLLocation.Chicago
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter policy: The default policy does not execute your handler for cancellation errors.
     - Parameter execute: The handler to execute if this promise is rejected.
     - SeeAlso: [Cancellation](http://promisekit.org/docs/)
     */

    /**
     The provided closure executes when this promise resolves.

         firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
         }.then {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    public func ensure(on q: DispatchQueue = .default, that body: @escaping () -> Void) -> Self {
        state.pipe(on: q) { _ in body() }
        return self
    }

    /**
     Allows you to “tap” into a promise chain and inspect its result.
     
     The function you provide cannot mutate the chain.
 
         NSURLSession.GET(/*…*/).tap{ print($0) }.then { data in
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter execute: The closure that executes when this promise resolves.
     - Note: The default behavior for tap without parameters is to `print`
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    public func tap(on q: DispatchQueue = .default, _ body: @escaping (Result<Value>) -> Void = { print("PromiseKit:", $0) }) -> Self {
        state.pipe(on: q) { body(Result($0)) }
        return self
    }
}


extension Thennable where Value: Collection {
    /**
     Transforms a `Promise` where `T` is a `Collection` into a `Promise<[U]>`

     func download(urls: [String]) -> Promise<UIImage> {
     //…
     }

     return URLSession.shared.dataTask(url: url).asArray().map(download)

     Equivalent to:

     func download(urls: [String]) -> Promise<UIImage> {
     //…
     }

     return URLSession.shared.dataTask(url: url).then { urls in
     return when(fulfilled: urls.map(download))
     }


     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter transform: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    public func map<TransformType: PromiseConvertible>(on: DispatchQueue = .default, transform: @escaping (Value.Iterator.Element) throws -> TransformType) -> Promise<[TransformType.Value]> {
        return Promise { resolve in
            return state.then(on: zalgo, else: resolve) { tt in
                when(fulfilled: try tt.map{ try transform($0).promise }).state.pipe(resolve)
            }
        }
    }
}
