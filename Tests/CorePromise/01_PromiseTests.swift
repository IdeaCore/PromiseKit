import PromiseKit
import XCTest

class PromiseTests: XCTestCase {
    override func setUp() {
        InjectedErrorUnhandler = { _ in }
    }

    func testPending() {
        XCTAssertTrue(Promise<Void>.pending().promise.isPending)
        XCTAssertFalse(Promise().isPending)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isPending)
    }

    func testResolved() {
        XCTAssertFalse(Promise<Void>.pending().promise.isResolved)
        XCTAssertTrue(Promise().isResolved)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isResolved)
    }

    func testFulfilled() {
        XCTAssertFalse(Promise<Void>.pending().promise.isFulfilled)
        XCTAssertTrue(Promise().isFulfilled)
        XCTAssertFalse(Promise<Void>(error: Error.dummy).isFulfilled)
    }

    func testRejected() {
        XCTAssertFalse(Promise<Void>.pending().promise.isRejected)
        XCTAssertTrue(Promise<Void>(error: Error.dummy).isRejected)
        XCTAssertFalse(Promise().isRejected)
    }

    func testDispatchQueueAsyncExtensionReturnsPromise() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise { _ -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 1
        }.done { one in
            XCTAssertEqual(one, 1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testDispatchQueueAsyncExtensionCanThrowInBody() {
        let ex = expectation(description: "")

        DispatchQueue.global().promise { _ -> Int in
            throw Error.dummy
        }.done { _ in
            XCTFail()
        }.catch { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testCustomStringConvertible() {
        let a = Promise<Void>.pending().promise   // isPending
        let b = Promise()                         // SealedState
        let c = Promise<Void>(error: Error.dummy) // SealedState
        let d = Promise{ f, _ in f("myValue") }   // UnsealedState
        let e = Promise<Void>{ _, r in r(Error.dummy) }  // UnsealedState

        XCTAssertEqual("\(a)", "Promise(.pending(handlers: 0))")
        XCTAssertEqual("\(b)", "Promise(())")
        XCTAssertEqual("\(c)", "Promise(Error.dummy)")
        XCTAssertEqual("\(d)", "Promise(myValue)")
        XCTAssertEqual("\(e)", "Promise(Error.dummy)")
    }
}

private enum Error: Swift.Error {
    case dummy
}
