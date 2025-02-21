// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
#if !SKIP_BRIDGE
import Foundation
#if !SKIP
import SystemConfiguration
#else
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
#endif

/// Provides general information for a Skip app.
@available(*, deprecated, message: "relocated to the skip-device framework")
public class Reachability {

    /// Returns true if the network is currently reachable
    public static var isNetworkReachable: Bool {
        #if !SKIP
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        guard SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) else {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
        #else
        let context = ProcessInfo.processInfo.androidContext
        let connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        if Build.VERSION.SDK_INT >= Build.VERSION_CODES.M {
            guard let network = connectivityManager.activeNetwork else { return false }
            guard let activeNetwork = connectivityManager.getNetworkCapabilities(network) else { return false }

            if activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) { return true }
            if activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) { return true }
            if activeNetwork.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) { return true }

            return false
        } else {
            // older devices…
            let networkInfo = connectivityManager.activeNetworkInfo
            return networkInfo != nil && networkInfo.isConnected
        }
        #endif
    }
}
#endif

