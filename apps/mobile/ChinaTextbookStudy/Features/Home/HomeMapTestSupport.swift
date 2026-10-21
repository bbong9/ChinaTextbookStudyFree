#if DEBUG
import SwiftUI
import UIKit

/// 只读合成测试参数；不扩展存档或经济规则。
enum HomeMapTestSeed {
    static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("-uitest") }
    static func flag(_ value: String) -> Bool { enabled && ProcessInfo.processInfo.arguments.contains(value) }
    static func value(_ key: String) -> String? {
        guard enabled else { return nil }
        return PetScreenTestSeed.value(key)
    }
    static func apply(to progress: inout UserProgress, now: Date) {
        if flag("-uitest-map-daily") { progress.lastDailyRewardDate = nil }
        if flag("-uitest-map-zero-hearts") {
            progress.hearts = 0
            progress.nextHeartAt = now.addingTimeInterval(300).timeIntervalSince1970 * 1000
        }
        if flag("-uitest-map-chest") || flag("-uitest-map-late-current") {
            let count = flag("-uitest-map-late-current") ? 18 : 11
            let bookId = "g1up"
            if let outline = try? DataLoader.shared.loadOutline(bookId: bookId) {
                for meta in outline.pathLessonMetas(bookId: bookId).prefix(count) {
                    progress.completedLessons[meta.id] = LessonResult(lessonId: meta.id, stars: 3, accuracy: 1,
                        completedAt: ISO8601DateFormatter().string(from: now))
                }
            }
        }
        if flag("-uitest-map-league") {
            progress.pendingLeagueResult = LeagueWeekResult(weekKey: "2026-10-12", rank: 1,
                tierBefore: "bronze", tierAfter: "silver", promoted: true, demoted: false, gems: 30)
        }
    }
}

/// CADisplayLink 只在测试参数开启时挂载，统计实际滚动期间的显示回调间隔。
struct HomeMapFPSProbe: UIViewRepresentable {
    let offset: CGFloat
    func makeUIView(context: Context) -> FPSLabel { FPSLabel() }
    func updateUIView(_ view: FPSLabel, context: Context) { view.scrolled(to: offset) }
    static func dismantleUIView(_ view: FPSLabel, coordinator: ()) { view.stop() }

    final class FPSLabel: UILabel {
        private var link: CADisplayLink?
        private var lastTime: CFTimeInterval = 0
        private var lastMotion: CFTimeInterval = 0
        private var previousOffset: CGFloat = 0
        private var samples: [Double] = []
        private var lastReport: CFTimeInterval = 0
        override init(frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = true; accessibilityIdentifier = "map-performance"
            font = .monospacedSystemFont(ofSize: 10, weight: .medium)
            textColor = .black; backgroundColor = .white
            let link = CADisplayLink(target: self, selector: #selector(frameTick(_:)))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            link.add(to: .main, forMode: .common); self.link = link
        }
        required init?(coder: NSCoder) { fatalError() }
        func stop() { link?.invalidate(); link = nil }
        func scrolled(to offset: CGFloat) {
            if abs(offset - previousOffset) > 0.1 { lastMotion = CACurrentMediaTime(); previousOffset = offset }
        }
        @objc private func frameTick(_ link: CADisplayLink) {
            defer { lastTime = link.timestamp }
            guard lastTime > 0 else { return }
            if link.timestamp - lastMotion < 0.25 { samples.append(link.timestamp - lastTime) }
            guard link.timestamp - lastReport > 0.5, !samples.isEmpty else { return }
            lastReport = link.timestamp
            let fps = Double(samples.count) / samples.reduce(0, +)
            let sorted = samples.sorted()
            let p95 = sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.95))] * 1000
            let report = String(format: "frames=%d fps=%.2f p95_ms=%.2f", samples.count, fps, p95)
            text = report; accessibilityValue = report
        }
    }
}
#endif
