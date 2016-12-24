import PromiseKit
import XCTest

class WhenTests: XCTestCase {

    func testEmpty() {
        let e = expectation(description: "")
        let promises: [Promise<Void>] = []
        when(fulfilled: promises).done { x in
            XCTAssertTrue(x is Void)  // check is not `Array<Void>`
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testInt() {
        let e1 = expectation(description: "")
        let p1 = Promise(1)
        let p2 = Promise(2)
        let p3 = Promise(3)
        let p4 = Promise(4)

        when(fulfilled: [p1, p2, p3, p4]).done { x in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testDoubleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(1)
        let p2 = Promise("abc")
        when(fulfilled: p1, p2).done { x, y in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testTripleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(1)
        let p2 = Promise("abc")
        let p3 = Promise(1.0)
        when(fulfilled: p1, p2, p3).done { u, v, w in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testQuadrupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(1)
        let p2 = Promise("abc")
        let p3 = Promise(1.0)
        let p4 = Promise(true)
        when(fulfilled: p1, p2, p3, p4).done { u, v, w, x in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuintupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(1)
        let p2 = Promise("abc")
        let p3 = Promise(1.0)
        let p4 = Promise(true)
        let p5 = Promise("a" as Character)
        when(fulfilled: p1, p2, p3, p4, p5).done { u, v, w, x, y in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            XCTAssertEqual("a" as Character, y)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testVoid() {
        let e1 = expectation(description: "")
        let p1 = Promise(1).done { _ in }
        let p2 = Promise(2).done { _ in }
        let p3 = Promise(3).done { _ in }
        let p4 = Promise(4).done { _ in }

        when(fulfilled: p1, p2, p3, p4).done(e1.fulfill)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRejected() {
        enum Error: Swift.Error { case dummy }

        let e1 = expectation(description: "")
        let p1 = after(interval: 0.1).then{ true }
        let p2 = after(interval: 0.2).done{ throw Error.dummy }
        let p3 = Promise(false)
            
        when(fulfilled: p1, p2, p3).catch { _ in
            e1.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: 0.01)
        let p2 = after(interval: 0.02)
        let p3 = after(interval: 0.03)
        let p4 = after(interval: 0.04)

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(fulfilled: p1, p2, p3, p4).done { _ in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }

        progress.resignCurrent()
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: 0.01)
        let p2 = after(interval: 0.02).done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(interval: 0.03)
        let p4 = after(interval: 0.04)

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise: Promise<Void> = when(fulfilled: p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch { _ in
            ex2.fulfill()
        }

        var x = 0
        func finally() {
            x += 1
            if x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = DispatchQueue.main
        p1.ensure(on: q, that: finally)
        p2.ensure(on: q, that: finally)
        p3.ensure(on: q, that: finally)
        p4.ensure(on: q, that: finally)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        enum Error: Swift.Error {
            case test
        }

        InjectedErrorUnhandler = { error in
            XCTFail()
        }

        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: Error.test)
        let p2 = after(interval: 0.1)
        when(fulfilled: p1, p2).done{ XCTFail() }.catch { error in
            XCTAssertTrue(error as? Error == Error.test)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        enum Error: Swift.Error {
            case test
            case straggler
        }

        InjectedErrorUnhandler = { error in
            XCTFail()
        }

        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        let p1 = Promise<Void>(error: Error.test)
        let p2 = after(interval: 0.1).done { throw Error.straggler }
        let p3 = after(interval: 0.2).done { throw Error.straggler }

        when(fulfilled: p1, p2, p3).catch { error -> Void in
            XCTAssertTrue(Error.test == error as? Error)
            ex1.fulfill()
        }

        p2.ensure { after(interval: 0.1).done(ex2.fulfill) }
        p3.ensure { after(interval: 0.1).done(ex3.fulfill) }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAllSealedRejectedFirstOneRejects() {
        enum Error: Swift.Error {
            case test1
            case test2
            case test3
        }

        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: Error.test1)
        let p2 = Promise<Void>(error: Error.test2)
        let p3 = Promise<Void>(error: Error.test3)

        when(fulfilled: p1, p2, p3).catch { error in
            XCTAssertTrue(error as? Error == Error.test1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
