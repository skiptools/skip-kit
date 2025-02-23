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
import UserNotifications
import SystemConfiguration
#else
import android.Manifest
import android.os.Build
import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.registerForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
#endif

/// Provides an interface for requesting permissions
public class PermissionManager {
    public static let shared = PermissionManager()

    private init() {
    }

    /// Requests the given permission.
    /// - Parameters:
    ///   - permission: the permission, such as `PermissionType.CAMERA`
    ///   - showRationale: an optional async callback to invoke when the system determies that a rationale should be displayed for the permission check
    /// - Returns: true if the permission was granted, false if denied or there was an error making the request
    public static func requestPermission(_ permission: PermissionType, showRationale: (() async -> Bool)? = nil) async -> Bool {
        #if !SKIP
        switch permission {
        case .POST_NOTIFICATIONS: return await (try? requestPostNotificationPermission()) == true
        case .READ_CONTACTS: return await (try? requestContactsPermission(readWrite: false)) == true
        case .WRITE_CONTACTS: return await (try? requestContactsPermission(readWrite: true)) == true
        case .READ_CALENDAR: return await (try? requestCalendarPermission(readWrite: false)) == true
        case .WRITE_CALENDAR: return await (try? requestCalendarPermission(readWrite: true)) == true
        case .READ_EXTERNAL_STORAGE: return await requestPhotoLibraryPermission(readWrite: false) == true
        case .WRITE_EXTERNAL_STORAGE: return await requestPhotoLibraryPermission(readWrite: true) == true
        case .RECORD_AUDIO: return await requestRecordAudioPermission() == true
        case .CAMERA: return await requestCameraPermission() == true
        default: return true
        }
        #else
        // e.g.: android.permission.ACCESS_FINE_LOCATION
        try await UIApplication.shared.requestPermission(permission.androidPermissionName, showRationale: showRationale)
        #endif
    }

    /// Requests permission to send push notifications
    public static func requestPostNotificationPermission(alert: Bool = true, sound: Bool = true, badge: Bool = true) async throws -> Bool {
        #if SKIP
        return await requestPermission(.POST_NOTIFICATIONS)
        #else
        var opts = UNAuthorizationOptions()
        if alert { opts.insert(.alert) }
        if sound { opts.insert(.sound) }
        if badge { opts.insert(.badge) }
        return try await UNUserNotificationCenter.current().requestAuthorization(options: opts)
        #endif
    }

    /// Request permission to use the device camera
    public static func requestCameraPermission() async -> Bool {
        #if SKIP
        return await requestPermission(.CAMERA)
        #else
        return await requestAVPermission(for: .video)
        #endif
    }

    /// Requests microphone access
    public static func requestRecordAudioPermission() async -> Bool {
        #if SKIP
        return await requestPermission(.RECORD_AUDIO)
        #else
        return await requestAVPermission(for: .audio)
        #endif
    }

    #if !SKIP
    private static func requestAVPermission(for mediaType: AVMediaType) async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: mediaType)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    #endif

    public static func requestContactsPermission(readWrite: Bool = false) async throws -> Bool {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CONTACTS : .READ_CONTACTS)
        #else
        let contactStore = CNContactStore()
        let contactAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

        if contactAuthorizationStatus == .notDetermined {
            return try await contactStore.requestAccess(for: .contacts)
        } else if contactAuthorizationStatus == .denied {
            return false
        }
        return true
        #endif
    }

    public static func requestCalendarPermission(readWrite: Bool = false) async throws -> Bool {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return try await requestEventKitPermission(for: .event)
        #endif
    }

    public static func requestReminderPermission(readWrite: Bool = false) async throws -> Bool {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_CALENDAR : .READ_CALENDAR)
        #else
        return try await requestEventKitPermission(for: .reminder)
        #endif
    }

    #if !SKIP
    private static func requestEventKitPermission(for eventType: EKEntityType) async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: eventType)
        switch status {
        case .notDetermined:
            let eventStore = EKEventStore()
            return try await eventStore.requestAccess(to: eventType)
        case .authorized:
            return true
        case .denied:
            return false
        default:
            return true // e.g. restricted
        }
    }
    #endif

    /// Requests the media library permission
    public static func requestPhotoLibraryPermission(readWrite: Bool = true) async -> Bool {
        #if SKIP
        return await requestPermission(readWrite ? .WRITE_EXTERNAL_STORAGE : .READ_EXTERNAL_STORAGE)
        #else
        switch PHPhotoLibrary.authorizationStatus(for: readWrite ? .readWrite : .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: readWrite ? .readWrite : .addOnly)
            return status == .authorized || status == .limited
        default:
            return false
        }
        #endif
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
