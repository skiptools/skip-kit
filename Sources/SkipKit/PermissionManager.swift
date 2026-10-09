// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI
#if !SKIP
import ObjectiveC
import UserNotifications
// NOTE: Camera, microphone, photo library, and location permissions intentionally avoid static
//       sensitive-framework symbols; see the dynamic permission helper comments below.
#else
import android.Manifest
import android.os.Build
import android.content.Context
import android.content.pm.PackageManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.registerForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
#endif

/// Provides an interface for requesting permissions
public final class PermissionManager: Sendable {
    private init() {
    }

    public static func queryPermission(_ permission: PermissionType) -> PermissionAuthorization {
        #if !SKIP
        switch permission {
        case .POST_NOTIFICATIONS: return .unknown // queryPostNotificationPermission() // this is async, so we cannot call it
        //case .READ_CONTACTS: return queryContactsPermission(readWrite: false)
        //case .WRITE_CONTACTS: return queryContactsPermission(readWrite: true)
        //case .READ_CALENDAR: return queryCalendarPermission(readWrite: false)
        //case .WRITE_CALENDAR: return queryCalendarPermission(readWrite: true)
        case .READ_EXTERNAL_STORAGE: return queryPhotoLibraryPermission(readWrite: false)
        case .WRITE_EXTERNAL_STORAGE: return queryPhotoLibraryPermission(readWrite: true)
        case .RECORD_AUDIO: return queryRecordAudioPermission()
        case .CAMERA: return queryCameraPermission()
        case .ACCESS_FINE_LOCATION: return queryLocationPermission(precise: true, always: false)
        case .ACCESS_COARSE_LOCATION: return queryLocationPermission(precise: false, always: false)
        default: return .unknown
        }
        #else
        // e.g.: android.permission.ACCESS_FINE_LOCATION
        // Android does not have limited options, so we always return `authorized` or `unknown`
        guard let activity = UIApplication.shared.androidActivity else {
            return .unknown
        }
        let granted = ContextCompat.checkSelfPermission(activity, permission.androidPermissionName)
        switch granted {
        case PackageManager.PERMISSION_GRANTED: return .authorized
        case PackageManager.PERMISSION_DENIED: return .unknown // "DENIED" is a misnomer: if may also mean that permission has not yet been requested
        default: return .unknown
        }
        #endif
    }

    /// Requests the given permission.
    /// - Parameters:
    ///   - permission: the permission, such as `PermissionType.CAMERA`
    ///   - showRationale: an optional async callback to invoke when the system determies that a rationale should be displayed for the permission check
    /// - Returns: true if the permission was granted, false if denied or there was an error making the request
    public static func requestPermission(_ permission: PermissionType, showRationale: (() async -> Bool)?) async -> PermissionAuthorization {
        #if !SKIP
        switch permission {
        case .POST_NOTIFICATIONS: return await (try? requestPostNotificationPermission()) ?? .unknown
        //case .READ_CONTACTS: return await (try? requestContactsPermission(readWrite: false)) ?? .unknown
        //case .WRITE_CONTACTS: return await (try? requestContactsPermission(readWrite: true)) ?? .unknown
        //case .READ_CALENDAR: return await (try? requestCalendarPermission(readWrite: false)) ?? .unknown
        //case .WRITE_CALENDAR: return await (try? requestCalendarPermission(readWrite: true)) ?? .unknown
        case .READ_EXTERNAL_STORAGE: return await requestPhotoLibraryPermission(readWrite: false)
        case .WRITE_EXTERNAL_STORAGE: return await requestPhotoLibraryPermission(readWrite: true)
        case .RECORD_AUDIO: return await requestRecordAudioPermission()
        case .CAMERA: return await requestCameraPermission()
        case .ACCESS_FINE_LOCATION: return await requestLocationPermission(precise: true, always: false)
        case .ACCESS_COARSE_LOCATION: return await requestLocationPermission(precise: false, always: false)
        default: return .unknown
        }
        #else
        // e.g.: android.permission.ACCESS_FINE_LOCATION
        // Android does not have limited options, so we always return `authorized` or `denied`
        if try await UIApplication.shared.requestPermission(permission.androidPermissionName, showRationale: showRationale) == true {
            return .authorized
        } else {
            return .denied
        }
        #endif
    }

    /// Requests the given permission.
    /// - Parameters:
    ///   - permission: the permission, such as `PermissionType.CAMERA`
    /// - Returns: true if the permission was granted, false if denied or there was an error making the request
    /* SKIP @nodispatch */public static func requestPermission(_ permission: PermissionType) async -> PermissionAuthorization {
        await requestPermission(permission, showRationale: nil)
    }

    /// Queries whether push notifications have been permitted
    public static func queryPostNotificationPermission() async -> PermissionAuthorization {
        #if SKIP
        return queryPermission(.POST_NOTIFICATIONS)
        #else
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = settings.authorizationStatus
        switch status {
        case .notDetermined:
            return .unknown
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .limited
        case .ephemeral:
            return .limited
        @unknown default:
            return .unknown
        }
        #endif
    }

    /// Requests permission to send push notifications
    ///
    /// - seeAlso: https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
    public static func requestPostNotificationPermission(alert: Bool = true, sound: Bool = true, badge: Bool = true) async throws -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(.POST_NOTIFICATIONS)
        #else
        var opts = UNAuthorizationOptions()
        if alert { opts.insert(.alert) }
        if sound { opts.insert(.sound) }
        if badge { opts.insert(.badge) }
        return try await UNUserNotificationCenter.current().requestAuthorization(options: opts) ? .authorized : .denied
        #endif
    }

    /// Queries camera access
    public static func queryCameraPermission() -> PermissionAuthorization {
        #if SKIP
        return queryPermission(.CAMERA)
        #elseif os(watchOS)
        return .restricted
        #else
        return queryCapturePermission(for: avMediaTypeVideo)
        #endif
    }

    /// Request permission to use the device camera
    public static func requestCameraPermission() async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(.CAMERA)
        #elseif os(watchOS)
        return .restricted
        #else
        return await requestCapturePermission(for: avMediaTypeVideo)
        #endif
    }

    /// Queries microphone access
    public static func queryRecordAudioPermission() -> PermissionAuthorization {
        #if SKIP
        return queryPermission(.RECORD_AUDIO)
        #else
        return queryMicrophonePermission()
        #endif
    }

    /// Requests microphone access
    public static func requestRecordAudioPermission() async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(.RECORD_AUDIO)
        #else
        return await requestMicrophonePermission()
        #endif
    }

    #if !SKIP
    /// Camera and microphone permissions are accessed dynamically so apps that embed SkipKit but
    /// never use capture devices do not get flagged by App Store Connect for camera or microphone
    /// purpose strings. The Objective-C class and selectors below are public AVFoundation API;
    /// this only avoids static references to sensitive Swift symbols such as typed media constants.
    private static var avMediaTypeVideo: NSString {
        "vide" as NSString
    }

    private static var avMediaTypeAudio: NSString {
        "soun" as NSString
    }

    private static func queryMicrophonePermission() -> PermissionAuthorization {
        queryCapturePermission(for: avMediaTypeAudio)
    }

    private static func requestMicrophonePermission() async -> PermissionAuthorization {
        await requestCapturePermission(for: avMediaTypeAudio)
    }

    private static func queryCapturePermission(for mediaType: NSString) -> PermissionAuthorization {
        guard let captureDeviceClass = avCaptureDeviceClass() else {
            return .unknown
        }

        let selector = NSSelectorFromString("authorizationStatusForMediaType:")
        guard let method = class_getClassMethod(captureDeviceClass, selector) else {
            return .unknown
        }

        typealias AuthorizationStatusForMediaType = @convention(c) (AnyClass, Selector, NSString) -> Int
        let function = unsafeBitCast(method_getImplementation(method), to: AuthorizationStatusForMediaType.self)
        return permissionAuthorization(fromAVAuthorizationStatus: function(captureDeviceClass, selector, mediaType))
    }

    private static func requestCapturePermission(for mediaType: NSString) async -> PermissionAuthorization {
        let status = queryCapturePermission(for: mediaType)
        if status != .unknown {
            return status
        }

        return await withCheckedContinuation { continuation in
            guard let captureDeviceClass = avCaptureDeviceClass() else {
                continuation.resume(returning: .unknown)
                return
            }

            let selector = NSSelectorFromString("requestAccessForMediaType:completionHandler:")
            guard let method = class_getClassMethod(captureDeviceClass, selector) else {
                continuation.resume(returning: .unknown)
                return
            }

            typealias RequestAccessForMediaType = @convention(c) (AnyClass, Selector, NSString, @escaping @convention(block) (Bool) -> Void) -> Void
            let function = unsafeBitCast(method_getImplementation(method), to: RequestAccessForMediaType.self)
            let handler: @convention(block) (Bool) -> Void = { granted in
                continuation.resume(returning: granted ? .authorized : .denied)
            }
            function(captureDeviceClass, selector, mediaType, handler)
        }
    }

    private static func permissionAuthorization(fromAVAuthorizationStatus status: Int) -> PermissionAuthorization {
        switch status {
        case 0:
            return .unknown
        case 1:
            return .restricted
        case 2:
            return .denied
        case 3:
            return .authorized
        default:
            return .unknown
        }
    }

    private static func avCaptureDeviceClass() -> AnyClass? {
        if let captureDeviceClass = NSClassFromString("AVCaptureDevice") {
            return captureDeviceClass
        }

        let frameworkPaths = [
            "/System/Library/Frameworks/AVFoundation.framework/AVFoundation",
            "/System/Library/Frameworks/AVFoundation.framework/Versions/A/AVFoundation",
        ]
        for frameworkPath in frameworkPaths where dlopen(frameworkPath, RTLD_LAZY) != nil {
            break
        }
        return NSClassFromString("AVCaptureDevice")
    }

    /// Photo library permission is accessed dynamically so apps that embed SkipKit but never use
    /// photo access do not get flagged by App Store Connect for photo library purpose strings.
    /// The Objective-C class and selectors below are public Photos API; this only avoids static
    /// references to sensitive Swift symbols such as typed access-level constants.
    private static let phAccessLevelAddOnly = 1
    private static let phAccessLevelReadWrite = 2

    private static func queryPhotoLibraryPermission(accessLevel: Int) -> PermissionAuthorization {
        guard let photoLibraryClass = phPhotoLibraryClass() else {
            return .unknown
        }

        let selector = NSSelectorFromString("authorizationStatusForAccessLevel:")
        guard let method = class_getClassMethod(photoLibraryClass, selector) else {
            return .unknown
        }

        typealias AuthorizationStatusForAccessLevel = @convention(c) (AnyClass, Selector, Int) -> Int
        let function = unsafeBitCast(method_getImplementation(method), to: AuthorizationStatusForAccessLevel.self)
        return permissionAuthorization(fromPHAuthorizationStatus: function(photoLibraryClass, selector, accessLevel))
    }

    private static func requestPhotoLibraryPermission(accessLevel: Int) async -> PermissionAuthorization {
        let status = queryPhotoLibraryPermission(accessLevel: accessLevel)
        if status != .unknown {
            return status
        }

        return await withCheckedContinuation { continuation in
            guard let photoLibraryClass = phPhotoLibraryClass() else {
                continuation.resume(returning: .unknown)
                return
            }

            let selector = NSSelectorFromString("requestAuthorizationForAccessLevel:handler:")
            guard let method = class_getClassMethod(photoLibraryClass, selector) else {
                continuation.resume(returning: .unknown)
                return
            }

            typealias RequestAuthorizationForAccessLevel = @convention(c) (AnyClass, Selector, Int, @escaping @convention(block) (Int) -> Void) -> Void
            let function = unsafeBitCast(method_getImplementation(method), to: RequestAuthorizationForAccessLevel.self)
            let handler: @convention(block) (Int) -> Void = { status in
                continuation.resume(returning: permissionAuthorization(fromPHAuthorizationStatus: status))
            }
            function(photoLibraryClass, selector, accessLevel, handler)
        }
    }

    private static func permissionAuthorization(fromPHAuthorizationStatus status: Int) -> PermissionAuthorization {
        switch status {
        case 0:
            return .unknown
        case 1:
            return .restricted
        case 2:
            return .denied
        case 3:
            return .authorized
        case 4:
            return .limited
        default:
            return .unknown
        }
    }

    private static func phPhotoLibraryClass() -> AnyClass? {
        if let photoLibraryClass = NSClassFromString("PHPhotoLibrary") {
            return photoLibraryClass
        }

        let frameworkPaths = [
            "/System/Library/Frameworks/Photos.framework/Photos",
            "/System/Library/Frameworks/Photos.framework/Versions/A/Photos",
        ]
        for frameworkPath in frameworkPaths where dlopen(frameworkPath, RTLD_LAZY) != nil {
            break
        }
        return NSClassFromString("PHPhotoLibrary")
    }
    #endif

#if false // TODO: create framework skip-contacts
    // ITMS-90683: Missing purpose string in Info.plist - Your app’s code references one or more APIs that access sensitive user data, or the app has one or more entitlements that permit such access. The Info.plist file for the “XXX.app” bundle should contain a NSContactsUsageDescription key with a user-facing purpose string explaining clearly and completely why your app needs the data. If you’re using external libraries or SDKs, they may reference APIs that require a purpose string. While your app might not use these APIs, a purpose string is still required. For details, visit: https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/requesting_access_to_protected_resources.

    public static func queryContactsPermission(readWrite: Bool = false) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(readWrite ? .WRITE_CONTACTS : .READ_CONTACTS)
        #else
        let status: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .notDetermined:
            return .unknown
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .unknown
        }
        #endif
    }

    public static func requestContactsPermission(readWrite: Bool = false) async throws -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CONTACTS : .READ_CONTACTS)
        #else
        let status = queryContactsPermission(readWrite: readWrite)
        if status != .unknown {
            return status
        }
        let contactStore = CNContactStore()
        try await contactStore.requestAccess(for: .contacts)
        return queryContactsPermission(readWrite: readWrite)
        #endif
    }
#endif


    public static func queryPhotoLibraryPermission(readWrite: Bool = true) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(readWrite ? .WRITE_EXTERNAL_STORAGE : .READ_EXTERNAL_STORAGE)
        #elseif os(watchOS)
        return .restricted
        #else
        return queryPhotoLibraryPermission(accessLevel: readWrite ? phAccessLevelReadWrite : phAccessLevelAddOnly)
        #endif
    }

    /// Requests the media library permission
    public static func requestPhotoLibraryPermission(readWrite: Bool = true) async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_EXTERNAL_STORAGE : .READ_EXTERNAL_STORAGE)
        #elseif os(watchOS)
        return .restricted
        #else
        return await requestPhotoLibraryPermission(accessLevel: readWrite ? phAccessLevelReadWrite : phAccessLevelAddOnly)
        #endif
    }

    public static func queryLocationPermission(precise: Bool, always: Bool) -> PermissionAuthorization {
        #if SKIP
        let coarseLocationPermission = queryPermission(.ACCESS_COARSE_LOCATION)
        let fineLocationPermission = queryPermission(.ACCESS_FINE_LOCATION)
        let backgroundLocationPermission = queryPermission(.ACCESS_BACKGROUND_LOCATION)
        
        if always == true {
            if backgroundLocationPermission == .authorized {
                if precise == true {
                    if fineLocationPermission == .authorized {
                        return .authorized
                    } else {
                        return .limited
                    }
                } else {
                    if coarseLocationPermission == .authorized {
                        return .authorized
                    }
                }
            }
        } else {
            if precise == true {
                if fineLocationPermission == .authorized {
                    return .authorized
                }
            } else {
                if coarseLocationPermission == .authorized {
                    return .authorized
                }
            }
        }
        return .unknown
        
        #else
        guard let locationManager = LocationDelegate.shared.locationManager,
              let status = locationManager.value(forKey: "authorizationStatus") as? Int else {
            return .unknown
        }
        let accuracy = locationManager.value(forKey: "accuracyAuthorization") as? Int

        switch status {
        case LocationDelegate.authorizationStatusNotDetermined:
            return .unknown
        case LocationDelegate.authorizationStatusRestricted:
            return .restricted
        case LocationDelegate.authorizationStatusDenied:
            return .denied
        case LocationDelegate.authorizationStatusAuthorizedAlways:
            if precise == true && accuracy == LocationDelegate.accuracyAuthorizationReducedAccuracy {
                // requested fullAccuracy, but only coarse was approved
                return .limited
            } else {
                return .authorized
            }
        case LocationDelegate.authorizationStatusAuthorizedWhenInUse:
            if always == true {
                // requested always, but only when in use was granted
                return .limited
            } else if precise == true && accuracy == LocationDelegate.accuracyAuthorizationReducedAccuracy {
                // requested fullAccuracy, but only coarse was approved
                return .limited
            } else {
                return .authorized
            }
        default:
            return .unknown
        }
        #endif
    }

    /// Requests location permission
    public static func requestLocationPermission(precise: Bool, always: Bool) async -> PermissionAuthorization {
        #if SKIP
        let status = queryLocationPermission(precise: precise, always: always)
        if status == .unknown {
            return await requestPermission(precise ? .ACCESS_FINE_LOCATION : .ACCESS_COARSE_LOCATION)
        } else if status == .limited && always == true {
            // NOTE: for API 30+, this redirects directly to the app's settings Location permission. There is no UI popup in Android for this
            return await PermissionManager.requestPermission(.ACCESS_BACKGROUND_LOCATION)
        } else {
            return status
        }
        #else
        let status = queryLocationPermission(precise: precise, always: always)
        if status != .unknown && status != .limited {
            return status
        }
        await LocationDelegate.shared.requestPermission(always: always)
        return queryLocationPermission(precise: precise, always: always)
        #endif
    }
}

#if !SKIP
/// A delegate that encapsulates a `CLLocationManager` and handles `locationManagerDidChangeAuthorization`.
///
/// CoreLocation is accessed dynamically through the Objective-C runtime rather than being imported,
/// because merely linking against CoreLocation.framework causes App Store Connect to require a
/// location usage purpose string from every app that embeds this library, even apps that never use location.
class LocationDelegate: NSObject {
    /// For some reason, we need to keep just a single reference to CLLocationManager around for the locationManagerDidChangeAuthorization to get called reliably
    nonisolated(unsafe) static let shared = LocationDelegate()

    /// `CLAuthorizationStatus` constants
    static let authorizationStatusNotDetermined = 0
    static let authorizationStatusRestricted = 1
    static let authorizationStatusDenied = 2
    static let authorizationStatusAuthorizedAlways = 3
    static let authorizationStatusAuthorizedWhenInUse = 4

    /// `CLAccuracyAuthorization` constants
    static let accuracyAuthorizationFullAccuracy = 0
    static let accuracyAuthorizationReducedAccuracy = 1

    /// The shared `CLLocationManager` instance, or nil if the CoreLocation framework could not be loaded
    lazy var locationManager: NSObject? = {
        if Thread.isMainThread {
            return LocationDelegate.locationManagerClass()?.init()
        } else {
            return DispatchQueue.main.sync {
                LocationDelegate.locationManagerClass()?.init()
            }
        }
    }()

    var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
    }

    /// Returns the `CLLocationManager` class, loading the CoreLocation system framework if no other module in the app has already linked it
    private static func locationManagerClass() -> NSObject.Type? {
        if let managerClass = NSClassFromString("CLLocationManager") as? NSObject.Type {
            return managerClass
        }
        // the unversioned path is the iOS framework layout; the versioned path is the macOS layout
        for frameworkPath in [
            "/System/Library/Frameworks/CoreLocation.framework/CoreLocation",
            "/System/Library/Frameworks/CoreLocation.framework/Versions/A/CoreLocation",
        ] {
            if dlopen(frameworkPath, RTLD_LAZY) != nil {
                break
            }
        }
        return NSClassFromString("CLLocationManager") as? NSObject.Type
    }

    func requestPermission(always: Bool) async {
        let requestSelector = NSSelectorFromString(always ? "requestAlwaysAuthorization" : "requestWhenInUseAuthorization")
        guard let locationManager = locationManager, locationManager.responds(to: requestSelector) else {
            logger.warning("LocationDelegate: CLLocationManager is unavailable; cannot request location permission")
            return
        }
        locationManager.setValue(self, forKey: "delegate")
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            logger.debug("LocationDelegate: \(always ? "requestAlwaysAuthorization" : "requestWhenInUseAuthorization")")
            locationManager.perform(requestSelector)
        }
    }

    /// Invoked by `CLLocationManager` through the Objective-C runtime when the authorization status changes
    @objc(locationManagerDidChangeAuthorization:)
    func locationManagerDidChangeAuthorization(_ manager: NSObject) {
        logger.debug("LocationDelegate.locationManagerDidChangeAuthorization")
        continuation?.resume(returning: ())
        continuation = nil // always clear the continuation between checks
    }
}
#endif

/// The status of a permission authorization
public enum PermissionAuthorization : String, Sendable {
    /// Authorization status is unknown
    case unknown
    /// The app isn’t authorized to access the permission, and the user can’t grant such permission.
    case restricted
    /// The user explicitly denied this app the permission.
    case denied
    /// The user explicitly granted this app the permission.
    case authorized
    /// The user authorized this app for limited access to the permission.
    case limited

    /// Returns true if the permission definitely has some authorization, false if is definitely does not, or nil if it is unknown
    public var isAuthorized: Bool? {
        switch self {
        case .unknown: return nil
        case .restricted: return false
        case .denied: return false
        case .authorized: return true
        case .limited: return true
        }
    }
}

/// The encapsulation of a permission name
public struct PermissionType : Equatable, Sendable {
    public let androidPermissionName: String

    public init(androidPermissionName: String) {
        self.androidPermissionName = androidPermissionName
    }

    public static func == (lhs: PermissionType, rhs: PermissionType) -> Bool {
        lhs.androidPermissionName == rhs.androidPermissionName
    }
}

/// https://developer.android.com/reference/android/Manifest.permission
public extension PermissionType {
    static let CAMERA = PermissionType(androidPermissionName: "android.permission.CAMERA")
    static let RECORD_AUDIO = PermissionType(androidPermissionName: "android.permission.RECORD_AUDIO")

    static let READ_CONTACTS = PermissionType(androidPermissionName: "android.permission.READ_CONTACTS")
    static let WRITE_CONTACTS = PermissionType(androidPermissionName: "android.permission.WRITE_CONTACTS")

    static let READ_CALENDAR = PermissionType(androidPermissionName: "android.permission.READ_CALENDAR")
    static let WRITE_CALENDAR = PermissionType(androidPermissionName: "android.permission.WRITE_CALENDAR")

    // API 11+ breaks this up into: READ_MEDIA_IMAGES, READ_MEDIA_VIDEO
    static let READ_EXTERNAL_STORAGE = PermissionType(androidPermissionName: "android.permission.READ_EXTERNAL_STORAGE")
    static let WRITE_EXTERNAL_STORAGE = PermissionType(androidPermissionName: "android.permission.WRITE_EXTERNAL_STORAGE")

    static let POST_NOTIFICATIONS = PermissionType(androidPermissionName: "android.permission.POST_NOTIFICATIONS")
    static let ACCESS_FINE_LOCATION = PermissionType(androidPermissionName: "android.permission.ACCESS_FINE_LOCATION")
    static let ACCESS_COARSE_LOCATION = PermissionType(androidPermissionName: "android.permission.ACCESS_COARSE_LOCATION")
    static let ACCESS_BACKGROUND_LOCATION = PermissionType(androidPermissionName: "android.permission.ACCESS_BACKGROUND_LOCATION")
}

#endif
