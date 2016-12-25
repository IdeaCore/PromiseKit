import PromiseKit
import XCTest

class JointTests: XCTestCase {
    func testPiping() {
        let (promise, joint) = Promise<Int>.pending()

        XCTAssert(promise.isPending)

        let foo = Promise(3)
        foo.weld(to: joint)

        XCTAssertEqual(3, promise.value)
    }

    func testPipingPending() {
        let (promise, joint) = Promise<Int>.pending()

        XCTAssert(promise.isPending)

        let (foo, fulfillFoo, _) = Promise<Int>.pending()
        foo.weld(to: joint)

        fulfillFoo(3)

        XCTAssertEqual(3, promise.value)
    }

    func testCallback() {
        let ex = expectation(description: "")

        let (promise, joint) = Promise<Void>.pending()
        promise.then { ex.fulfill() }

        Promise().weld(to: joint)

        waitForExpectations(timeout: 1)
    }

    func testCallbackPending() {
        let ex = expectation(description: "")

        let (promise, joint) = Promise<Void>.pending()
        promise.then { ex.fulfill() }

        let (foo, fulfillFoo, _) = Promise<Void>.pending()
        foo.weld(to: joint)

        fulfillFoo()

        waitForExpectations(timeout: 1)
    }
}
