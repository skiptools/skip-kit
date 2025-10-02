// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
@testable import SkipKit

let logger: Logger = Logger(subsystem: "SkipKit", category: "Tests")

@available(macOS 13, *)
final class SkipKitTests: XCTestCase {
    func testSkipKit() throws {
        logger.log("running testSkipKit")

        // on iOS, this seems to correspond to the version of XCUnit current running, like 15.2 or 15.4
        XCTAssertNotEqual("", ProcessInfo.processInfo.appVersionString)
        XCTAssertEqual(0, ProcessInfo.processInfo.appVersionNumber ?? 0)
    }

    func testCache() {
        let cache = Cache<UUID, Data>(limit: 100, cost: \.count)

        var addedKeys = Set<UUID>()
        // Cache has no `count` accessor, so we brute-force check for the existance of every key we have added
        var cacheCount = { addedKeys.compactMap({ cache[$0] }).count }

        @discardableResult func addData(size: Int) -> UUID {
            let key = UUID()
            addedKeys.insert(key)
            cache.putValue(Data(count: size), for: key)
            return key
        }

        let key1 = addData(size: 1) // total size = 1
        XCTAssertEqual(cacheCount(), 1)
        XCTAssertNotNil(cache.getValue(for: key1))

        let key2 = addData(size: 90) // total size = 91
        XCTAssertEqual(cacheCount(), 2)
        XCTAssertNotNil(cache.getValue(for: key1))
        XCTAssertNotNil(cache.getValue(for: key2))

        let key3 = addData(size: 9) // total size = 100
        XCTAssertEqual(cacheCount(), 3)
        XCTAssertNotNil(cache.getValue(for: key1))
        XCTAssertNotNil(cache.getValue(for: key2))
        XCTAssertNotNil(cache.getValue(for: key3))

        let key4 = addData(size: 1) // total size = 101 => evict
        XCTAssertLessThan(cacheCount(), 4, "cache should have auto-evicted one or more items")
        XCTAssertTrue(cache.getValue(for: key1) == nil || cache.getValue(for: key2) == nil || cache.getValue(for: key3) == nil, "either key1 or key2 or key3 should have been evicted from the cache")
        // XCTAssertNotNil(cache.getValue(for: key4), "newly added key overflowing cache should have been retained") // not necessarily true
    }
}
