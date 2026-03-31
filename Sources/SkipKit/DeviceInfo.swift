// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
import SwiftUI

#if SKIP
import android.content.Context
import android.content.res.Configuration
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.util.DisplayMetrics
import android.view.WindowManager
#else
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Network)
import Network
#endif
#if canImport(IOKit)
import IOKit.ps
#endif
#endif

// MARK: - DeviceType

/// The general category of the device.
public enum DeviceType: String, Sendable {
    case phone
    case tablet
    case desktop
    case tv
    case watch
    case unknown
}

// MARK: - BatteryState

/// The current charging state of the device battery.
public enum BatteryState: String, Sendable {
    /// The device is not plugged in and running on battery.
    case unplugged
    /// The device is plugged in and charging.
    case charging
    /// The device is plugged in and the battery is full.
    case full
    /// The battery state is unknown.
    case unknown
}

// MARK: - NetworkStatus

/// The current network connectivity status.
public enum NetworkStatus: String, Sendable {
    /// The device has no network connectivity.
    case offline
    /// The device is connected via Wi-Fi.
    case wifi
    /// The device is connected via cellular data.
    case cellular
    /// The device is connected via Ethernet.
    case ethernet
    /// The device is connected via an unknown transport.
    case other
}

// MARK: - DeviceInfo

/// Provides information about the current device, including screen size, device type,
/// battery status, and network connectivity.
///
/// Access via the `DeviceInfo.current` singleton.
///
/// On iOS, this reads from `UIDevice`, `UIScreen`, `NWPathMonitor`, and `ProcessInfo`.
/// On Android, this reads from `DisplayMetrics`, `BatteryManager`, `ConnectivityManager`, and `Build`.
public final class DeviceInfo {
    nonisolated(unsafe) public static let current = DeviceInfo()

    private init() { }

    // MARK: - Screen

    /// The screen width in points.
    public var screenWidth: Double {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let dm = context.getResources().getDisplayMetrics()
        return Double(dm.widthPixels) / Double(dm.density)
        #elseif os(iOS)
        return Double(UIScreen.main.bounds.width)
        #elseif os(macOS)
        return Double(NSScreen.main?.frame.width ?? 0)
        #else
        return 0
        #endif
    }

    /// The screen height in points.
    public var screenHeight: Double {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let dm = context.getResources().getDisplayMetrics()
        return Double(dm.heightPixels) / Double(dm.density)
        #elseif os(iOS)
        return Double(UIScreen.main.bounds.height)
        #elseif os(macOS)
        return Double(NSScreen.main?.frame.height ?? 0)
        #else
        return 0
        #endif
    }

    /// The screen scale factor (pixels per point).
    public var screenScale: Double {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        return Double(context.getResources().getDisplayMetrics().density)
        #elseif os(iOS)
        return Double(UIScreen.main.scale)
        #elseif os(macOS)
        return Double(NSScreen.main?.backingScaleFactor ?? 1.0)
        #else
        return 1.0
        #endif
    }

    // MARK: - Device Type

    /// The general category of the current device.
    ///
    /// On iOS: uses `UIDevice.current.userInterfaceIdiom`.
    /// On Android: uses screen size configuration (smallest width >= 600dp = tablet).
    public var deviceType: DeviceType {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let config = context.getResources().getConfiguration()
        let screenLayout = config.screenLayout & Configuration.SCREENLAYOUT_SIZE_MASK
        if screenLayout >= Configuration.SCREENLAYOUT_SIZE_XLARGE {
            return .tablet
        } else if screenLayout >= Configuration.SCREENLAYOUT_SIZE_LARGE {
            return .tablet
        } else {
            return .phone
        }
        #elseif os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .phone
        case .pad: return .tablet
        case .tv: return .tv
        case .mac: return .desktop
        default: return .unknown
        }
        #elseif os(macOS)
        return .desktop
        #elseif os(tvOS)
        return .tv
        #elseif os(watchOS)
        return .watch
        #else
        return .unknown
        #endif
    }

    /// Whether the device is likely a tablet (iPad or large-screen Android device).
    public var isTablet: Bool {
        deviceType == .tablet
    }

    /// Whether the device is likely a phone.
    public var isPhone: Bool {
        deviceType == .phone
    }

    // MARK: - Device Model

    /// The manufacturer of the device.
    ///
    /// On iOS: always `"Apple"`.
    /// On Android: `Build.MANUFACTURER` (e.g. `"Google"`, `"Samsung"`).
    public var manufacturer: String {
        #if SKIP
        return Build.MANUFACTURER
        #else
        return "Apple"
        #endif
    }

    /// The model name of the device.
    ///
    /// On iOS: the machine identifier (e.g. `"iPhone15,2"`).
    /// On Android: `Build.MODEL` (e.g. `"Pixel 7"`).
    public var modelName: String {
        #if SKIP
        return Build.MODEL
        #elseif os(iOS)
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        #elseif os(macOS)
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        #else
        return "Unknown"
        #endif
    }

    // MARK: - Battery

    /// The current battery level as a value from 0.0 to 1.0, or `nil` if unavailable.
    ///
    /// On iOS: uses `UIDevice.current.batteryLevel` (must enable monitoring).
    /// On Android: uses `BatteryManager.EXTRA_LEVEL`.
    public var batteryLevel: Double? {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        guard let bm = bm else { return nil }
        let level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        if level < 0 { return nil }
        return Double(level) / 100.0
        #elseif os(iOS)
        let device = UIDevice.current
        let wasEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let level = device.batteryLevel
        if !wasEnabled { device.isBatteryMonitoringEnabled = false }
        if level < 0 { return nil }
        return Double(level)
        #else
        return nil
        #endif
    }

    /// The current battery charging state.
    ///
    /// On iOS: uses `UIDevice.current.batteryState`.
    /// On Android: uses `BatteryManager.isCharging()` and battery property.
    public var batteryState: BatteryState {
        #if SKIP
        let context = ProcessInfo.processInfo.androidContext
        let bm = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        guard let bm = bm else { return .unknown }
        if bm.isCharging() {
            let level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            return level >= 100 ? .full : .charging
        }
        return .unplugged
        #elseif os(iOS)
        let device = UIDevice.current
        let wasEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let state = device.batteryState
        if !wasEnabled { device.isBatteryMonitoringEnabled = false }
        switch state {
        case .unplugged: return .unplugged
        case .charging: return .charging
        case .full: return .full
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
        #else
        return .unknown
        #endif
    }

    // MARK: - Network

    /// A one-shot check of the current network connectivity status.
    ///
    /// For live updates, use `monitorNetwork()` instead.
    ///
    /// On iOS: uses `NWPathMonitor` for a single snapshot.
    /// On Android: uses `ConnectivityManager` with `NetworkCapabilities`.
    public var networkStatus: NetworkStatus {
        #if SKIP
        return Self.queryAndroidNetworkStatus()
        #elseif canImport(Network)
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "skip.kit.network.snapshot")
        var result: NetworkStatus = .offline
        let semaphore = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { path in
            result = Self.mapNWPath(path)
            semaphore.signal()
        }
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        return result
        #else
        return .offline
        #endif
    }

    /// Whether the device currently has network connectivity (one-shot check).
    public var isOnline: Bool {
        networkStatus != .offline
    }

    /// Whether the device is connected via Wi-Fi (one-shot check).
    public var isOnWifi: Bool {
        networkStatus == .wifi
    }

    /// Whether the device is connected via cellular data (one-shot check).
    public var isOnCellular: Bool {
        networkStatus == .cellular
    }

    /// Returns an `AsyncStream` that emits `NetworkStatus` values whenever connectivity changes.
    ///
    /// The stream emits an initial value immediately, then a new value each time the
    /// network status changes (e.g. Wi-Fi connected, cellular lost, etc.).
    ///
    /// Cancel the `for await` loop or the enclosing `Task` to stop monitoring.
    ///
    /// On iOS: uses `NWPathMonitor` for live path updates.
    /// On Android: uses `ConnectivityManager.registerDefaultNetworkCallback`.
    ///
    /// ```swift
    /// for await status in DeviceInfo.current.monitorNetwork() {
    ///     print("Network: \(status)")
    /// }
    /// ```
    public func monitorNetwork() -> AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            #if SKIP
            let context = ProcessInfo.processInfo.androidContext
            let cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager

            // Emit initial status
            continuation.yield(Self.queryAndroidNetworkStatus())

            guard let cm = cm else {
                continuation.finish()
                return
            }

            /* SKIP INSERT:
            val callback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: android.net.Network) {
                    continuation.yield(DeviceInfo.queryAndroidNetworkStatus())
                }
                override fun onLost(network: android.net.Network) {
                    continuation.yield(NetworkStatus.offline)
                }
                override fun onCapabilitiesChanged(network: android.net.Network, caps: NetworkCapabilities) {
                    continuation.yield(DeviceInfo.queryAndroidNetworkStatus())
                }
            }
             */

            cm.registerDefaultNetworkCallback(callback)

            continuation.onTermination = { _ in
                // SKIP INSERT: cm.unregisterNetworkCallback(callback)
            }

            #elseif canImport(Network)
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "skip.kit.network.monitor")
            monitor.pathUpdateHandler = { path in
                continuation.yield(Self.mapNWPath(path))
            }
            monitor.start(queue: queue)

            continuation.onTermination = { _ in
                monitor.cancel()
            }
            #else
            continuation.yield(.offline)
            continuation.finish()
            #endif
        }
    }

    // MARK: - Network Helpers

    #if SKIP
    private static func queryAndroidNetworkStatus() -> NetworkStatus {
        let context = ProcessInfo.processInfo.androidContext
        let cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        guard let cm = cm else { return .offline }
        let network = cm.getActiveNetwork()
        guard let network = network else { return .offline }
        let caps = cm.getNetworkCapabilities(network)
        guard let caps = caps else { return .offline }
        if caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) { return .wifi }
        if caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) { return .cellular }
        if caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) { return .ethernet }
        return .other
    }
    #endif

    #if canImport(Network) && !SKIP
    private static func mapNWPath(_ path: NWPath) -> NetworkStatus {
        guard path.status == .satisfied else { return .offline }
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .other
    }
    #endif

    // MARK: - Locale

    /// The user's current locale identifier (e.g. `"en_US"`).
    public var localeIdentifier: String {
        Locale.current.identifier
    }

    /// The user's preferred language code (e.g. `"en"`).
    public var languageCode: String? {
        #if SKIP
        return Locale.current.language.languageCode?.identifier
        #else
        return Locale.current.language.languageCode?.identifier
        #endif
    }

    /// The user's current time zone identifier (e.g. `"America/New_York"`).
    public var timeZoneIdentifier: String {
        TimeZone.current.identifier
    }
}

#endif
