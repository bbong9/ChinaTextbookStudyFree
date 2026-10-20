import SwiftUI

/// 120×130 的黏土矢量宠物，size 指宽。省略 kind/accessory 时读取当前展示环境。
struct PetView: View {
    var kind: PetKind? = nil
    var mood: MascotMood = .happy
    var size: CGFloat = 120
    var reactTo: MascotReaction? = nil
    var reactKey: Int = 0
    var accessory: PetAccessory? = nil
    var bloom = false
    var crack = 0
    var allowsTap = false

    @Environment(\.petEnvironment) private var pet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.petAnimationsPaused) private var paused
    @State private var reactionY: CGFloat = 0
    @State private var reactionRotation = 0.0
    @State private var reactionScale: CGFloat = 1
    @State private var tapKey = 0
    @State private var lastRequest: ReactionRequest?
    @State private var reactionRun = UUID()

    private var activeKind: PetKind { kind ?? pet.kind }
    private var activeAccessory: PetAccessory { accessory ?? pet.accessory }
    private var moves: Bool { !reduceMotion && !paused }
    private var request: ReactionRequest {
        .init(reaction: reactTo, key: reactKey, tap: tapKey, moves: moves)
    }

    var body: some View {
        Group {
            if allowsTap {
                Button(action: tap) { illustration }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
            } else {
                illustration
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(activeKind.name)
        .accessibilityValue("\(mood.petLabel)，\(activeAccessory.name)，\(moves ? "动态效果开启" : "动态效果已减少")")
        .accessibilityAddTraits(allowsTap ? .isButton : [])
        .accessibilityIdentifier("pet-\(activeKind.artKey)")
        .task(id: request) {
            let current = request
            let tapped = current.tap != (lastRequest?.tap ?? 0)
            lastRequest = current
            await react(tapped ? .correct : current.reaction)
        }
    }

    private var illustration: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !moves)) { time in
            let phase = moves ? time.date.timeIntervalSinceReferenceDate : 0
            let breath = moves ? (1 - cos(phase * .pi / 2.6)) * 0.01 : 0
            let blink = moves && phase.truncatingRemainder(dividingBy: 4.8) > 4.66
            Canvas { context, dimensions in
                var ctx = context
                ctx.scaleBy(x: dimensions.width / 120, y: dimensions.height / 130)
                let extra = activeAccessory.topOverflow(for: activeKind.anchors)
                let fit = 130 / (130 + extra)
                ctx.translateBy(x: 60 * (1 - fit), y: extra * fit)
                ctx.scaleBy(x: fit, y: fit)
                PetArtwork(context: ctx).draw(activeKind, mood: mood, bloom: bloom,
                    crack: crack, blink: blink, wave: moves ? sin(phase * 7) * 12 : 0,
                    accessory: activeAccessory)
            }
            .frame(width: size, height: size * 130 / 120)
            .scaleEffect((1 + breath) * (moves ? reactionScale : 1), anchor: .bottom)
            .offset(y: moves ? reactionY - breath * size : 0)
            .rotationEffect(.degrees(moves ? reactionRotation : 0))
        }
    }

    private func tap() {
        HapticEngine.shared.tap()
        SFXEngine.shared.play(.tap)
        tapKey += 1
    }

    /// task 随视图移除、外部触发键或系统设置变化取消，不遗留 Timer/异步回调。
    @MainActor private func react(_ reaction: MascotReaction?) async {
        let run = UUID()
        reactionRun = run
        resetReaction()
        guard moves, let reaction else { return }
        defer { if reactionRun == run { resetReaction() } }
        do {
            switch reaction {
            case .correct:
                withAnimation(.easeOut(duration: 0.18)) { reactionY = -size * 0.12; reactionScale = 1.08 }
                try await Task.sleep(for: .milliseconds(180))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { reactionY = 0; reactionScale = 1 }
                try await Task.sleep(for: .milliseconds(450))
            case .wrong:
                for angle in [-7.0, 7, -4, 0] {
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: 0.1)) { reactionRotation = angle }
                    try await Task.sleep(for: .milliseconds(100))
                }
            case .levelup:
                withAnimation(.easeOut(duration: 0.25)) { reactionY = -size * 0.2; reactionScale = 1.1 }
                withAnimation(.easeInOut(duration: 0.65)) { reactionRotation = 360 }
                try await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { reactionY = 0; reactionScale = 1 }
                try await Task.sleep(for: .milliseconds(400))
            }
        } catch { /* 取消时由 defer 清零。 */ }
    }

    private func resetReaction() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { reactionY = 0; reactionRotation = 0; reactionScale = 1 }
    }

    private struct ReactionRequest: Hashable {
        let reaction: MascotReaction?
        let key: Int
        let tap: Int
        let moves: Bool
    }
}

extension MascotMood {
    static var petMoods: [Self] { [.happy, .cheer, .sad, .think, .wave, .surprise, .proud, .embarrassed] }
    var petLabel: String {
        switch self {
        case .happy: return "开心"
        case .cheer: return "欢呼"
        case .sad: return "难过"
        case .think: return "思考"
        case .wave: return "挥手"
        case .surprise: return "惊讶"
        case .proud: return "自豪"
        case .embarrassed: return "害羞"
        }
    }
}
