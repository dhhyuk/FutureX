// The MIT License (MIT)
//
// Copyright (c) 2016-2018 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import Future

class PromisePerformanceTests: XCTestCase {
    func testCreation() {
        measure {
            for _ in 0..<100_000 {
                let _ = Future<Int, Void> { (_,_) in
                    return // do nothing
                }
            }
        }
    }

    func testOnValue() {
        let futures = (0..<50_000).map { _ in Future<Int, Void>(value: 1) }

        let expectation = self.expectation()
        var finished = 0

        measure {
            for future in futures {
                future.on(success: { _ in
                    finished += 1
                    if finished == futures.count {
                        expectation.fulfill()
                    }

                    return // do nothing
                })
            }
        }

        wait() // wait so that next test aren't affected
    }

    func testFulfill() {
        let items = (0..<100_000).map { _ in Future<Int, Void>.promise }

        let expectation = self.expectation()
        var finished = 0

        for item in items {
            item.future.on(success: { _ in
                finished += 1
                if finished == items.count {
                    expectation.fulfill()
                }

                return // do nothing
            })
        }

        measure {
            for item in items {
                item.succeed(value: 1)
            }
        }

        wait() // wait so that next test aren't affecteds
    }

    func testAttachingCallbacksToResolvedFuture() {
        measure {
            for _ in Array(0..<5000) {
                let promise = Future<Int, Error>.promise
                let future = promise.future

                promise.succeed(value: 1)

                future.on(success: { _ in })
            }
        }
    }

    // MARK: - How Long the Whole Chain Takes

    func testChain() {
        measure {
            var remaining = 5000
            let expecation = self.expectation()
            for _ in Array(0..<5000) {
                let future = Future<Int, Void>(value: 1)
                    .map { $0 + 1 }
                    .flatMap { Future<Int, Void>(value: $0 + 1) }
                    .mapError { $0 }

                future.on(success: { _ in
                    remaining -= 1
                    if remaining == 0 {
                        expecation.fulfill()
                    }
                })
            }
            wait()
        }
    }

    func testZip() {
        measure {
            var remaining = 5000
            let expecation = self.expectation()
            for _ in Array(0..<5000) {
                let future = Future.zip([
                    Future<Int, Void>(value: 1),
                    Future<Int, Void>(value: 2),
                    Future<Int, Void>(value: 4)]
                )

                future.on(success: { _ in
                    remaining -= 1
                    if remaining == 0 {
                        expecation.fulfill()
                    }
                })
            }
            wait()
        }
    }
}

