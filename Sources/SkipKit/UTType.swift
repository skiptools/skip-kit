// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if !SKIP
@_exported import UniformTypeIdentifiers
#else
public struct UTType: Equatable, Hashable {
    var identifier: String
    var preferredMIMEType: String?
    
    public init?(identifier: String, mimeType: String?, conformingTo supertype: UTType? = .data) {
            self.identifier = identifier
            self.preferredMIMEType = mimeType
        }
}

public extension UTType {
    public static let item: UTType = UTType(identifier: "public.item", mimeType: nil)!
    public static let content: UTType = UTType(identifier: "public.content", mimeType: nil)!
    public static let compositeContent: UTType = UTType(identifier: "public.composite-content", mimeType: nil)!
    public static let diskImage: UTType = UTType(identifier: "public.disk-image", mimeType: nil)!
    public static let data: UTType = UTType(identifier: "public.data", mimeType: nil)!
    public static let directory: UTType = UTType(identifier: "public.directory", mimeType: nil)!
    public static let resolvable: UTType = UTType(identifier: "com.apple.resolvable", mimeType: nil)!
    public static let symbolicLink: UTType = UTType(identifier: "public.symlink", mimeType: nil)!
    public static let executable: UTType = UTType(identifier: "public.executable", mimeType: nil)!
    public static let mountPoint: UTType = UTType(identifier: "com.apple.mount-point", mimeType: nil)!
    public static let aliasFile: UTType = UTType(identifier: "com.apple.alias-file", mimeType: nil)!
    public static let urlBookmarkData: UTType = UTType(identifier: "com.apple.bookmark", mimeType: nil)!
    public static let url: UTType = UTType(identifier: "public.url", mimeType: nil)!
    public static let fileURL: UTType = UTType(identifier: "public.file-url", mimeType: nil)!
    public static let text: UTType = UTType(identifier: "public.text", mimeType: nil)!
    public static let plainText: UTType = UTType(identifier: "public.plain-text", mimeType: "text/plain")!
    public static let utf8PlainText: UTType = UTType(identifier: "public.utf8-plain-text", mimeType: "text/plain;charset=utf-8")!
    public static let utf16ExternalPlainText: UTType = UTType(identifier: "public.utf16-external-plain-text", mimeType: nil)!
    public static let utf16PlainText: UTType = UTType(identifier: "public.utf16-plain-text", mimeType: "text/plain;charset=utf-16")!
    public static let delimitedText: UTType = UTType(identifier: "public.delimited-values-text", mimeType: nil)!
    public static let commaSeparatedText: UTType = UTType(identifier: "public.comma-separated-values-text", mimeType: "text/csv")!
    public static let tabSeparatedText: UTType = UTType(identifier: "public.tab-separated-values-text", mimeType: "text/tab-separated-values")!
    public static let utf8TabSeparatedText: UTType = UTType(identifier: "public.utf8-tab-separated-values-text", mimeType: nil)!
    public static let rtf: UTType = UTType(identifier: "public.rtf", mimeType: "text/rtf")!
    public static let html: UTType = UTType(identifier: "public.html", mimeType: "text/html")!
    public static let xml: UTType = UTType(identifier: "public.xml", mimeType: "application/xml")!
    public static let yaml: UTType = UTType(identifier: "public.yaml", mimeType: "application/x-yaml")!
    public static let css: UTType = UTType(identifier: "public.css", mimeType: "text/css")!
    public static let sourceCode: UTType = UTType(identifier: "public.source-code", mimeType: nil)!
    public static let assemblyLanguageSource: UTType = UTType(identifier: "public.assembly-source", mimeType: nil)!
    public static let cSource: UTType = UTType(identifier: "public.c-source", mimeType: nil)!
    public static let objectiveCSource: UTType = UTType(identifier: "public.objective-c-source", mimeType: nil)!
    public static let swiftSource: UTType = UTType(identifier: "public.swift-source", mimeType: nil)!
    public static let cPlusPlusSource: UTType = UTType(identifier: "public.c-plus-plus-source", mimeType: nil)!
    public static let objectiveCPlusPlusSource: UTType = UTType(identifier: "public.objective-c-plus-plus-source", mimeType: nil)!
    public static let cHeader: UTType = UTType(identifier: "public.c-header", mimeType: nil)!
    public static let cPlusPlusHeader: UTType = UTType(identifier: "public.c-plus-plus-header", mimeType: nil)!
    public static let script: UTType = UTType(identifier: "public.script", mimeType: nil)!
    public static let appleScript: UTType = UTType(identifier: "com.apple.applescript.text", mimeType: nil)!
    public static let osaScript: UTType = UTType(identifier: "com.apple.applescript.script", mimeType: nil)!
    public static let osaScriptBundle: UTType = UTType(identifier: "com.apple.applescript.script-bundle", mimeType: nil)!
    public static let javaScript: UTType = UTType(identifier: "com.netscape.javascript-source", mimeType: "text/javascript")!
    public static let shellScript: UTType = UTType(identifier: "public.shell-script", mimeType: nil)!
    public static let perlScript: UTType = UTType(identifier: "public.perl-script", mimeType: "text/x-perl-script")!
    public static let pythonScript: UTType = UTType(identifier: "public.python-script", mimeType: "text/x-python-script")!
    public static let rubyScript: UTType = UTType(identifier: "public.ruby-script", mimeType: "text/x-ruby-script")!
    public static let phpScript: UTType = UTType(identifier: "public.php-script", mimeType: "text/php")!
    public static let makefile: UTType = UTType(identifier: "public.make-source", mimeType: nil)!
    public static let json: UTType = UTType(identifier: "public.json", mimeType: "application/json")!
    public static let propertyList: UTType = UTType(identifier: "com.apple.property-list", mimeType: nil)!
    public static let xmlPropertyList: UTType = UTType(identifier: "com.apple.xml-property-list", mimeType: nil)!
    public static let binaryPropertyList: UTType = UTType(identifier: "com.apple.binary-property-list", mimeType: nil)!
    public static let pdf: UTType = UTType(identifier: "com.adobe.pdf", mimeType: "application/pdf")!
    public static let rtfd: UTType = UTType(identifier: "com.apple.rtfd", mimeType: nil)!
    public static let flatRTFD: UTType = UTType(identifier: "com.apple.flat-rtfd", mimeType: nil)!
    public static let webArchive: UTType = UTType(identifier: "com.apple.webarchive", mimeType: "application/x-webarchive")!
    public static let image: UTType = UTType(identifier: "public.image", mimeType: "image/*")!
    public static let jpeg: UTType = UTType(identifier: "public.jpeg", mimeType: "image/jpeg")!
    public static let tiff: UTType = UTType(identifier: "public.tiff", mimeType: "image/tiff")!
    public static let gif: UTType = UTType(identifier: "com.compuserve.gif", mimeType: "image/gif")!
    public static let png: UTType = UTType(identifier: "public.png", mimeType: "image/png")!
    public static let icns: UTType = UTType(identifier: "com.apple.icns", mimeType: nil)!
    public static let bmp: UTType = UTType(identifier: "com.microsoft.bmp", mimeType: "image/bmp")!
    public static let ico: UTType = UTType(identifier: "com.microsoft.ico", mimeType: "image/vnd.microsoft.icon")!
    public static let rawImage: UTType = UTType(identifier: "public.camera-raw-image", mimeType: nil)!
    public static let svg: UTType = UTType(identifier: "public.svg-image", mimeType: "image/svg+xml")!
    public static let livePhoto: UTType = UTType(identifier: "com.apple.live-photo", mimeType: nil)!
    public static let heif: UTType = UTType(identifier: "public.heif", mimeType: "image/heif")!
    public static let heic: UTType = UTType(identifier: "public.heic", mimeType: "image/heic")!
    public static let heics: UTType = UTType(identifier: "public.heics", mimeType: "image/heic-sequence")!
    public static let webP: UTType = UTType(identifier: "org.webmproject.webp", mimeType: "image/webp")!
    public static let exr: UTType = UTType(identifier: "com.ilm.openexr-image", mimeType: nil)!
    public static let dng: UTType = UTType(identifier: "com.adobe.raw-image", mimeType: "image/x-adobe-dng")!
    public static let jpegxl: UTType = UTType(identifier: "public.jpeg-xl", mimeType: "image/jxl")!
    public static let threeDContent: UTType = UTType(identifier: "public.3d-content", mimeType: nil)!
    public static let usd: UTType = UTType(identifier: "com.pixar.universal-scene-description", mimeType: nil)!
    public static let usdz: UTType = UTType(identifier: "com.pixar.universal-scene-description-mobile", mimeType: "model/vnd.usdz+zip")!
    public static let realityFile: UTType = UTType(identifier: "com.apple.reality", mimeType: "model/vnd.reality")!
    public static let sceneKitScene: UTType = UTType(identifier: "com.apple.scenekit.scene", mimeType: nil)!
    public static let arReferenceObject: UTType = UTType(identifier: "com.apple.arobject", mimeType: nil)!
    public static let audiovisualContent: UTType = UTType(identifier: "public.audiovisual-content", mimeType: nil)!
    public static let movie: UTType = UTType(identifier: "public.movie", mimeType: nil)!
    public static let video: UTType = UTType(identifier: "public.video", mimeType: nil)!
    public static let audio: UTType = UTType(identifier: "public.audio", mimeType: nil)!
    public static let quickTimeMovie: UTType = UTType(identifier: "com.apple.quicktime-movie", mimeType: "video/quicktime")!
    public static let mpeg: UTType = UTType(identifier: "public.mpeg", mimeType: "video/mpeg")!
    public static let mpeg2Video: UTType = UTType(identifier: "public.mpeg-2-video", mimeType: "video/mpeg2")!
    public static let mpeg2TransportStream: UTType = UTType(identifier: "public.mpeg-2-transport-stream", mimeType: nil)!
    public static let mp3: UTType = UTType(identifier: "public.mp3", mimeType: "audio/mpeg")!
    public static let mpeg4Movie: UTType = UTType(identifier: "public.mpeg-4", mimeType: "video/mp4")!
    public static let mpeg4Audio: UTType = UTType(identifier: "public.mpeg-4-audio", mimeType: "audio/mp4")!
    public static let appleProtectedMPEG4Audio: UTType = UTType(identifier: "com.apple.protected-mpeg-4-audio", mimeType: nil)!
    public static let appleProtectedMPEG4Video: UTType = UTType(identifier: "com.apple.protected-mpeg-4-video", mimeType: nil)!
    public static let avi: UTType = UTType(identifier: "public.avi", mimeType: "video/avi")!
    public static let aiff: UTType = UTType(identifier: "public.aiff-audio", mimeType: "audio/aiff")!
    public static let wav: UTType = UTType(identifier: "com.microsoft.waveform-audio", mimeType: "audio/vnd.wave")!
    public static let midi: UTType = UTType(identifier: "public.midi-audio", mimeType: "audio/midi")!
    public static let playlist: UTType = UTType(identifier: "public.playlist", mimeType: nil)!
    public static let m3uPlaylist: UTType = UTType(identifier: "public.m3u-playlist", mimeType: "audio/mpegurl")!
    public static let folder: UTType = UTType(identifier: "public.folder", mimeType: nil)!
    public static let volume: UTType = UTType(identifier: "public.volume", mimeType: nil)!
    public static let package: UTType = UTType(identifier: "com.apple.package", mimeType: nil)!
    public static let bundle: UTType = UTType(identifier: "com.apple.bundle", mimeType: nil)!
    public static let pluginBundle: UTType = UTType(identifier: "com.apple.plugin", mimeType: nil)!
    public static let spotlightImporter: UTType = UTType(identifier: "com.apple.metadata-importer", mimeType: nil)!
    public static let quickLookGenerator: UTType = UTType(identifier: "com.apple.quicklook-generator", mimeType: nil)!
    public static let xpcService: UTType = UTType(identifier: "com.apple.xpc-service", mimeType: nil)!
    public static let framework: UTType = UTType(identifier: "com.apple.framework", mimeType: nil)!
    public static let application: UTType = UTType(identifier: "com.apple.application", mimeType: nil)!
    public static let applicationBundle: UTType = UTType(identifier: "com.apple.application-bundle", mimeType: nil)!
    public static let applicationExtension: UTType = UTType(identifier: "com.apple.application-and-system-extension", mimeType: nil)!
    public static let unixExecutable: UTType = UTType(identifier: "public.unix-executable", mimeType: nil)!
    public static let exe: UTType = UTType(identifier: "com.microsoft.windows-executable", mimeType: "application/x-msdownload")!
    public static let systemPreferencesPane: UTType = UTType(identifier: "com.apple.systempreference.prefpane", mimeType: nil)!
    public static let archive: UTType = UTType(identifier: "public.archive", mimeType: nil)!
    public static let gzip: UTType = UTType(identifier: "org.gnu.gnu-zip-archive", mimeType: "application/x-gzip")!
    public static let bz2: UTType = UTType(identifier: "public.bzip2-archive", mimeType: "application/x-bzip2")!
    public static let zip: UTType = UTType(identifier: "public.zip-archive", mimeType: "application/zip")!
    public static let appleArchive: UTType = UTType(identifier: "com.apple.archive", mimeType: nil)!
    public static let tarArchive: UTType = UTType(identifier: "public.tar-archive", mimeType: "application/x-tar")!
    public static let spreadsheet: UTType = UTType(identifier: "public.spreadsheet", mimeType: nil)!
    public static let presentation: UTType = UTType(identifier: "public.presentation", mimeType: nil)!
    public static let database: UTType = UTType(identifier: "public.database", mimeType: nil)!
    public static let message: UTType = UTType(identifier: "public.message", mimeType: nil)!
    public static let contact: UTType = UTType(identifier: "public.contact", mimeType: nil)!
    public static let vCard: UTType = UTType(identifier: "public.vcard", mimeType: "text/vcard")!
    public static let toDoItem: UTType = UTType(identifier: "public.to-do-item", mimeType: nil)!
    public static let calendarEvent: UTType = UTType(identifier: "public.calendar-event", mimeType: nil)!
    public static let emailMessage: UTType = UTType(identifier: "public.email-message", mimeType: nil)!
    public static let internetLocation: UTType = UTType(identifier: "com.apple.internet-location", mimeType: nil)!
    public static let internetShortcut: UTType = UTType(identifier: "com.microsoft.internet-shortcut", mimeType: nil)!
    public static let font: UTType = UTType(identifier: "public.font", mimeType: nil)!
    public static let bookmark: UTType = UTType(identifier: "public.bookmark", mimeType: nil)!
    public static let pkcs12: UTType = UTType(identifier: "com.rsa.pkcs-12", mimeType: "application/x-pkcs12")!
    public static let x509Certificate: UTType = UTType(identifier: "public.x509-certificate", mimeType: "application/x-x509-ca-cert")!
    public static let epub: UTType = UTType(identifier: "org.idpf.epub-container", mimeType: "application/epub+zip")!
    public static let log: UTType = UTType(identifier: "public.log", mimeType: nil)!
    public static let ahap: UTType = UTType(identifier: "com.apple.haptics.ahap", mimeType: nil)!
    public static let geoJSON: UTType = UTType(identifier: "public.geojson", mimeType: "application/geo+json")!
    public static let linkPresentationMetadata: UTType = UTType(identifier: "com.apple.linkpresentation.metadata", mimeType: nil)!
}

#endif
#endif
