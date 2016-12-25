import PlaygroundSupport
import PromiseKit

PlaygroundPage.current.needsIndefiniteExecution = true

enum E: Error {
    case e
}

firstly {
    1
}.then { in
    URLRequest(url: URL(string: "a")!)
}.then { _ in
    URLRequest(url: URL(string: "a")!)
}.then { _ -> URLRequest in
    URLRequest(url: URL(string: "a")!)
}.then { _ -> Promise in
    URLRequest(url: URL(string: "a")!)
}.then { _ -> Promise in
    Promise(URLRequest(url: URL(string: "a")!))
.then { _ -> Promise<Any> in
    Promise(URLRequest(url: URL(string: "a")!))
}.ensure {
    PlaygroundPage.current.finishExecution()
}
