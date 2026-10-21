import SwiftUI

enum EggHatchPhase: Int, CaseIterable {
    case shakeLeft1, shakeRight1, shakeLeft2, shakeRight2, shakeLeft3, shakeRight3
    case crack1, crack2, crack3, broken, revealed
    var crack: Int { min(3, max(0, rawValue - Self.crack1.rawValue + 1)) }
    var angle: Double { rawValue < Self.crack1.rawValue ? (rawValue.isMultiple(of: 2) ? -12 : 12) : 0 }
    var title: String {
        switch self {
        case .shakeLeft1, .shakeRight1, .shakeLeft2, .shakeRight2, .shakeLeft3, .shakeRight3: return "咚咚！谁在里面？"
        case .crack1, .crack2, .crack3: return "小伙伴就要出来啦！"
        case .broken: return "蛋壳裂开啦！"
        case .revealed: return "认识新朋友！"
        }
    }
}

struct EggHatchView: View {
    let kind: PetKind
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.clayMotionPaused) private var clayPaused
    @Environment(\.petAnimationsPaused) private var petPaused
    @State private var phase: EggHatchPhase = .shakeLeft1
    private var paused: Bool { reduceMotion || clayPaused || petPaused }
    private var manualSteps: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-uitest") && ProcessInfo.processInfo.arguments.contains("-uitest-egg-steps")
        #else
        return false
        #endif
    }

    var body: some View {
        Stage { _ in MeadowLayer(horizon: 300) } content: { layout in
            TitleRibbon(title: phase == .revealed ? "欢迎 \(kind.name)！" : "神秘蛋孵化中")
                .position(layout.place(x: 422, y: 54))
            Group {
                if phase == .revealed {
                    PetView(kind: kind, mood: .cheer, size: 180, reactTo: .levelup, accessory: .noAccessory)
                        .transition(paused ? .identity : .scale(scale: 0.4, anchor: .bottom).combined(with: .opacity))
                } else if phase == .broken {
                    HStack(spacing: 22) {
                        shell.rotationEffect(.degrees(-25))
                        shell.rotationEffect(.degrees(25))
                    }
                } else {
                    PetView(kind: .egg, size: 174, accessory: .noAccessory, crack: phase.crack)
                        .rotationEffect(.degrees(paused ? 0 : phase.angle))
                }
            }
            .position(layout.place(x: 422, y: phase == .revealed ? 188 : 212))
            Text(phase.title).font(ClayFont.button).foregroundStyle(ClayColor.statText)
                .position(layout.place(x: 422, y: phase == .revealed ? 299 : 323))
                .accessibilityIdentifier("pet-egg-phase").accessibilityValue(String(phase.rawValue))
            if phase == .revealed {
                ClayButton(title: "带\(kind.name)回小屋", id: "pet-egg-done", action: onDone)
                    .position(x: layout.place(x: 422, y: 0).x,
                              y: min(layout.place(x: 0, y: 342).y, layout.size.height - layout.safeArea.bottom - 32))
            }
            #if DEBUG
            if manualSteps && phase != .revealed {
                ClayButton(title: "下一帧", style: .cream, id: "pet-egg-next", action: advance)
                    .stageAnchor(.bottomTrailing, in: layout, size: .init(width: 120, height: 52))
            }
            #endif
        }
        .environment(\.petAnimationsPaused, paused)
        .overlay { if phase == .revealed && !paused { ConfettiView(active: true).allowsHitTesting(false) } }
        .interactiveDismissDisabled()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pet-egg-screen")
        .task(id: paused) {
            if paused { phase = .revealed; return }
            guard !manualSteps else { return }
            // 单次有限动画；离开页面即取消。
            do {
                while phase != .revealed {
                    try await Task.sleep(for: .milliseconds(420))
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: 0.22)) { advance() }
                }
            } catch { }
        }
    }

    private var shell: some View {
        ClayGradient.egg.view.frame(width: 72, height: 66)
            .clipShape(Ellipse()).overlay { Image(systemName: "bolt.fill").foregroundStyle(ClayColor.Pet.crack) }
    }

    private func advance() { phase = EggHatchPhase(rawValue: phase.rawValue + 1) ?? .revealed }
}
