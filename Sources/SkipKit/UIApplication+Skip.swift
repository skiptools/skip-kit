// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import SwiftUI

///// Provides general information for a Skip app.
//extension UIApplication {
//    // @SKIP @nobridge // FIXME: private let Java_UIApplication+SkipKt = try! JClass(name: "skip/kit/UIApplication+SkipKt")
//    public func appStoreListing(for store: StoreListing = StoreListing.auto) throws -> URL {
//        try _appStoreListing(for: store)
//    }
//}
//
//private func _appStoreListing(for store: StoreListing = StoreListing.auto) throws -> URL {
//    URL(string: "TODO")!
//}

// https://docs.expo.dev/versions/latest/sdk/storereview/

// Android:

//const androidPackageName = 'host.exp.exponent';
//// Open the Android Play Store in the browser -> redirects to Play Store on Android
//Linking.openURL(
//  `https://play.google.com/store/apps/details?id=${androidPackageName}&showAllReviews=true`
//);
//// Open the Android Play Store directly
//Linking.openURL(`market://details?id=${androidPackageName}&showAllReviews=true`);

// iOS:

//const itunesItemId = 982107779;
//// Open the iOS App Store in the browser -> redirects to App Store on iOS
//Linking.openURL(`https://apps.apple.com/app/apple-store/id${itunesItemId}?action=write-review`);
//// Open the iOS App Store directly
//Linking.openURL(
//  `itms-apps://itunes.apple.com/app/viewContentsUserReviews/id${itunesItemId}?action=write-review`
//);


//public class StoreListing {
//    internal init() {
//    }
//}
//
//public extension StoreListing {
//    static var auto: StoreListing {
//        #if SKIP
//        googlePlayStore
//        #else
//        appleAppStore
//        #endif
//    }
//
//    static var appleAppStore: StoreListing { AppleAppStoreListing() }
//    static var googlePlayStore: StoreListing { GooglePlayStoreListing() }
//}
//
//class AppleAppStoreListing : StoreListing {
//    override internal init() {
//        super.init()
//    }
//}
//
//class GooglePlayStoreListing : StoreListing {
//    override internal init() {
//    }
//}


#endif
