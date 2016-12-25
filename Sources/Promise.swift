import class Dispatch.DispatchQueue
import func Foundation.NSLog

/**
 A *promise* represents the future value of a (usually) asynchronous task.

 To obtain the value of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which returns a promise, you can call `then` on that
 promise, et cetera.

 Promises start in a pending state and *resolve* with a value to become
 *fulfilled* or an `Error` to become rejected.

 - SeeAlso: [PromiseKit 101](http://promisekit.org/docs/)
 */
public final class Promise<Value>: Thennable {
    let state: State<Value>

    /**
     Create a new, pending promise.

         func fetchAvatar(user: String) -> Promise<UIImage> {
             return Promise { fulfill, reject in
                 MyWebHelper.GET("\(user)/avatar") { data, err in
                     guard let data = data else { return reject(err) }
                     guard let img = UIImage(data: data) else { return reject(MyError.InvalidImage) }
                     guard let img.size.width > 0 else { return reject(MyError.ImageTooSmall) }
                     fulfill(img)
                 }
             }
         }

     - Parameter resolvers: The provided closure is called immediately on the active thread; commence your asynchronous task, calling either fulfill or reject when it completes.
      - Parameter fulfill: Fulfills this promise with the provided value.
      - Parameter reject: Rejects this promise with the provided error.
     - Returns: A new promise.
     - Note: It is usually easier to use `PromiseKit.wrap`.
     - Note: If you are wrapping a delegate-based system, we recommend to use instead: `Promise.pending()`
     - SeeAlso: http://promisekit.org/docs/sealing-promises/
     - SeeAlso: http://promisekit.org/docs/cookbook/wrapping-delegation/
     - SeeAlso: pending()
     */
    required public init(resolvers: (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
        var resolve: ((Resolution<Value>) -> Void)!
        do {
            state = UnsealedState(resolver: &resolve)
            try resolvers({ resolve(.fulfilled($0)) }, { error in
                #if !PMKDisableWarnings
                    if self.isPending {
                        resolve(Resolution(error))
                    } else {
                        NSLog("PromiseKit: warning: reject called on already rejected Promise: \(error)")
                    }
                #else
                    resolve(Resolution(error))
                #endif
            })
        } catch {
            resolve(Resolution(error))
        }
    }

    /**
     Returns a promise that assumes the state of another promise.
 
     Convenient for catching errors for any preamble in creating initial promises, or for various other patterns that would otherwise be ugly or unclear in the resulting code. For example:
 
         return Promise {
             guard let url = /**/ else { throw Error.badUrl }
             return URLSession.shared.dataTask(url: url)
         }
     
     - Remark: `return` was chosen rather than passing in a `pipe` function since you cannot forget to `return`.

     */
    public init(weld body: () throws -> Promise) {
        do {
            state = try body().state
        } catch {
            state = SealedState(resolution: Resolution(error))
        }
    }

    /**
     Create an already fulfilled promise.
     
     - Note: Usually promises start pending, but sometimes you need a promise that has already transitioned to the “fulfilled” state.
     */
    public init(_ value: Value) {
        state = SealedState(resolution: .fulfilled(value))
    }

    /**
     Create an already rejected promise.
     
     - Note: Usually promises start pending, but sometimes you need a promise that has already transitioned to the “rejected” state.
     */
    public init(error: Error) {
        state = SealedState(resolution: Resolution(error))
    }

    /**
     Careful with this, it is imperative that sealant can only be called once
     or you will end up with spurious unhandled-errors due to possible double
     rejections and thus immediately deallocated ErrorConsumptionTokens.
     */
    init(sealant: (@escaping (Resolution<Value>) -> Void) -> Void) {
        var resolve: ((Resolution<Value>) -> Void)!
        state = UnsealedState(resolver: &resolve)
        sealant(resolve)
    }

    public typealias Pending = (promise: Promise, fulfill: (Value) -> Void, reject: (Error) -> Void)

    /**
     Making promises that wrap asynchronous delegation systems or other larger asynchronous systems without a simple completion handler is easier with pending.

         class Foo: BarDelegate {
             let (promise, fulfill, reject) = Promise<Int>.pending()
    
             func barDidFinishWithResult(result: Int) {
                 fulfill(result)
             }
    
             func barDidError(error: NSError) {
                 reject(error)
             }
         }

     - Returns: A tuple consisting of: 
       1. A promise
       2. A function that fulfills that promise
       3. A function that rejects that promise
     - Note: This function is ambiguous with `pending() -> (Promise, Joint) so you will have to split the tuple in your declaration for the receiver or specify the type of your receiver manually to `Promise<T>.Pending`.
     */
    public final class func pending() -> Pending {
        var fulfill: ((Value) -> Void)!
        var reject: ((Error) -> Void)!
        let promise = self.init { fulfill = $0; reject = $1 }
        return (promise, fulfill, reject)
    }

    /**
     Provides a safe way to instantiate a promise and resolve it later by “welding” it to another promise’s `Joint`.
     
     - Note: Mostly used to avoid implicitly-unwrapped-optionals (IUO) when you need a promise within its own handler.
     - Note: Using a promise in its own handler is a great way to do things like “retry” and polling.

         class Engine {
            static func make() -> Promise<Engine> {
                let (enginePromise, joint) = Promise<Engine>.joint()
                let cylinder: Cylinder = Cylinder(explodeAction: {

                    // We *could* use an IUO, but there are no guarantees about when
                    // this callback will be called. Having an actual promise is safe.

                    enginePromise.then { engine in
                        engine.checkOilPressure()
                    }
                })

                firstly {
                    Ignition.default.start()
                }.then { plugs in
                    Engine(cylinders: [cylinder], sparkPlugs: plugs)
                }.weld(joint)

                return enginePromise
            }
         }

     - Note: Usually this utility seems both opaque and strange… until you need it that is.
     - Returns: A new promise and its `Joint`.
     - SeeAlso: `weld(to:)`
     - Remark: This may seem convoluted, why not just allow any promise to adopt the state of another with an instance function? Because that allows responsibility for tasks to escape, any third party library, other module or co-worker could interfere with *your* tasks.
     */
    public final class func pending() -> (Promise<Value>, Joint<Value>) {
        let pipe = Joint<Value>()
        let promise = Promise(sealant: { pipe.resolve = $0 })
        return (promise, pipe)
    }

    /**
     Pipes the value of this promise to the promise created with the joint.

     - Parameter to: The joint that we are ”welded” to; its promise adopts our state.
     - SeeAlso: `pending() -> (Promise, Joint)`
     */
    public func weld(to joint: Joint<Value>) {
        state.pipe(joint.resolve)
    }
    
    /**
     Void promises are less prone to generics-of-doom scenarios.
     - SeeAlso: when.swift contains enlightening examples of using `Promise<Void>` to simplify your code.
     */
    public func asVoid() -> Promise<Void> {
        return done(on: zalgo) { _ in }
    }

    public func recover<ReturnType: PromiseConvertible>(on q: DispatchQueue = .default, policy: CatchPolicy = .allErrorsExceptCancellation, handler body: @escaping (Error) throws -> ReturnType) -> Promise where ReturnType.Value == Value {
        let (rv, joint) = Promise.pending()
        state.recover(on: q, policy: policy, else: joint.resolve) { error in
            let recovery = try body(error).promise
            guard rv !== recovery else { throw PMKError.returnedSelf }
            recovery.weld(to: joint)
        }
        return rv
    }

    public func recover(on q: DispatchQueue = .default, policy: CatchPolicy = .allErrorsExceptCancellation, handler body: @escaping (Error) throws -> Void) -> Promise<Void> {
        return Promise<Void>(sealant: { resolve in
            state.catch(on: q, policy: policy) { error in
                do {
                    try body(error)
                    resolve(.fulfilled())
                } catch {
                    resolve(Resolution(error))
                }
            }
        })
    }
}

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

     NSURLSession.dataTask(url: url1).then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 With:

     firstly {
         URLSession.shared.dataTask(url: url1)
     }.then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }
 */
public func firstly<ReturnType: PromiseConvertible>(execute body: () throws -> ReturnType) -> Promise<ReturnType.Value> {
    do {
        return try body().promise
    } catch {
        return Promise(error: error)
    }
}

/// - SeeAlso: `firstly`
public func firstly<ReturnType: PromiseConvertible>(execute body: () -> ReturnType) -> Promise<ReturnType.Value> {
    return body().promise
}

/**
 - SeeAlso: `Promise.pending() -> (Promise, Joint)`
 - SeeAlso: `Promise.pipe`
 */
public class Joint<T> {
    fileprivate var resolve: ((Resolution<T>) -> Void)!
}
