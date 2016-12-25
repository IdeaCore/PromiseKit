//  Created by Austin Feight on 3/19/16.
//  Copyright © 2016 Max Howell. All rights reserved.

import PromiseKit
import XCTest

class JoinTests: XCTestCase {
    func testImmediates() {
        let successPromise = Promise()

        var joinFinished = false
        when(resolved: successPromise).done(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on fulfilled promise")
        
        let promise2 = Promise(2)
        let promise3 = Promise(3)
        let promise4 = Promise(4)
        var join2Finished = false
        when(resolved: promise2, promise3, promise4).done(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on fulfilled promises")
    }
    
    func testImmediateErrors() {
        enum E: Error { case dummy }

        let errorPromise = Promise<Void>(error: E.dummy)
        var joinFinished = false
        when(resolved: errorPromise).done(on: zalgo) { _ in joinFinished = true }
        XCTAssert(joinFinished, "Join immediately finishes on rejected promise")
        
        let errorPromise2 = Promise<Void>(error: E.dummy)
        let errorPromise3 = Promise<Void>(error: E.dummy)
        let errorPromise4 = Promise<Void>(error: E.dummy)
        var join2Finished = false
        when(resolved: errorPromise2, errorPromise3, errorPromise4).done(on: zalgo) { _ in join2Finished = true }
        XCTAssert(join2Finished, "Join immediately finishes on rejected promises")
    }
    
    func testFulfilledAfterAllResolve() {
        let (promise1, fulfill1, _) = Promise<Void>.pending()
        let (promise2, fulfill2, _) = Promise<Void>.pending()
        let (promise3, fulfill3, _) = Promise<Void>.pending()
        
        var finished = false
        when(resolved: promise1, promise2, promise3).done(on: zalgo) { _ in finished = true }
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill1()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill2()
        XCTAssertFalse(finished, "Not all promises have resolved")
        
        fulfill3()
        XCTAssert(finished, "All promises have resolved")
    }
}
