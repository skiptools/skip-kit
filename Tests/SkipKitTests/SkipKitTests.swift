// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
@testable import SkipKit

let logger: Logger = Logger(subsystem: "SkipKit", category: "Tests")

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
@available(macOS 13, *)
final class SkipKitTests: XCTestCase {
    func testSkipKit() throws {
        logger.log("running testSkipKit")

        if isRobolectric || isJava {
            return // Robolectric does not automatically add a ShadowPackageManager, so calls result in an NPE
        }

        // on iOS, this seems to correspond to the version of XCUnit current running, like 15.2 or 15.4
        XCTAssertNotEqual("", ProcessInfo.processInfo.appVersionString)
        XCTAssertEqual(0, ProcessInfo.processInfo.appVersionNumber)
    }

}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
