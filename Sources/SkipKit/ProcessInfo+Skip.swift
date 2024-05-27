// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI

/// Provides general information for a Skip app.
public extension ProcessInfo {
    /// Returns the version of the app.
    ///
    /// On iOS, uses the `CFBundleShortVersionString` of the main `Bundle's Info.plist`
    ///
    /// On Android, uses the `versionName` property of the `android.content.pm.PackageManager`
    var appVersionString: String {
        _appVersionString
    }

    /// Returns the version of the app.
    ///
    /// On iOS, uses the `CFBundleVersion` of the main `Bundle's Info.plist`
    ///
    /// On Android, uses the `versionCode` property of the `android.content.pm.PackageManager`
    var appVersionNumber: Int {
        _appVersionNumber
    }
}

#if SKIP
private let packageInfo: android.content.pm.PackageInfo = {
    let context = ProcessInfo.processInfo.androidContext
    let packageManager = context.getPackageManager()
    return packageManager.getPackageInfo(context.getPackageName(), android.content.pm.PackageManager.GET_META_DATA)
}()
#endif

private let _appVersionString: String = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    #else
    packageInfo.versionName
    #endif
}()


private let _appVersionNumber: Int = {
    #if !SKIP
    Bundle.main.infoDictionary?["CFBundleVersion"] as? Int ?? 0
    #else
    packageInfo.versionCode
    #endif
}()

