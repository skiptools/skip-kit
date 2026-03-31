// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation

#if SKIP
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import android.os.Build
#endif

/// Provides information about the currently running application.
///
/// Access via the `AppInfo.current` singleton. All properties are computed lazily
/// and cached for the lifetime of the process.
///
/// On iOS, this reads from `Bundle.main.infoDictionary` and system APIs.
/// On Android, this reads from `PackageManager`, `ApplicationInfo`, and `Build`.
public struct AppInfo {
    /// The shared instance for the currently running app.
    nonisolated(unsafe) public static let current = AppInfo()

    private init() { }

    // MARK: - Identity

    /// The bundle identifier (iOS) or package name (Android).
    ///
    /// Example: `"com.example.myapp"`
    public var appIdentifier: String? {
        _appIdentifier
    }

    /// The user-visible display name of the app.
    ///
    /// On iOS: `CFBundleDisplayName` or `CFBundleName`.
    /// On Android: The application label from `PackageManager`.
    public var displayName: String? {
        _displayName
    }

    // MARK: - Version

    /// The user-facing version string (e.g. `"1.2.3"`).
    ///
    /// On iOS: `CFBundleShortVersionString`.
    /// On Android: `versionName` from `PackageInfo`.
    public var version: String? {
        _version
    }

    /// The internal build number as a string (e.g. `"42"` or `"2024.03.15"`).
    ///
    /// On iOS: `CFBundleVersion`.
    /// On Android: `versionCode` from `PackageInfo` (as a string).
    public var buildNumber: String? {
        _buildNumber
    }

    /// The build number as an integer, if parseable.
    ///
    /// On iOS: `CFBundleVersion` parsed as Int.
    /// On Android: `versionCode`.
    public var buildNumberInt: Int? {
        _buildNumberInt
    }

    /// A combined "version (build)" string, e.g. `"1.2.3 (42)"`.
    public var versionWithBuild: String {
        let v = version ?? "0.0.0"
        if let b = buildNumber {
            return "\(v) (\(b))"
        }
        return v
    }

    // MARK: - Build Configuration

    /// Whether the app is running in a debug build.
    ///
    /// On iOS: Checks for the `DEBUG` preprocessor flag.
    /// On Android: Reads `ApplicationInfo.FLAG_DEBUGGABLE`.
    public var isDebug: Bool {
        _isDebug
    }

    /// Whether the app is running in a release build (the inverse of `isDebug`).
    public var isRelease: Bool {
        !isDebug
    }

    /// Whether the app was installed from TestFlight (iOS only).
    /// Returns `false` on Android.
    public var isTestFlight: Bool {
        _isTestFlight
    }

    // MARK: - Platform Info

    /// The operating system name (e.g. `"iOS"`, `"Android"`).
    public var osName: String {
        #if SKIP
        "Android"
        #elseif os(iOS)
        "iOS"
        #elseif os(macOS)
        "macOS"
        #elseif os(tvOS)
        "tvOS"
        #elseif os(watchOS)
        "watchOS"
        #else
        "Unknown"
        #endif
    }

    /// The operating system version string.
    ///
    /// On iOS/macOS: e.g. `"17.4.1"`.
    /// On Android: The SDK version string, e.g. `"14"` (API level 34).
    public var osVersion: String {
        _osVersion
    }

    /// The device model identifier.
    ///
    /// On iOS: e.g. `"iPhone15,2"`.
    /// On Android: e.g. `"Pixel 7"`.
    public var deviceModel: String {
        _deviceModel
    }

    // MARK: - App Bundle Info (iOS-specific, safe no-ops on Android)

    /// The minimum OS version required by the app.
    ///
    /// On iOS: `MinimumOSVersion` from Info.plist.
    /// On Android: `minSdkVersion` from `ApplicationInfo`.
    public var minimumOSVersion: String? {
        _minimumOSVersion
    }

    /// The app's URL scheme types (iOS only). Returns an empty array on Android.
    public var urlSchemes: [String] {
        _urlSchemes
    }

    /// All keys available in the iOS Info.plist. Returns an empty array on Android.
    public var infoDictionaryKeys: [String] {
        #if !SKIP
        return Array((Bundle.main.infoDictionary ?? [:]).keys)
        #else
        return []
        #endif
    }

    /// Access a raw Info.plist value by key (iOS) or returns `nil` on Android.
    public func infoDictionaryValue(forKey key: String) -> Any? {
        #if !SKIP
        return Bundle.main.infoDictionary?[key]
        #else
        return nil
        #endif
    }
}

// MARK: - Private Cached Values

#if SKIP
private let _pkgInfo: android.content.pm.PackageInfo = {
    let context = ProcessInfo.processInfo.androidContext
    return context.getPackageManager().getPackageInfo(context.getPackageName(), PackageManager.GET_META_DATA)
}()

private let _appInfo: ApplicationInfo = {
    let context = ProcessInfo.processInfo.androidContext
    return context.getApplicationInfo()
}()
#endif

private let _appIdentifier: String? = {
    #if !SKIP
    Bundle.main.bundleIdentifier
    #else
    ProcessInfo.processInfo.androidContext.getPackageName()
    #endif
}()

private let _displayName: String? = {
    #if !SKIP
    (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
        ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
    #else
    let context = ProcessInfo.processInfo.androidContext
    let pm = context.getPackageManager()
    let label = _appInfo.loadLabel(pm)
    return "\(label)"
    #endif
}()

private let _version: String? = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    #else
    _pkgInfo.versionName
    #endif
}()

private let _buildNumber: String? = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    #else
    "\(_pkgInfo.versionCode)"
    #endif
}()

private let _buildNumberInt: Int? = {
    #if !SKIP
    if let str = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return Int(str)
    }
    return nil
    #else
    Int(_pkgInfo.versionCode)
    #endif
}()

private let _isDebug: Bool = {
    #if !SKIP
    #if DEBUG
    return true
    #else
    return false
    #endif
    #else
    return (_appInfo.flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0
    #endif
}()

private let _isTestFlight: Bool = {
    #if !SKIP
    #if targetEnvironment(simulator)
    return false
    #else
    guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
    return receiptURL.lastPathComponent == "sandboxReceipt"
    #endif
    #else
    return false
    #endif
}()

private let _osVersion: String = {
    #if !SKIP
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    #else
    return "\(Build.VERSION.SDK_INT)"
    #endif
}()

private let _deviceModel: String = {
    #if !SKIP
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(validatingUTF8: $0) ?? "Unknown"
        }
    }
    #else
    return Build.MODEL
    #endif
}()

private let _minimumOSVersion: String? = {
    #if !SKIP
    return Bundle.main.infoDictionary?["MinimumOSVersion"] as? String
    #else
    return "\(_appInfo.minSdkVersion)"
    #endif
}()

private let _urlSchemes: [String] = {
    #if !SKIP
    guard let types = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
        return []
    }
    return types.compactMap { dict in
        (dict["CFBundleURLSchemes"] as? [String])?.first
    }
    #else
    return []
    #endif
}()

#endif
