// Copyright 2025-2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI

#if !SKIP
import LocalAuthentication
#else
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
#endif

public enum BiometricAuthenticationType: String, Sendable {
    case none
    case fingerprint
    case facialRecognition
    case unspecified
}

public enum BiometricAuthenticationResult: Sendable {
    case success
    case cancelled
    case failed
    case unavailable
}

public enum BiometricAuthentication {

    // MARK: - Properties
    public static var authenticationType: BiometricAuthenticationType {
        #if !SKIP
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .fingerprint
        case .faceID:
            return .facialRecognition
        default:
            return .none
        }
        #else
        guard let activity = UIApplication.shared.androidActivity else {
            return .none
        }

        let manager = BiometricManager.from(activity)
        let authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG

        if manager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS {
            return .unspecified
        } else {
            return .none
        }
        #endif
    }

    public static var canAuthenticate: Bool {
        self.authenticationType != .none
    }

    // MARK: - Functions

    /// Authenticates the user with the device's biometric authentication method.
    ///
    /// - Parameters:
    ///   - localizedReason: The authentication reason.
    ///   - allowsDeviceCredentialFallback: A Boolean value indicating whether the system device credential can be used as a fallback.
    ///   - completion: The authentication completion handler.
    public static func authenticate(
        localizedReason: String,
        allowsDeviceCredentialFallback: Bool = false,
        completion: @escaping @MainActor (BiometricAuthenticationResult) -> Void
    ) {
        #if !SKIP
        let context = LAContext()
        let policy: LAPolicy = allowsDeviceCredentialFallback
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics
        var error: NSError?

        guard context.canEvaluatePolicy(
            policy,
            error: &error
        ) else {
            Task { @MainActor in
                completion(.unavailable)
            }
            return
        }

        context.evaluatePolicy(
            policy,
            localizedReason: localizedReason
        ) { success, error in
            Task { @MainActor in
                if success {
                    completion(.success)
                } else if let error = error as? LAError, error.isCancellation {
                    completion(.cancelled)
                } else {
                    completion(.failed)
                }
            }
        }
        #else
        guard let activity = UIApplication.shared.androidActivity as? FragmentActivity else {
            completion(.unavailable)
            return
        }

        let manager = BiometricManager.from(activity)
        let authenticators = allowsDeviceCredentialFallback
            ? BiometricManager.Authenticators.BIOMETRIC_STRONG | BiometricManager.Authenticators.DEVICE_CREDENTIAL
            : BiometricManager.Authenticators.BIOMETRIC_STRONG

        guard manager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS else {
            completion(.unavailable)
            return
        }

        let executor = ContextCompat.getMainExecutor(activity)
        let callback = AndroidBiometricAuthenticationCallback(completion: completion)
        let prompt = BiometricPrompt(activity, executor, callback)
        let builder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(localizedReason)
            .setAllowedAuthenticators(authenticators)

        if !allowsDeviceCredentialFallback {
            builder.setNegativeButtonText(activity.getString(android.R.string.cancel))
        }

        prompt.authenticate(builder.build())
        #endif
    }
}

#if SKIP
private final class AndroidBiometricAuthenticationCallback: BiometricPrompt.AuthenticationCallback {

    // MARK: - Properties
    let completion: @MainActor (BiometricAuthenticationResult) -> Void

    // MARK: - Initialization

    /// Initializes a new instance of the `AndroidBiometricAuthenticationCallback` class.
    ///
    /// - Parameter completion: The authentication completion handler.
    init(completion: @escaping @MainActor (BiometricAuthenticationResult) -> Void) {
        self.completion = completion
    }

    // MARK: - Functions

    /// Handles successful biometric authentication.
    ///
    /// - Parameter result: The biometric prompt authentication result.
    override func onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
        self.completion(.success)
    }

    /// Handles biometric authentication errors.
    ///
    /// - Parameters:
    ///   - errorCode: The Android biometric prompt error code.
    ///   - errString: The Android biometric prompt error message.
    override func onAuthenticationError(errorCode: Int, errString: CharSequence) {
        switch errorCode {
        case BiometricPrompt.ERROR_NEGATIVE_BUTTON,
             BiometricPrompt.ERROR_USER_CANCELED,
             BiometricPrompt.ERROR_CANCELED:
            self.completion(.cancelled)
        default:
            self.completion(.failed)
        }
    }

    /// Handles a failed biometric match while the prompt remains active.
    override func onAuthenticationFailed() {
        // Nothing to do here. Android keeps the biometric prompt active.
    }
}
#endif

#if !SKIP
private extension LAError {

    // MARK: - Properties
    var isCancellation: Bool {
        switch self.code {
        case .appCancel, .systemCancel, .userCancel, .userFallback:
            return true
        default:
            return false
        }
    }
}
#endif
#endif
