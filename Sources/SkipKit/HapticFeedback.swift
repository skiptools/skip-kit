// Copyright 2024-2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
import Foundation
#if canImport(CoreHaptics)
import CoreHaptics
#endif

/// A single haptic event within a pattern.
public struct HapticEvent {
    /// The type of haptic primitive to play.
    public let type: HapticEventType
    /// Intensity from 0.0 to 1.0.
    public let intensity: Double
    /// Delay in seconds before this event plays (relative to the previous event).
    public let delay: Double

    public init(_ type: HapticEventType, intensity: Double = 1.0, delay: Double = 0.0) {
        self.type = type
        self.intensity = min(max(intensity, 0.0), 1.0)
        self.delay = max(delay, 0.0)
    }
}

/// The type of haptic primitive.
public enum HapticEventType {
    /// A short, sharp tap. The most common haptic element.
    case tap
    /// A subtle, light tick. Good for selections and fine adjustments.
    case tick
    /// A heavy, deep vibration. Good for collisions and impacts.
    case thud
    /// A vibration that increases in intensity. Good for building tension or starting an action.
    case rise
    /// A vibration that decreases in intensity. Good for releasing tension or ending an action.
    case fall
    /// A deep, low-frequency tick. Good for warnings and errors.
    case lowTick
}

/// A sequence of haptic events that form a complete feedback pattern.
public struct HapticPattern {
    public let events: [HapticEvent]

    public init(_ events: [HapticEvent]) {
        self.events = events
    }
}

// MARK: - Predefined Patterns

extension HapticPattern {
    /// A light tap for picking up or selecting an element.
    public static let pick = HapticPattern([HapticEvent(.tick, intensity: 0.4)])

    /// A subtle tick for snapping to a grid or alignment point.
    public static let snap = HapticPattern([
        HapticEvent(.tick, intensity: 0.5),
        HapticEvent(.tick, intensity: 0.3, delay: 0.04)
    ])

    /// A solid tap for placing or confirming an action.
    public static let place = HapticPattern([HapticEvent(.tap, intensity: 0.7)])

    /// A satisfying confirmation pattern.
    public static let success = HapticPattern([
        HapticEvent(.tap, intensity: 0.8),
        HapticEvent(.tick, intensity: 0.5, delay: 0.1)
    ])

    /// An attention-getting warning pattern.
    public static let warning = HapticPattern([
        HapticEvent(.rise, intensity: 0.8),
        HapticEvent(.fall, intensity: 0.9, delay: 0.1)
    ])

    /// A rejection or failure pattern with three descending taps.
    public static let error = HapticPattern([
        HapticEvent(.lowTick, intensity: 1.0),
        HapticEvent(.lowTick, intensity: 0.7, delay: 0.1),
        HapticEvent(.lowTick, intensity: 0.4, delay: 0.1)
    ])

    /// A heavy single impact.
    public static let impact = HapticPattern([HapticEvent(.thud, intensity: 1.0)])

    /// A celebratory double-tap pattern.
    public static let celebrate = HapticPattern([
        HapticEvent(.tap, intensity: 1.0),
        HapticEvent(.rise, intensity: 0.6, delay: 0.08),
        HapticEvent(.tap, intensity: 0.9, delay: 0.08),
        HapticEvent(.tick, intensity: 0.4, delay: 0.1)
    ])

    /// A big celebration with escalating intensity for combos and achievements.
    public static let bigCelebrate = HapticPattern([
        HapticEvent(.thud, intensity: 0.8),
        HapticEvent(.rise, intensity: 1.0, delay: 0.1),
        HapticEvent(.tap, intensity: 1.0, delay: 0.08),
        HapticEvent(.tick, intensity: 0.8, delay: 0.06),
        HapticEvent(.tap, intensity: 0.6, delay: 0.06),
        HapticEvent(.tick, intensity: 0.4, delay: 0.1)
    ])

    /// Creates a repeating bounce pattern with decreasing intensity, like a ball bouncing to rest.
    public static func bounce(count: Int = 3, startIntensity: Double = 0.9) -> HapticPattern {
        var events: [HapticEvent] = []
        for i in 0..<count {
            let fraction = 1.0 - (Double(i) / Double(count))
            let intensity = startIntensity * fraction
            let delay = i == 0 ? 0.0 : 0.06 + Double(i) * 0.03
            events.append(HapticEvent(.tap, intensity: intensity, delay: delay))
        }
        return HapticPattern(events)
    }

    /// Creates an escalating pattern for combo streaks. Higher streaks feel more dramatic.
    public static func combo(streak: Int) -> HapticPattern {
        let clamped = min(max(streak, 1), 8)
        var events: [HapticEvent] = []
        // Quick escalating taps
        for i in 0..<clamped {
            let intensity = 0.4 + (0.6 * Double(i) / Double(clamped))
            let delay = i == 0 ? 0.0 : 0.06
            events.append(HapticEvent(.tap, intensity: intensity, delay: delay))
        }
        // Finish with a satisfying thud
        events.append(HapticEvent(.thud, intensity: min(0.5 + Double(clamped) * 0.1, 1.0), delay: 0.08))
        return HapticPattern(events)
    }
}

// MARK: - Playback

/// Plays custom haptic patterns on both iOS and Android.
public final class HapticFeedback {
    #if canImport(CoreHaptics)
    private static var engine: CHHapticEngine?
    #endif

    /// Play a haptic pattern. Call from any thread.
    public static func play(_ pattern: HapticPattern) {
        guard !pattern.events.isEmpty else { return }

        #if SKIP
        playAndroid(pattern)
        #elseif canImport(CoreHaptics)
        playiOS(pattern)
        #endif
    }

    // MARK: - iOS Implementation

    #if canImport(CoreHaptics)
    private static func playiOS(_ pattern: HapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            if engine == nil {
                engine = try CHHapticEngine()
                engine?.resetHandler = { engine = nil }
                engine?.stoppedHandler = { _ in engine = nil }
            }
            try engine?.start()

            var hapticEvents: [CHHapticEvent] = []
            var timeOffset: TimeInterval = 0

            for event in pattern.events {
                timeOffset += event.delay

                let sharpness: Float
                let eventType: CHHapticEvent.EventType

                switch event.type {
                case .tap:
                    eventType = .hapticTransient
                    sharpness = 0.7
                case .tick:
                    eventType = .hapticTransient
                    sharpness = 1.0
                case .thud:
                    eventType = .hapticTransient
                    sharpness = 0.1
                case .rise:
                    eventType = .hapticContinuous
                    sharpness = 0.5
                case .fall:
                    eventType = .hapticContinuous
                    sharpness = 0.5
                case .lowTick:
                    eventType = .hapticTransient
                    sharpness = 0.3
                }

                var params = [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(event.intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ]

                let duration: TimeInterval
                if eventType == .hapticContinuous {
                    duration = 0.15
                    // For rise/fall, add an intensity curve
                    if event.type == .rise {
                        params.append(CHHapticEventParameter(parameterID: .attackTime, value: Float(duration)))
                    } else if event.type == .fall {
                        params.append(CHHapticEventParameter(parameterID: .decayTime, value: Float(duration)))
                    }
                } else {
                    duration = 0.0 // transient events have no duration
                }

                let hapticEvent = CHHapticEvent(
                    eventType: eventType,
                    parameters: params,
                    relativeTime: timeOffset,
                    duration: duration
                )
                hapticEvents.append(hapticEvent)
            }

            let hapticPattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine?.makePlayer(with: hapticPattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptic playback failure is not critical
            logger.warning("Haptic playback failed: \(error)")
        }
    }
    #endif

    // MARK: - Android Implementation

    #if SKIP
    private static let vibrator: android.os.Vibrator? = {
        let context = ProcessInfo.processInfo.androidContext
        if android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.S {
            return nil
        }
        guard let mgr = context.getSystemService(android.content.Context.VIBRATOR_MANAGER_SERVICE) as? android.os.VibratorManager else {
            return nil
        }
        return mgr.getDefaultVibrator()
    }()

    private static func playAndroid(_ pattern: HapticPattern) {
        guard let vibrator = vibrator else { return }

        let composition = android.os.VibrationEffect.startComposition()
        var delayMs = 0

        for event in pattern.events {
            delayMs += Int(event.delay * 1000.0)

            let primitive: Int
            switch event.type {
            case .tap:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_CLICK
            case .tick:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_TICK
            case .thud:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_THUD
            case .rise:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_QUICK_RISE
            case .fall:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_QUICK_FALL
            case .lowTick:
                primitive = android.os.VibrationEffect.Composition.PRIMITIVE_LOW_TICK
            }

            composition.addPrimitive(primitive, Float(event.intensity), delayMs)
            delayMs = 0 // reset after adding; next event's delay is relative
        }

        vibrator.vibrate(composition.compose())
    }
    #endif
}

#endif
