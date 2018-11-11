// The MIT License (MIT)
//
// Copyright (c) 2017-2018 Alexander Grebenyuk (github.com/kean).

import XCTest
import Foundation
import Pill

class FutureTests: XCTestCase {

    // MARK: - Observe On

    func testObserveOnMainThreadByDefault() {
        // GIVEN the default promise
        let future = Future<Int, MyError>(value: 1)

        // EXPECT maps to be called on main queue
        _ = future.map { _ -> Int in
            XCTAssertTrue(Thread.isMainThread)
            return 2
        }

        // EXPECT on(...) to be called on the main queue
        future.on(
            success: { _ in
                XCTAssertTrue(Thread.isMainThread)
            },
            failure: { _ in
                XCTAssertTrue(Thread.isMainThread)
            },
            completion: {
                XCTAssertTrue(Thread.isMainThread)
            }
        )
    }

    func testObserveOn() {
        // GIVEN the promise with a a custom observe queue
        let future = Future<Int, MyError>(value: 1)
            .observeOn(DispatchQueue.global())

        // EXPECT maps to be called on global queue
        _ = future.map { _ -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 2
        }

        // EXPECT on(...) to be called on the global queue
        future.on(
            success: { _ in
                XCTAssertFalse(Thread.isMainThread)
            },
            failure: { _ in
                XCTAssertFalse(Thread.isMainThread)
            },
            completion: {
                XCTAssertFalse(Thread.isMainThread)
            }
        )
    }

    func testObserveOnFlatMap() {
        // GIVEN the promise with a a custom observe queue
        let future = Future<Int, MyError>(value: 1)
            .observeOn(DispatchQueue.global())
            .flatMap { value in
                return Future(value: value + 1)
            }

        // EXPECT maps to be called on global queue
        _ = future.map { _ -> Int in
            XCTAssertFalse(Thread.isMainThread)
            return 2
        }

        // EXPECT on(...) to be called on the global queue
        future.on(
            success: { _ in
                XCTAssertFalse(Thread.isMainThread)
            },
            failure: { _ in
                XCTAssertFalse(Thread.isMainThread)
            },
            completion: {
                XCTAssertFalse(Thread.isMainThread)
            }
        )
    }

    // MARK: And

    func testBothSucceed() {
        // GIVEN two futures
        let promise = Promise<Int, String>()
        let future = promise.future

        let promise2 = Promise<Int, String>()
        let future2 = promise2.future

        let expectation = self.expectation(description: "succees")

        // EXPECT "and" future to succeed
        future.and(future2).on(
            success: { value in
                XCTAssertEqual(value.0, 1)
                XCTAssertEqual(value.1, 2)
                expectation.fulfill()
            },
            failure: { _ in
                XCTFail()
            }
        )

        // WHEN first both succeed
        promise.succeed(value: 1)
        DispatchQueue.global().async {
            promise2.succeed(value: 2)
        }

        wait()
    }

    func testAndFirstFails() {
        // GIVEN two futures
        let promise = Promise<Int, String>()
        let future = promise.future

        let promise2 = Promise<Int, String>()
        let future2 = promise2.future

        let expectation = self.expectation(description: "failure")

        // EXPECT "and" future to fail
        future.and(future2).on(
            success: { _ in
                XCTFail()
            },
            failure: { error in
                XCTAssertEqual("error", error)
                expectation.fulfill()
            }
        )

        // WHEN first succeed, second fails
        promise.succeed(value: 1)
        promise2.fail(error: "error")

        wait()
    }

    func testAndSecondFails() {
        // GIVEN two futures
        let promise = Promise<Int, String>()
        let future = promise.future

        let promise2 = Promise<Int, String>()
        let future2 = promise2.future

        let expectation = self.expectation(description: "failure")

        // EXPECT "and" future to fail
        future.and(future2).on(
            success: { _ in
                XCTFail()
            },
            failure: { error in
                XCTAssertEqual("error", error)
                expectation.fulfill()
            }
        )

        // WHEN first succeed, second fails
        promise2.succeed(value: 1)
        promise.fail(error: "error")

        wait()
    }
}
