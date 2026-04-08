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

    // MARK: - AppInfo Tests

    func testAppInfoSingleton() throws {
        let info = AppInfo.current
        // Should always be accessible
        XCTAssertNotNil(info)
    }

    func testAppInfoOSName() throws {
        let name = AppInfo.current.osName
        XCTAssertFalse(name.isEmpty)
        // On macOS test runner, should be "macOS"; on Android, "Android"
        #if os(macOS) && !SKIP
        XCTAssertEqual(name, "macOS")
        #endif
    }

    func testAppInfoOSVersion() throws {
        let version = AppInfo.current.osVersion
        XCTAssertFalse(version.isEmpty)
    }

    func testAppInfoDeviceModel() throws {
        let model = AppInfo.current.deviceModel
        XCTAssertFalse(model.isEmpty)
    }

    func testAppInfoBuildConfiguration() throws {
        // isDebug and isRelease should be inverses
        XCTAssertNotEqual(AppInfo.current.isDebug, AppInfo.current.isRelease)
    }

    func testAppInfoVersionWithBuild() throws {
        let vwb = AppInfo.current.versionWithBuild
        XCTAssertFalse(vwb.isEmpty)
        // Should always contain at least a version
        XCTAssertTrue(vwb.count >= 1)
    }

    func testAppInfoDisplayName() throws {
        // Display name may or may not be set depending on test context
        // Just verify the accessor doesn't crash
        let _ = AppInfo.current.displayName
    }

    func testAppInfoAppIdentifier() throws {
        // In a test context this may return the test bundle identifier or nil
        let _ = AppInfo.current.appIdentifier
    }

    func testAppInfoTestFlight() throws {
        // In test context, should not be TestFlight
        #if !SKIP
        XCTAssertFalse(AppInfo.current.isTestFlight)
        #endif
    }

    func testAppInfoMinimumOS() throws {
        let _ = AppInfo.current.minimumOSVersion
    }

    func testAppInfoURLSchemes() throws {
        let schemes = AppInfo.current.urlSchemes
        // Should return an array (possibly empty)
        XCTAssertTrue(schemes.count >= 0)
    }

    func testAppInfoDictionaryAccess() throws {
        // On iOS, should have keys; on Android returns empty
        let keys = AppInfo.current.infoDictionaryKeys
        XCTAssertTrue(keys.count >= 0)

        // Should not crash for any key
        let _ = AppInfo.current.infoDictionaryValue(forKey: "CFBundleIdentifier")
        let _ = AppInfo.current.infoDictionaryValue(forKey: "NonExistentKey")
    }

    // MARK: - DeviceInfo Tests

    func testDeviceInfoSingleton() throws {
        let info = DeviceInfo.current
        XCTAssertNotNil(info)
    }

    func testDeviceInfoScreenDimensions() throws {
        let width = DeviceInfo.current.screenWidth
        let height = DeviceInfo.current.screenHeight
        let scale = DeviceInfo.current.screenScale
        // In test context (macOS/Robolectric), dimensions may be zero but shouldn't be negative
        XCTAssertTrue(width >= 0)
        XCTAssertTrue(height >= 0)
        XCTAssertTrue(scale > 0)
    }

    func testDeviceInfoDeviceType() throws {
        let deviceType = DeviceInfo.current.deviceType
        // Should return a valid enum case
        let validTypes: [DeviceType] = [.phone, .tablet, .desktop, .tv, .watch, .unknown]
        XCTAssertTrue(validTypes.contains(deviceType))

        // isTablet and isPhone should be consistent with deviceType
        if DeviceInfo.current.isTablet {
            XCTAssertEqual(deviceType, .tablet)
        }
        if DeviceInfo.current.isPhone {
            XCTAssertEqual(deviceType, .phone)
        }
    }

    func testDeviceInfoManufacturer() throws {
        let manufacturer = DeviceInfo.current.manufacturer
        XCTAssertFalse(manufacturer.isEmpty)
        #if os(macOS) && !SKIP
        XCTAssertEqual(manufacturer, "Apple")
        #endif
    }

    func testDeviceInfoModelName() throws {
        let model = DeviceInfo.current.modelName
        XCTAssertFalse(model.isEmpty)
    }

    func testDeviceInfoBattery() throws {
        // Battery may be nil in test/simulator context
        let _ = DeviceInfo.current.batteryLevel

        let state = DeviceInfo.current.batteryState
        let validStates: [BatteryState] = [.unplugged, .charging, .full, .unknown]
        XCTAssertTrue(validStates.contains(state))
    }

    func testDeviceInfoNetworkStatus() throws {
        let status = DeviceInfo.current.networkStatus
        let validStatuses: [NetworkStatus] = [.offline, .wifi, .cellular, .ethernet, .other]
        XCTAssertTrue(validStatuses.contains(status))

        // isOnline should be consistent
        if status != .offline {
            XCTAssertTrue(DeviceInfo.current.isOnline)
        }
    }

    func testDeviceInfoNetworkConvenience() throws {
        let _ = DeviceInfo.current.isOnline
        let _ = DeviceInfo.current.isOnWifi
        let _ = DeviceInfo.current.isOnCellular
    }

    func testDeviceInfoMonitorNetwork() async throws {
        // Verify the stream can be created and yields at least one value
        var received = false
        let stream = DeviceInfo.current.monitorNetwork()
        for await status in stream {
            let validStatuses: [NetworkStatus] = [.offline, .wifi, .cellular, .ethernet, .other]
            XCTAssertTrue(validStatuses.contains(status))
            received = true
            break // Just check the first emitted value
        }
        XCTAssertTrue(received, "monitorNetwork should emit at least one initial value")
    }

    func testDeviceInfoLocale() throws {
        let locale = DeviceInfo.current.localeIdentifier
        XCTAssertFalse(locale.isEmpty)

        let tz = DeviceInfo.current.timeZoneIdentifier
        XCTAssertFalse(tz.isEmpty)

        // Language code may or may not be nil
        let _ = DeviceInfo.current.languageCode
    }

    func testDeviceTypeEnum() throws {
        let types: [DeviceType] = [.phone, .tablet, .desktop, .tv, .watch, .unknown]
        XCTAssertEqual(types.count, 6)
        XCTAssertEqual(DeviceType.phone.rawValue, "phone")
        XCTAssertEqual(DeviceType.tablet.rawValue, "tablet")
    }

    func testBatteryStateEnum() throws {
        let states: [BatteryState] = [.unplugged, .charging, .full, .unknown]
        XCTAssertEqual(states.count, 4)
        XCTAssertEqual(BatteryState.charging.rawValue, "charging")
    }

    func testNetworkStatusEnum() throws {
        let statuses: [NetworkStatus] = [.offline, .wifi, .cellular, .ethernet, .other]
        XCTAssertEqual(statuses.count, 5)
        XCTAssertEqual(NetworkStatus.wifi.rawValue, "wifi")
        XCTAssertEqual(NetworkStatus.offline.rawValue, "offline")
    }

    // MARK: - SBOM Tests

    /// A simple error type for missing test resources.
    private struct SBOMTestResourceMissing: Error {}

    /// Loads the bundled `sbom-test.spdx.json` resource as raw `Data`.
    private func loadSBOMTestData() throws -> Data {
        guard let url = Bundle.module.url(forResource: "sbom-test.spdx", withExtension: "json") else {
            XCTFail("Could not find sbom-test.spdx.json resource in test bundle")
            throw SBOMTestResourceMissing()
        }
        return try Data(contentsOf: url)
    }

    func testSBOMParseDocumentMetadata() throws {
        let data = try loadSBOMTestData()
        let doc = try SBOMDocument.parse(data: data)
        XCTAssertEqual(doc.spdxVersion, "SPDX-2.3")
        XCTAssertEqual(doc.SPDXID, "SPDXRef-DOCUMENT")
        XCTAssertEqual(doc.dataLicense, "CC0-1.0")
        XCTAssertEqual(doc.name, "skip-kit-sbom-test")
        XCTAssertEqual(doc.documentNamespace, "https://skip.dev/spdx/skip-kit-test")
    }

    func testSBOMParseCreationInfo() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        XCTAssertEqual(doc.creationInfo?.created, "2026-04-08T12:00:00Z")
        XCTAssertEqual(doc.creationInfo?.creators?.count, 1)
        XCTAssertEqual(doc.creationInfo?.creators?.first, "Tool: skip-kit-test")
        XCTAssertEqual(doc.creationInfo?.licenseListVersion, "3.22")
    }

    func testSBOMParsePackages() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        XCTAssertEqual(doc.packages.count, 5)

        // Find the skip-kit library package
        let skipKitPackage = doc.packages.first { $0.name == "skip-kit" }
        XCTAssertNotNil(skipKitPackage)
        XCTAssertEqual(skipKitPackage?.versionInfo, "1.0.0")
        XCTAssertEqual(skipKitPackage?.supplier, "Organization: Skip")
        XCTAssertEqual(skipKitPackage?.licenseDeclared, "MPL-2.0")
        XCTAssertEqual(skipKitPackage?.licenseConcluded, "MPL-2.0")
        XCTAssertEqual(skipKitPackage?.copyrightText, "Copyright 2025 Skip")
        XCTAssertEqual(skipKitPackage?.primaryPackagePurpose, "LIBRARY")
        XCTAssertEqual(skipKitPackage?.downloadLocation, "https://source.skip.tools/skip-kit.git")
        XCTAssertEqual(skipKitPackage?.filesAnalyzed, false)
        XCTAssertEqual(skipKitPackage?.externalRefs?.count, 1)
        XCTAssertEqual(skipKitPackage?.externalRefs?.first?.referenceType, "swiftpm")
        XCTAssertEqual(skipKitPackage?.externalRefs?.first?.referenceCategory, "PACKAGE-MANAGER")
    }

    func testSBOMParseChecksums() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        let euplPackage = doc.packages.first { $0.name == "example-eupl" }
        XCTAssertNotNil(euplPackage)
        XCTAssertEqual(euplPackage?.checksums?.count, 2)
        let sha1 = euplPackage?.checksums?.first { $0.algorithm == "SHA1" }
        XCTAssertEqual(sha1?.checksumValue, "0123456789abcdef0123456789abcdef01234567")
        let sha256 = euplPackage?.checksums?.first { $0.algorithm == "SHA256" }
        XCTAssertEqual(sha256?.checksumValue, "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210")
    }

    func testSBOMParseRelationships() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        XCTAssertEqual(doc.relationships?.count, 5)
        let describes = doc.relationships?.first { $0.relationshipType == "DESCRIBES" }
        XCTAssertEqual(describes?.spdxElementId, "SPDXRef-DOCUMENT")
        XCTAssertEqual(describes?.relatedSpdxElement, "SPDXRef-Package-test-app")
    }

    func testSBOMParseExtractedLicenses() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        XCTAssertEqual(doc.hasExtractedLicensingInfos?.count, 1)
        let extracted = doc.extractedLicense(forId: "LicenseRef-custom")
        XCTAssertNotNil(extracted)
        XCTAssertEqual(extracted?.name, "Custom Test License")
        XCTAssertEqual(extracted?.extractedText, "A custom license that is not on the SPDX list.")
        XCTAssertEqual(extracted?.seeAlsos?.count, 1)
        XCTAssertEqual(extracted?.seeAlsos?.first, "https://example.com/custom-license")
    }

    func testSBOMDependencyPackagesFiltersApplication() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        // The "test-app" package has APPLICATION purpose and should be filtered out.
        let deps = doc.dependencyPackages
        XCTAssertEqual(deps.count, 4)
        XCTAssertFalse(deps.contains { $0.name == "test-app" })
        XCTAssertTrue(deps.contains { $0.name == "skip-kit" })
        XCTAssertTrue(deps.contains { $0.name == "example-eupl" })
        XCTAssertTrue(deps.contains { $0.name == "example-eupl-helper" })
        XCTAssertTrue(deps.contains { $0.name == "example-custom" })
    }

    func testSBOMDependencyPackagesSortedByName() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        let names = doc.dependencyPackages.compactMap { $0.name }
        // Expect alphabetical (case-insensitive) order.
        XCTAssertEqual(names, ["example-custom", "example-eupl", "example-eupl-helper", "skip-kit"])
    }

    func testSBOMRootPackageSPDXID() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        XCTAssertEqual(doc.rootPackageSPDXID, "SPDXRef-Package-test-app")
    }

    func testSBOMTopLevelPackages() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        let top = doc.topLevelPackages
        // The root depends on skip-kit, example-eupl, and example-custom directly.
        // example-eupl-helper is transitive (depended on by example-eupl) and should NOT
        // appear in the top-level list.
        let names = top.compactMap { $0.name }
        XCTAssertEqual(names, ["example-custom", "example-eupl", "skip-kit"])
        XCTAssertFalse(names.contains("example-eupl-helper"))
    }

    func testSBOMDirectDependencies() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        guard let euplPackage = doc.packages.first(where: { $0.name == "example-eupl" }) else {
            XCTFail("Expected to find example-eupl package")
            return
        }
        let subDeps = doc.directDependencies(of: euplPackage)
        XCTAssertEqual(subDeps.count, 1)
        XCTAssertEqual(subDeps.first?.name, "example-eupl-helper")

        // skip-kit has no transitive dependencies in the test fixture.
        guard let skipKitPackage = doc.packages.first(where: { $0.name == "skip-kit" }) else {
            XCTFail("Expected to find skip-kit package")
            return
        }
        XCTAssertTrue(doc.directDependencies(of: skipKitPackage).isEmpty)
    }

    func testSBOMDirectDependenciesSorted() throws {
        let doc = try SBOMDocument.parse(data: try loadSBOMTestData())
        // The root package's direct dependencies should be sorted by name.
        let rootDeps = doc.directDependencies(ofSPDXID: "SPDXRef-Package-test-app")
        let names = rootDeps.compactMap { $0.name }
        XCTAssertEqual(names, ["example-custom", "example-eupl", "skip-kit"])
    }

    func testSBOMDisplayMode() throws {
        // Hierarchy is the default.
        XCTAssertEqual(SBOMDisplayMode.hierarchy.rawValue, "hierarchy")
        XCTAssertEqual(SBOMDisplayMode.flat.rawValue, "flat")
    }

    func testSBOMSPDXLicenseIsUnknown() throws {
        XCTAssertTrue(SPDXLicense.isUnknown(nil))
        XCTAssertTrue(SPDXLicense.isUnknown(""))
        XCTAssertTrue(SPDXLicense.isUnknown("NOASSERTION"))
        XCTAssertTrue(SPDXLicense.isUnknown("NONE"))
        XCTAssertFalse(SPDXLicense.isUnknown("MIT"))
        XCTAssertFalse(SPDXLicense.isUnknown("EUPL-1.2"))
    }

    func testSBOMSPDXCanonicalIdentifier() throws {
        XCTAssertEqual(SPDXLicense.canonicalIdentifier("MIT"), "MIT")
        XCTAssertEqual(SPDXLicense.canonicalIdentifier("EUPL-1.2"), "EUPL-1.2")
        XCTAssertEqual(SPDXLicense.canonicalIdentifier("Apache-2.0"), "Apache-2.0")
        // Compound expressions should yield just the head identifier.
        XCTAssertEqual(SPDXLicense.canonicalIdentifier("MIT OR Apache-2.0"), "MIT")
        XCTAssertEqual(SPDXLicense.canonicalIdentifier("LGPL-3.0-only WITH LGPL-3.0-linking-exception"), "LGPL-3.0-only")
        // NOASSERTION yields nil.
        XCTAssertNil(SPDXLicense.canonicalIdentifier("NOASSERTION"))
        XCTAssertNil(SPDXLicense.canonicalIdentifier(nil))
        // LicenseRef- IDs are not on spdx.org/licenses and should yield nil.
        XCTAssertNil(SPDXLicense.canonicalIdentifier("LicenseRef-custom"))
    }

    func testSBOMSPDXLicensePageURL() throws {
        XCTAssertEqual(SPDXLicense.licensePageURL(for: "EUPL-1.2")?.absoluteString, "https://spdx.org/licenses/EUPL-1.2.html")
        XCTAssertEqual(SPDXLicense.licensePageURL(for: "MPL-2.0")?.absoluteString, "https://spdx.org/licenses/MPL-2.0.html")
        XCTAssertEqual(SPDXLicense.licensePageURL(for: "Apache-2.0")?.absoluteString, "https://spdx.org/licenses/Apache-2.0.html")
        // Compound expressions should still resolve to the head license's page.
        XCTAssertEqual(SPDXLicense.licensePageURL(for: "LGPL-3.0-only WITH LGPL-3.0-linking-exception")?.absoluteString, "https://spdx.org/licenses/LGPL-3.0-only.html")
        XCTAssertNil(SPDXLicense.licensePageURL(for: "NOASSERTION"))
        XCTAssertNil(SPDXLicense.licensePageURL(for: nil))
        XCTAssertNil(SPDXLicense.licensePageURL(for: "LicenseRef-custom"))
    }

    func testSBOMResourceNames() throws {
        XCTAssertEqual(sbomDarwinResourceName, "sbom-darwin-ios.spdx")
        XCTAssertEqual(sbomLinuxAndroidResourceName, "sbom-linux-android.spdx")
        XCTAssertEqual(sbomResourceExtension, "json")
        // Default resource name is platform-specific.
        #if os(Android)
        XCTAssertEqual(SBOMDocument.defaultResourceName, sbomLinuxAndroidResourceName)
        #else
        XCTAssertEqual(SBOMDocument.defaultResourceName, sbomDarwinResourceName)
        #endif
    }

    func testSBOMBundleContainsSBOM() throws {
        // The test bundle does not contain a sbom-darwin-ios.spdx.json or sbom-linux-android.spdx.json,
        // so this should return false. (We deliberately use a different name for the test fixture so
        // that we can also exercise the negative case.)
        XCTAssertFalse(SBOMDocument.bundleContainsSBOM(Bundle.module))
        XCTAssertNil(try SBOMDocument.load(from: Bundle.module))
    }
}
