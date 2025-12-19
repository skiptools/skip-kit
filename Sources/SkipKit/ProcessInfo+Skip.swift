// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation

/// Provides general information for a Skip app.
public extension ProcessInfo {
    /// Returns the version of the app.
    ///
    /// On iOS, uses the `CFBundleShortVersionString` of the main `Bundle's Info.plist`
    ///
    /// On Android, uses the `versionName` property of the `android.content.pm.PackageManager`
    var appVersionString: String? {
        _appVersionString
    }

    /// Returns the version of the app.
    ///
    /// On iOS, uses the `CFBundleVersion` of the main `Bundle's Info.plist`
    ///
    /// On Android, uses the `versionCode` property of the `android.content.pm.PackageManager`
    var appVersionNumber: Int? {
        _appVersionNumber
    }

    /// Returns the identifier of the app.
    ///
    /// On iOS, uses the `CFBundleIdentifier` of the main `Bundle's Info.plist`
    ///
    /// On Android, uses the `packageName` property of the `android.content.Context`
    var appIdentifier: String? {
        _appIdentifier
    }
}

#if SKIP
private let packageInfo: android.content.pm.PackageInfo = {
    let context = ProcessInfo.processInfo.androidContext
    let packageManager = context.getPackageManager()
    return packageManager.getPackageInfo(context.getPackageName(), android.content.pm.PackageManager.GET_META_DATA)
}()
#endif

private let _appVersionString: String? = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    #else
    packageInfo.versionName
    #endif
}()

private let _appVersionNumber: Int? = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleVersion"] as? Int
    #else
    packageInfo.versionCode
    #endif
}()

private let _appIdentifier: String? = {
    #if !SKIP
    (Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String)
    #else
    ProcessInfo.processInfo.androidContext.getPackageName()
    #endif
}()

#endif

