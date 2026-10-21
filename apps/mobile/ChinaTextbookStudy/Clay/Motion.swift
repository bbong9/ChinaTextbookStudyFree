import SwiftUI

/// design/index.html:277–298。周期为完整的 0% → 50% → 100%，距离是舞台点。
enum ClayMotion: String, CaseIterable {
    case bob, drift, drift2, pulse, twinkle, flutter

    var duration: TimeInterval {
        switch self {
        case .bob: return 2.4
        case .drift: return 9
        case .drift2: return 12
        case .pulse: return 1.8
        case .twinkle: return 2
        case .flutter: return 0.5
        }
    }

    struct Sample: Equatable {
        var x: CGFloat = 0, y: CGFloat = 0
        var scaleX: CGFloat = 1, scaleY: CGFloat = 1
        var opacity: Double = 1
    }

    func sample(at elapsed: TimeInterval, paused: Bool = false) -> Sample {
        // prefers-reduced-motion 的 animation:none 保留素材本来的不透明度和变换。
        guard !paused else { return Sample() }
        let phase = max(0, elapsed).truncatingRemainder(dividingBy: duration) / duration
        let progress = Self.easeInOut(phase <= 0.5 ? phase * 2 : (1 - phase) * 2)
        switch self {
        case .bob: return Sample(y: -6 * progress)
        case .drift, .drift2: return Sample(x: 18 * progress)
        case .pulse: return Sample(scaleX: 1 + 0.06 * progress, scaleY: 1 + 0.06 * progress,
                                  opacity: 0.75 + 0.25 * progress)
        case .twinkle: return Sample(opacity: 0.35 + 0.65 * progress)
        case .flutter: return Sample(scaleX: 1 - 0.6 * progress)
        }
    }

    /// CSS ease-in-out = cubic-bezier(.42, 0, .58, 1)。二分反解时间轴，避免正弦近似。
    private static func easeInOut(_ x: Double) -> Double {
        var low = 0.0, high = 1.0
        for _ in 0..<16 {
            let t = (low + high) / 2, u = 1 - t
            let value = 3 * u * u * t * 0.42 + 3 * u * t * t * 0.58 + t * t * t
            if value < x { low = t } else { high = t }
        }
        let t = (low + high) / 2
        return 3 * (1 - t) * t * t + t * t * t
    }
}

private struct ClayMotionPausedKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var clayMotionPaused: Bool {
        get { self[ClayMotionPausedKey.self] }
        set { self[ClayMotionPausedKey.self] = newValue }
    }
}

private struct ClayMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.clayMotionPaused) private var locallyPaused
    @State private var start = Date()
    let motion: ClayMotion?

    func body(content: Content) -> some View {
        if let motion {
            let paused = reduceMotion || locallyPaused
            TimelineView(.animation(paused: paused)) { timeline in
                let value = motion.sample(at: timeline.date.timeIntervalSince(start), paused: paused)
                content
                    .offset(x: value.x, y: value.y)
                    .scaleEffect(x: value.scaleX, y: value.scaleY)
                    .opacity(value.opacity)
            }
        } else {
            content
        }
    }
}

extension View {
    func clayMotion(_ motion: ClayMotion?) -> some View { modifier(ClayMotionModifier(motion: motion)) }
}
