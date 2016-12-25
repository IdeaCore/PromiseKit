import PlaygroundSupport
import PromiseKit

PlaygroundPage.current.needsIndefiniteExecution = true

enum E: Error {
    case e
}

firstly {
    1
}.then { _ in
    arc4random_uniform(2)
}.then { rnd -> Int in
    if rnd == 0 {
        return 1
    } else {
        throw E.e
    }
}.ensure {
    PlaygroundPage.current.finishExecution()
}.catch { error in
    print(error)
}
