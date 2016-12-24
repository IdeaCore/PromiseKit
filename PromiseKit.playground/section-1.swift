import PlaygroundSupport
import PromiseKit

enum E: Error {
    case e
}

firstly {
    Promise(1)
}.then { _ in
    arc4random_uniform(2)
}.then { rnd -> Int in
    if rnd == 0 {
        return 1
    } else {
        throw E.e
    }
}.catch { error in
    print(error)
}

PlaygroundPage.current.needsIndefiniteExecution = true
