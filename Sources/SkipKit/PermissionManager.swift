// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
#if !SKIP_BRIDGE
import Foundation
import SwiftUI
#if !SKIP
import Photos
import Contacts
import EventKit
import AVFoundation
import CoreLocation
import UserNotifications
import SystemConfiguration
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
public class PermissionManager {
    private init() {
    }

    public static func queryPermission(_ permission: PermissionType) -> PermissionAuthorization {
        #if !SKIP
        switch permission {
        case .POST_NOTIFICATIONS: return .unknown // queryPostNotificationPermission() // this is async, so we cannot call it
        case .READ_CONTACTS: return queryContactsPermission(readWrite: false)
        case .WRITE_CONTACTS: return queryContactsPermission(readWrite: true)
        case .READ_CALENDAR: return queryCalendarPermission(readWrite: false)
        case .WRITE_CALENDAR: return queryCalendarPermission(readWrite: true)
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
    public static func requestPermission(_ permission: PermissionType, showRationale: (() async -> Bool)? = nil) async -> PermissionAuthorization {
        #if !SKIP
        switch permission {
        case .POST_NOTIFICATIONS: return await (try? requestPostNotificationPermission()) ?? .unknown
        case .READ_CONTACTS: return await (try? requestContactsPermission(readWrite: false)) ?? .unknown
        case .WRITE_CONTACTS: return await (try? requestContactsPermission(readWrite: true)) ?? .unknown
        case .READ_CALENDAR: return await (try? requestCalendarPermission(readWrite: false)) ?? .unknown
        case .WRITE_CALENDAR: return await (try? requestCalendarPermission(readWrite: true)) ?? .unknown
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
        #else
        return queryAVPermission(for: .video)
        #endif
    }

    /// Request permission to use the device camera
    public static func requestCameraPermission() async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(.CAMERA)
        #else
        return await requestAVPermission(for: .video)
        #endif
    }

    /// Queries microphone access
    public static func queryRecordAudioPermission() -> PermissionAuthorization {
        #if SKIP
        return queryPermission(.RECORD_AUDIO)
        #else
        return queryAVPermission(for: .audio)
        #endif
    }

    /// Requests microphone access
    public static func requestRecordAudioPermission() async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(.RECORD_AUDIO)
        #else
        return await requestAVPermission(for: .audio)
        #endif
    }

    #if !SKIP
    private static func queryAVPermission(for mediaType: AVMediaType) -> PermissionAuthorization {
        let status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch status {
        case .notDetermined:
            return .unknown
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .unknown
        }
    }

    private static func requestAVPermission(for mediaType: AVMediaType) async -> PermissionAuthorization {
        let status = queryAVPermission(for: mediaType)
        if status != .unknown {
            return status
        }
        await AVCaptureDevice.requestAccess(for: mediaType)
        return queryAVPermission(for: mediaType)
    }
    #endif

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

    public static func queryCalendarPermission(readWrite: Bool = false) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return queryEventKitPermission(for: .event)
        #endif
    }

    public static func requestCalendarPermission(readWrite: Bool = false) async throws -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return try await requestEventKitPermission(for: .event)
        #endif
    }

    public static func queryReminderPermission(readWrite: Bool = false) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return queryEventKitPermission(for: .reminder)
        #endif
    }

    public static func requestReminderPermission(readWrite: Bool = false) async throws -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return try await requestEventKitPermission(for: .reminder)
        #endif
    }

    #if !SKIP
    private static func queryEventKitPermission(for eventType: EKEntityType) -> PermissionAuthorization {
        let status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: eventType)
        switch status {
        case .notDetermined:
            return .unknown
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized, .fullAccess, .writeOnly:
            return .authorized
        @unknown default:
            return .unknown
        }
    }

    private static func requestEventKitPermission(for eventType: EKEntityType) async throws -> PermissionAuthorization {
        let status = queryEventKitPermission(for: eventType)
        if status != .unknown {
            return status
        }
        let eventStore = EKEventStore()
        if #available(iOS 17.0, macOS 14.0, *) {
            // On iOS 17 and later, this method doesn’t prompt for access and immediately calls the completion block with an error.
            switch eventType {
            case .event:
                try await eventStore.requestFullAccessToEvents()
            case .reminder:
                try await eventStore.requestFullAccessToReminders()
            @unknown default:
                break // nothing else to do…
            }
        } else {
            try await eventStore.requestAccess(to: eventType)
        }
        return queryEventKitPermission(for: eventType)
    }
    #endif

    public static func queryPhotoLibraryPermission(readWrite: Bool = true) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(readWrite ? .WRITE_EXTERNAL_STORAGE : .READ_EXTERNAL_STORAGE)
        #else
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: readWrite ? .readWrite : .addOnly)

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

    /// Requests the media library permission
    public static func requestPhotoLibraryPermission(readWrite: Bool = true) async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_EXTERNAL_STORAGE : .READ_EXTERNAL_STORAGE)
        #else
        let status = queryPhotoLibraryPermission(readWrite: readWrite)
        if status != .unknown {
            return status
        }
        await PHPhotoLibrary.requestAuthorization(for: readWrite ? .readWrite : .addOnly)
        return queryPhotoLibraryPermission(readWrite: readWrite)
        #endif
    }

    public static func queryLocationPermission(precise: Bool, always: Bool) -> PermissionAuthorization {
        #if SKIP
        return queryPermission(precise ? .ACCESS_FINE_LOCATION : .ACCESS_COARSE_LOCATION)
        #else
        let locationManager = LocationDelegate.shared.locationManager
        let status = locationManager.authorizationStatus
        let accuracy = locationManager.accuracyAuthorization

        switch status {
        case .notDetermined:
            return .unknown
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            if precise == true && accuracy == .reducedAccuracy {
                // requested fullAccuracy, but only course was approved
                return .limited
            } else {
                return .authorized
            }
        case .authorizedWhenInUse:
            if always == true {
                // requested always, but only when in use was granted
                return .limited
            } else if precise == true && accuracy == .reducedAccuracy {
                // requested fullAccuracy, but only course was approved
                return .limited
            } else {
                return .authorized
            }
        @unknown default:
            return .unknown
        }
        #endif
    }

    /// Requests the media library permission
    public static func requestLocationPermission(precise: Bool, always: Bool) async -> PermissionAuthorization {
        #if SKIP
        return await requestPermission(precise ? .ACCESS_FINE_LOCATION : .ACCESS_COARSE_LOCATION)
        #else
        let status = queryLocationPermission(precise: precise, always: always)
        if status != .unknown {
            return status
        }
        await LocationDelegate.shared.requestPermission(always: always)
        return queryLocationPermission(precise: precise, always: always)
        #endif
    }
}

#if !SKIP
/// A delegate that encapsulates a `CLLocationManager` and handles `locationManagerDidChangeAuthorization`
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    /// For some reason, we need to keep just a single reference to CLLocationManager around for the locationManagerDidChangeAuthorization to get called reliably
    static let shared = LocationDelegate()

    lazy var locationManager = CLLocationManager()
    var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
    }

    func requestPermission(always: Bool) async {
        locationManager.delegate = self
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            if always {
                logger.debug("LocationDelegate: requestAlwaysAuthorization")
                locationManager.requestAlwaysAuthorization()
            } else {
                logger.debug("LocationDelegate: requestWhenInUseAuthorization")
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logger.debug("LocationDelegate.locationManagerDidChangeAuthorization")
        continuation?.resume(returning: ())
        continuation = nil // always clear the continuation between checks
    }
}
#endif

/// The status of a permission authorization
public enum PermissionAuthorization : String {
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
public struct PermissionType : Equatable {
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
}

#endif
