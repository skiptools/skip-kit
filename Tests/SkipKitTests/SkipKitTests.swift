// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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

    func testMailComposerOptions() throws {
        let opts = MailComposerOptions(
            recipients: ["alice@example.com", "bob@example.com"],
            ccRecipients: ["cc@example.com"],
            bccRecipients: ["bcc@example.com"],
            subject: "Test Subject",
            body: "<h1>Hello</h1>",
            isHTML: true
        )
        XCTAssertEqual(opts.recipients.count, 2)
        XCTAssertEqual(opts.ccRecipients.count, 1)
        XCTAssertEqual(opts.bccRecipients.count, 1)
        XCTAssertEqual(opts.subject, "Test Subject")
        XCTAssertEqual(opts.body, "<h1>Hello</h1>")
        XCTAssertTrue(opts.isHTML)
        XCTAssertEqual(opts.attachments.count, 0)

        // Default options
        let empty = MailComposerOptions()
        XCTAssertTrue(empty.recipients.isEmpty)
        XCTAssertNil(empty.subject)
        XCTAssertFalse(empty.isHTML)
    }

    func testMailAttachment() throws {
        let attachment = MailAttachment(
            url: URL(string: "file:///tmp/test.pdf")!,
            mimeType: "application/pdf",
            filename: "test.pdf"
        )
        XCTAssertEqual(attachment.mimeType, "application/pdf")
        XCTAssertEqual(attachment.filename, "test.pdf")
    }

    func testMailComposerResult() throws {
        let results: [MailComposerResult] = [.sent, .saved, .cancelled, .failed, .unknown]
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(MailComposerResult.sent.rawValue, "sent")
        XCTAssertEqual(MailComposerResult.cancelled.rawValue, "cancelled")
    }
}
