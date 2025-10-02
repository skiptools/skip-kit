// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation

/// A cache of keys to values. It can be configured to automatically evict entries when the total entries surpass a given cost limit, as well as remove entries under memory pressure.
///
/// On iOS, this is backed by an [`NSCache`](https://developer.apple.com/documentation/foundation/nscache), and on Android it uses a [`android.util.LruCache`](https://developer.android.com/reference/android/util/LruCache). The exact implementation behavior of the caches varies between the platforms, but is generally considered to behave in an optimal way for each operating system.
public class Cache<Key: Hashable, Value> {
    private let cacheLock = NSLock()
    private let manager: CacheManager<Key, Value>

    public init(evictOnBackground: Bool = true, limit: Int? = nil, cost: ((Value) -> Int)? = nil) {
        self.manager = CacheManager(evictOnBackground: evictOnBackground, limit: limit, cost: cost)
    }

    /// Lock the cache for an atomic operation.
    public func lock() {
        cacheLock.lock()
    }

    /// Lock the cache at the end of an atomic operation.
    public func unlock() {
        cacheLock.unlock()
    }

    /// Evict all entries from the cache.
    public func clear() {
        lock()
        defer { unlock() }
        manager.clear()
    }

    /// Gets the given key's value from the cache
    public func getValue(for key: Key) -> Value? {
        self[key]
    }

    /// Sets the given value for the key in the cache
    public func putValue(_ value: Value, for key: Key) {
        self[key] = value
    }

    /// Get or set a value in the cache.
    // SKIP @nobridge // This release does not yet support bridging custom subscripts and operators
    public subscript(key: Key) -> Value? {
        get {
            lock()
            defer { unlock() }
            return manager.get(key: key)
        }

        set {
            lock()
            defer { unlock() }
            manager.put(key: key, value: newValue)
        }
    }
}

#if SKIP
private final class CacheManager<Key, Value> {
    let cache: LRUCostCache<Key, Value>
    let limit: Int?
    let cacheCallbacks: CacheManagerCallbacks

    init(evictOnBackground: Bool, limit: Int?, cost: ((Value) -> Int)?) {
        self.cache = LRUCostCache(limit: limit ?? Int.MAX_VALUE, cost: cost)
        self.limit = limit
        self.cacheCallbacks = CacheManagerCallbacks(cache: self, evictOnBackground: evictOnBackground)
        ProcessInfo.processInfo.androidContext.registerComponentCallbacks(cacheCallbacks)
    }

    deinit {
        // de-register the callbacks when this CacheManager is gc'd (which will be possible since the CacheManagerCallbacks only maintains a weak reference to this instance)
        ProcessInfo.processInfo.androidContext.unregisterComponentCallbacks(cacheCallbacks)
    }

    func clear() {
        cache.evictAll()
    }

    func get(key: Key) -> Value? {
        cache.get(key)
    }

    func put(key: Key, value: Value?) {
        if let value {
            self.cache.put(key, value)
        } else {
            self.cache.remove(key)
        }
    }
}

private final class CacheManagerCallbacks<Key, Value>: android.content.ComponentCallbacks2 {
    // We need to maintain a separate ComponentCallbacks2 with a weak reference to the cache, otherwise it will never be GC'd
    private let cacheRef: java.lang.ref.WeakReference<CacheManager<Key, Value>>
    private let evictOnBackground: Bool

    init(cache: CacheManager<Key, Value>, evictOnBackground: Bool) {
        self.cacheRef = java.lang.ref.WeakReference(cache)
        self.evictOnBackground = evictOnBackground
    }

    func clear() {
        cacheRef.get()?.clear()
    }

    override func onLowMemory() {
        self.clear()
    }

    override func onTrimMemory(level: Int) {
        /// `TRIM_MEMORY_UI_HIDDEN`: Your app's UI is no longer visible. This is a good time to release large memory allocations that are used only by your UI, such as Bitmaps, or resources related to video playback or animations.
        if level >= android.content.ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN {
            if evictOnBackground {
                self.clear()
            }
        }

        /// `TRIM_MEMORY_BACKGROUND`: Your app's process is considered to be in the background, and has become eligible to be killed in order to free memory for other processes. Releasing more memory will prolong the time that your process can remain cached in memory. An effective strategy is to release resources that can be re-built when the user returns to your app.
        if level >= android.content.ComponentCallbacks2.TRIM_MEMORY_BACKGROUND {
            if evictOnBackground {
                self.clear()
            }
        }

        // deprecated in API 35: TRIM_MEMORY_COMPLETE, TRIM_MEMORY_MODERATE, TRIM_MEMORY_BACKGROUND, TRIM_MEMORY_UI_HIDDEN, TRIM_MEMORY_RUNNING_CRITICAL, TRIM_MEMORY_RUNNING_LOW, or TRIM_MEMORY_RUNNING_MODERATE
    }

    override func onConfigurationChanged(config: android.content.res.Configuration) {
    }

}

/// A cache that takes an optional cost evaluator function to determine the cost of an entry
private final class LRUCostCache<Key, Value>: android.util.LruCache<Key, Value> {
    let cost: ((Value) -> Int)?

    init(limit: Int? = nil, cost: ((Value) -> Int)? = nil) {
        super.init(limit ?? Int.MAX_VALUE)
        self.cost = cost
    }

    /// Returns the size of the entry for key and value in user-defined units. The default implementation returns 1 so that size is the number of entries and max size is the maximum number of entries.
    override func sizeOf(key: Key, value: Value) -> Int {
        if let cost {
            return cost(value)
        } else {
            return super.sizeOf(key, value) // i.e., 1
        }
    }
}

#else
private final class CacheManager<Key: Hashable, Value>: NSObject, NSCacheDelegate {
    let cache = NSCache<CacheKey, CacheValue>()
    let limit: Int?
    let cost: ((Value) -> Int)?
    private var didEnterBackgroundObserver: NSObjectProtocol?
    #if canImport(UIKit)
    /// https://developer.apple.com/documentation/uikit/uiapplication/didenterbackgroundnotification
    private let backgroundNotificationName = Notification.Name("UIApplicationDidEnterBackgroundNotification")
    #elseif canImport(AppKit)
    /// https://developer.apple.com/documentation/appkit/nsapplication/didresignactivenotification
    private let backgroundNotificationName = Notification.Name("NSApplicationDidResignActiveNotification")
    #endif

    public init(evictOnBackground: Bool, limit: Int?, cost: ((Value) -> Int)?) {
        self.limit = limit
        self.cost = cost

        super.init()

        cache.delegate = self

        if let limit {
            if cost != nil {
                // when the cost evaluator is set, the limit is the total cost limit
                cache.totalCostLimit = limit
            } else {
                // otherwise the limit is simply the size
                cache.countLimit = limit
            }
        }

        if evictOnBackground {
            self.didEnterBackgroundObserver = NotificationCenter.default.addObserver(forName: backgroundNotificationName, object: self, queue: nil) { [weak self] notification in
                MainActor.assumeIsolated {
                    self?.clear()
                }
            }
        }
    }

    deinit {
        cache.delegate = nil
        if let didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(didEnterBackgroundObserver, name: backgroundNotificationName, object: self)
        }
    }

    func get(key: Key) -> Value? {
        cache.object(forKey: CacheKey(key))?.value
    }

    func put(key: Key, value: Value?) {
        let cacheKey = CacheKey(key)
        if let value {
            if let cost {
                // evaluate cost of cached value
                cache.setObject(CacheValue(value: value), forKey: cacheKey, cost: cost(value))
            } else {
                cache.setObject(CacheValue(value: value), forKey: cacheKey)
            }
        } else {
            cache.removeObject(forKey: cacheKey)
        }
    }

    func clear() {
        cache.removeAllObjects()
    }

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        //print("evict: \((obj as? CacheValue)?.value ?? obj)")
    }

    /// A reference wrapper around a Hashable key (which might be a value type)
    final class CacheKey: Hashable {
        let key: Key
        init(_ key: Key) { self.key = key }
        func hash(into hasher: inout Hasher) { hasher.combine(key) }
        static func ==(lhs: CacheKey, rhs: CacheKey) -> Bool { lhs.key == rhs.key }
    }

    final class CacheValue {
        let value: Value
        init(value: Value) { self.value = value }
    }
}
#endif
#endif
