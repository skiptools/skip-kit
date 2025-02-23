// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
#if !SKIP_BRIDGE
import Foundation
import SwiftUI
#if !SKIP
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

    /// Requests the given permission type
    public static func requestPermission(_ permissionName: String) async -> Bool {
        #if !SKIP
        return await withCheckedContinuation { continuation in
            // TODO: iOS side
//            self.callback = { result in
//                switch result {
//                case .success(let location):
//                    continuation.resume(returning: location)
//                    self.callback = nil
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                    self.callback = nil
//                }
//            }
//            requestLocationOrAuthorization()

            continuation.resume(returning: true)
        }
        #else
        // e.g.: android.permission.ACCESS_FINE_LOCATION
        try await UIApplication.shared.requestPermission("android.permission." + permissionName)
        #endif
    }
}

#endif
