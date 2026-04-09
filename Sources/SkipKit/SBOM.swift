// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation

// MARK: - SPDX SBOM Model

/// A parsed SPDX (Software Package Data Exchange) Software Bill of Materials document.
///
/// This is a Codable representation of the SPDX 2.3 JSON format produced by tools like
/// `skip sbom create` (for the iOS/SwiftPM dependency tree) and the `spdx-gradle-plugin`
/// (for the Android/Gradle dependency tree).
///
/// See: https://spdx.github.io/spdx-spec/v2.3/
struct SBOMDocument: Codable, Hashable {
    /// The SPDX version this document conforms to (e.g., `SPDX-2.3`).
    var spdxVersion: String?
    /// The SPDX identifier for this document (typically `SPDXRef-DOCUMENT`).
    var SPDXID: String?
    /// The data license for the SPDX document content (typically `CC0-1.0`).
    var dataLicense: String?
    /// A human-readable name for the document.
    var name: String?
    /// A unique URI namespace identifying this document.
    var documentNamespace: String?
    /// Information about how and when the SBOM was created.
    var creationInfo: SBOMCreationInfo?
    /// The packages described by this SBOM.
    var packages: [SBOMPackage]
    /// Relationships between SPDX elements (e.g., DEPENDS_ON).
    var relationships: [SBOMRelationship]?
    /// Custom (non-SPDX-listed) license definitions used by packages in this document.
    var hasExtractedLicensingInfos: [SBOMExtractedLicense]?

    init(
        spdxVersion: String? = nil,
        SPDXID: String? = nil,
        dataLicense: String? = nil,
        name: String? = nil,
        documentNamespace: String? = nil,
        creationInfo: SBOMCreationInfo? = nil,
        packages: [SBOMPackage] = [],
        relationships: [SBOMRelationship]? = nil,
        hasExtractedLicensingInfos: [SBOMExtractedLicense]? = nil
    ) {
        self.spdxVersion = spdxVersion
        self.SPDXID = SPDXID
        self.dataLicense = dataLicense
        self.name = name
        self.documentNamespace = documentNamespace
        self.creationInfo = creationInfo
        self.packages = packages
        self.relationships = relationships
        self.hasExtractedLicensingInfos = hasExtractedLicensingInfos
    }
}

/// Metadata about how the SBOM was generated.
struct SBOMCreationInfo: Codable, Hashable {
    /// ISO 8601 timestamp of when the document was created.
    var created: String?
    /// The tools and/or organizations that created this document.
    var creators: [String]?
    /// The version of the SPDX license list used.
    var licenseListVersion: String?

    init(created: String? = nil, creators: [String]? = nil, licenseListVersion: String? = nil) {
        self.created = created
        self.creators = creators
        self.licenseListVersion = licenseListVersion
    }
}

/// A single package (dependency) tracked in the SBOM.
struct SBOMPackage: Codable, Hashable, Identifiable {
    /// The SPDX identifier for this package.
    var SPDXID: String?
    /// Human-readable package name.
    var name: String?
    /// Version string for the package.
    var versionInfo: String?
    /// Supplier (organization or person) that distributes the package.
    var supplier: String?
    /// Originator (the party that originally created the package).
    var originator: String?
    /// URL or other locator describing where the package can be downloaded.
    var downloadLocation: String?
    /// Free-form description of the package.
    var description: String?
    /// A short summary of the package.
    var summary: String?
    /// The package homepage.
    var homepage: String?
    /// The license that the SBOM author concluded applies (after analysis).
    var licenseConcluded: String?
    /// The license that the package author declared in the package.
    var licenseDeclared: String?
    /// Additional comments about the license.
    var licenseComments: String?
    /// Copyright notices declared by the package.
    var copyrightText: String?
    /// What this package is for (e.g., `LIBRARY`, `APPLICATION`).
    var primaryPackagePurpose: String?
    /// Source-info string (often from the gradle plugin).
    var sourceInfo: String?
    /// Whether the file contents of the package were analyzed.
    var filesAnalyzed: Bool?
    /// Cryptographic checksums for the package archive.
    var checksums: [SBOMChecksum]?
    /// External references such as `purl` (package URL) and SwiftPM repository URLs.
    var externalRefs: [SBOMExternalRef]?
    /// License information extracted from the package's files.
    var licenseInfoFromFiles: [String]?

    var id: String { SPDXID ?? (name ?? "") }

    init(
        SPDXID: String? = nil,
        name: String? = nil,
        versionInfo: String? = nil,
        supplier: String? = nil,
        originator: String? = nil,
        downloadLocation: String? = nil,
        description: String? = nil,
        summary: String? = nil,
        homepage: String? = nil,
        licenseConcluded: String? = nil,
        licenseDeclared: String? = nil,
        licenseComments: String? = nil,
        copyrightText: String? = nil,
        primaryPackagePurpose: String? = nil,
        sourceInfo: String? = nil,
        filesAnalyzed: Bool? = nil,
        checksums: [SBOMChecksum]? = nil,
        externalRefs: [SBOMExternalRef]? = nil,
        licenseInfoFromFiles: [String]? = nil
    ) {
        self.SPDXID = SPDXID
        self.name = name
        self.versionInfo = versionInfo
        self.supplier = supplier
        self.originator = originator
        self.downloadLocation = downloadLocation
        self.description = description
        self.summary = summary
        self.homepage = homepage
        self.licenseConcluded = licenseConcluded
        self.licenseDeclared = licenseDeclared
        self.licenseComments = licenseComments
        self.copyrightText = copyrightText
        self.primaryPackagePurpose = primaryPackagePurpose
        self.sourceInfo = sourceInfo
        self.filesAnalyzed = filesAnalyzed
        self.checksums = checksums
        self.externalRefs = externalRefs
        self.licenseInfoFromFiles = licenseInfoFromFiles
    }
}

/// A cryptographic checksum entry on a package.
struct SBOMChecksum: Codable, Hashable {
    /// Hash algorithm name (e.g., `SHA1`, `SHA256`).
    var algorithm: String?
    /// The hex-encoded checksum value.
    var checksumValue: String?

    init(algorithm: String? = nil, checksumValue: String? = nil) {
        self.algorithm = algorithm
        self.checksumValue = checksumValue
    }
}

/// An external reference attached to a package, such as a Package URL (`purl`) or SwiftPM repository.
struct SBOMExternalRef: Codable, Hashable {
    /// Category (e.g., `PACKAGE-MANAGER`, `SECURITY`).
    var referenceCategory: String?
    /// The locator string (the meaning depends on `referenceType`).
    var referenceLocator: String?
    /// The type of reference (e.g., `purl`, `swiftpm`).
    var referenceType: String?

    init(referenceCategory: String? = nil, referenceLocator: String? = nil, referenceType: String? = nil) {
        self.referenceCategory = referenceCategory
        self.referenceLocator = referenceLocator
        self.referenceType = referenceType
    }
}

/// A relationship between two SPDX elements (e.g., `A DEPENDS_ON B`).
struct SBOMRelationship: Codable, Hashable {
    var spdxElementId: String?
    var relatedSpdxElement: String?
    var relationshipType: String?

    init(spdxElementId: String? = nil, relatedSpdxElement: String? = nil, relationshipType: String? = nil) {
        self.spdxElementId = spdxElementId
        self.relatedSpdxElement = relatedSpdxElement
        self.relationshipType = relationshipType
    }
}

/// A custom license definition for licenses that are not on the SPDX License List.
/// Identified by `LicenseRef-…` rather than a standard SPDX identifier.
struct SBOMExtractedLicense: Codable, Hashable {
    /// The `LicenseRef-…` identifier used to refer to this license.
    var licenseId: String?
    /// The full text of the license.
    var extractedText: String?
    /// A human-readable name for the license.
    var name: String?
    /// URLs where the license text or more information can be found.
    var seeAlsos: [String]?

    init(licenseId: String? = nil, extractedText: String? = nil, name: String? = nil, seeAlsos: [String]? = nil) {
        self.licenseId = licenseId
        self.extractedText = extractedText
        self.name = name
        self.seeAlsos = seeAlsos
    }
}

// MARK: - Loading

/// The standard resource name (without extension) for the iOS/Darwin SPDX SBOM file.
let sbomDarwinResourceName = "sbom-darwin-ios.spdx"
/// The standard resource name (without extension) for the Android/Linux SPDX SBOM file.
let sbomLinuxAndroidResourceName = "sbom-linux-android.spdx"
/// The file extension for SPDX SBOM files.
let sbomResourceExtension = "json"

extension SBOMDocument {
    /// The default resource name for the SBOM appropriate for the current platform
    /// (`sbom-darwin-ios.spdx` on Apple platforms, `sbom-linux-android.spdx` on Android).
    static var defaultResourceName: String {
        #if os(Android)
        return sbomLinuxAndroidResourceName
        #else
        return sbomDarwinResourceName
        #endif
    }

    /// Loads the SBOM document for the current platform from the given bundle, if present.
    ///
    /// On Apple platforms this looks for `sbom-darwin-ios.spdx.json`. On Android, it looks
    /// for `sbom-linux-android.spdx.json`.
    ///
    /// - Parameter bundle: The bundle containing the SBOM resource.
    /// - Returns: The parsed `SBOMDocument`, or `nil` if no SBOM resource is present in the bundle.
    /// - Throws: A decoding error if the resource exists but cannot be parsed as SPDX JSON.
    static func load(from bundle: Bundle) throws -> SBOMDocument? {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: sbomResourceExtension) else {
            return nil
        }
        return try load(from: url)
    }

    /// Loads and parses an SPDX JSON SBOM document from the given file URL.
    static func load(from url: URL) throws -> SBOMDocument {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    /// Parses an SPDX JSON SBOM document from raw `Data`.
    static func parse(data: Data) throws -> SBOMDocument {
        let decoder = JSONDecoder()
        return try decoder.decode(SBOMDocument.self, from: data)
    }

    /// Returns the raw bytes of the SBOM resource for the current platform from the given
    /// bundle, if present. Useful for sharing the file via the system share sheet without
    /// re-encoding it.
    static func rawData(from bundle: Bundle) -> Data? {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: sbomResourceExtension) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    /// Returns the URL of the SBOM resource for the current platform from the given
    /// bundle, if present.
    static func resourceURL(in bundle: Bundle) -> URL? {
        return bundle.url(forResource: defaultResourceName, withExtension: sbomResourceExtension)
    }

    /// Returns `true` if the given bundle contains an SBOM resource for the current platform.
    static func bundleContainsSBOM(_ bundle: Bundle) -> Bool {
        return resourceURL(in: bundle) != nil
    }
}

extension SBOMDocument {
    /// All packages in the document excluding any "root" application packages (those with
    /// `primaryPackagePurpose == "APPLICATION"` or those that match the document name),
    /// sorted alphabetically by name (case-insensitive). This is the "flat" list of every
    /// dependency users typically want to see in a Bill of Materials view.
    var dependencyPackages: [SBOMPackage] {
        let docName = self.name ?? ""
        let filtered = packages.filter { pkg in
            if pkg.primaryPackagePurpose == "APPLICATION" {
                return false
            }
            // Filter out the root project package, which the gradle plugin emits with the
            // document name and a sourceInfo of "git+<no-scm-uri>...".
            if let pkgName = pkg.name, pkgName == docName {
                return false
            }
            return true
        }
        return sortedByName(filtered)
    }

    /// The SPDX identifier of the root package described by this document, found via the
    /// `SPDXRef-DOCUMENT DESCRIBES <root>` relationship. Falls back to the first package
    /// with `primaryPackagePurpose == "APPLICATION"` if no `DESCRIBES` relationship exists.
    var rootPackageSPDXID: String? {
        if let rels = relationships {
            for rel in rels {
                if rel.relationshipType == "DESCRIBES" && rel.spdxElementId == "SPDXRef-DOCUMENT" {
                    if let related = rel.relatedSpdxElement {
                        return related
                    }
                }
            }
        }
        for pkg in packages {
            if pkg.primaryPackagePurpose == "APPLICATION" {
                return pkg.SPDXID
            }
        }
        return nil
    }

    /// Looks up a package by its SPDX identifier.
    func package(forSPDXID spdxId: String) -> SBOMPackage? {
        for pkg in packages {
            if pkg.SPDXID == spdxId {
                return pkg
            }
        }
        return nil
    }

    /// Returns the packages directly depended on by the package with the given SPDX
    /// identifier (i.e., `<spdxId> DEPENDS_ON X`), sorted alphabetically by name.
    /// If the document has no relationships, returns an empty array.
    func directDependencies(ofSPDXID spdxId: String) -> [SBOMPackage] {
        guard let rels = relationships else { return [] }
        var result: [SBOMPackage] = []
        for rel in rels {
            if rel.relationshipType != "DEPENDS_ON" { continue }
            if rel.spdxElementId != spdxId { continue }
            guard let target = rel.relatedSpdxElement else { continue }
            if let pkg = package(forSPDXID: target) {
                result.append(pkg)
            }
        }
        return sortedByName(result)
    }

    /// Returns the direct dependencies of the given package, sorted alphabetically by name.
    func directDependencies(of package: SBOMPackage) -> [SBOMPackage] {
        guard let id = package.SPDXID else { return [] }
        return directDependencies(ofSPDXID: id)
    }

    /// The top-level dependency packages: the packages directly depended on by the document's
    /// root package via the `DEPENDS_ON` relationship, sorted alphabetically by name.
    ///
    /// If the document does not contain a `DESCRIBES` relationship or any `DEPENDS_ON`
    /// relationships from the root, this falls back to `dependencyPackages` so the
    /// hierarchy view still has something useful to display.
    var topLevelPackages: [SBOMPackage] {
        guard let rootId = rootPackageSPDXID else {
            return dependencyPackages
        }
        let direct = directDependencies(ofSPDXID: rootId)
        if direct.isEmpty {
            return dependencyPackages
        }
        return direct
    }

    /// Looks up an extracted license by its `LicenseRef-…` identifier.
    func extractedLicense(forId licenseId: String) -> SBOMExtractedLicense? {
        guard let infos = hasExtractedLicensingInfos else { return nil }
        for info in infos {
            if info.licenseId == licenseId {
                return info
            }
        }
        return nil
    }

    /// Sorts an array of packages alphabetically by `name`, case-insensitively. Packages
    /// without a name are pushed to the end of the list.
    private func sortedByName(_ pkgs: [SBOMPackage]) -> [SBOMPackage] {
        return pkgs.sorted { lhs, rhs in
            let l = (lhs.name ?? "~").lowercased()
            let r = (rhs.name ?? "~").lowercased()
            return l < r
        }
    }
}

/// Controls how `SBOMView` presents the bundled software dependencies.
public enum SBOMDisplayMode: String, Hashable {
    /// Show only the top-level dependencies (those directly depended on by the
    /// document's root package via the `DEPENDS_ON` relationship). The detail view
    /// for each package then lists its own direct dependencies, allowing the user
    /// to navigate the dependency tree.
    case hierarchy
    /// Show every dependency package in the SBOM as a single flat, alphabetised list.
    case flat
}

// MARK: - License helpers

/// Helpers for working with SPDX license identifiers.
enum SPDXLicense {
    /// `NOASSERTION` is the SPDX sentinel meaning "no information was provided".
    static let noAssertion = "NOASSERTION"
    /// `NONE` is the SPDX sentinel meaning "the field has explicitly no value".
    static let none = "NONE"

    /// Returns `true` if the given license string is missing or one of the SPDX
    /// "no information" sentinels (`NOASSERTION`, `NONE`).
    static func isUnknown(_ license: String?) -> Bool {
        guard let license = license else { return true }
        if license.isEmpty { return true }
        if license == noAssertion { return true }
        if license == none { return true }
        return false
    }

    /// Returns the SPDX license identifier suitable for linking to spdx.org/licenses/,
    /// stripping any compound expressions like `WITH` clauses or `OR`/`AND` operators.
    /// Returns `nil` if no usable identifier can be extracted, or if the identifier is
    /// a `LicenseRef-…` (which is a custom license, not on the SPDX list).
    static func canonicalIdentifier(_ license: String?) -> String? {
        guard let raw = license else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if isUnknown(trimmed) { return nil }
        // Strip enclosing parentheses
        var s = trimmed
        while s.hasPrefix("(") && s.hasSuffix(")") {
            s = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Take the first identifier from a compound expression like "MIT OR Apache-2.0"
        // or "LGPL-3.0-only WITH LGPL-3.0-linking-exception".
        let separators = [" WITH ", " OR ", " AND ", " or ", " and ", " with "]
        var head = s
        for sep in separators {
            if let range = head.range(of: sep) {
                head = String(head[head.startIndex..<range.lowerBound])
            }
        }
        head = head.trimmingCharacters(in: .whitespacesAndNewlines)
        if head.isEmpty { return nil }
        // LicenseRef-... is not on spdx.org/licenses
        if head.hasPrefix("LicenseRef-") { return nil }
        return head
    }

    /// Returns the URL on spdx.org/licenses/ for the given SPDX license identifier,
    /// or `nil` if no canonical SPDX identifier could be extracted.
    static func licensePageURL(for license: String?) -> URL? {
        guard let id = canonicalIdentifier(license) else { return nil }
        return URL(string: "https://spdx.org/licenses/\(id).html")
    }
}

#endif // !SKIP_BRIDGE
