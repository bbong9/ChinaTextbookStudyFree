import SwiftUI

private struct ClayHitTarget: ViewModifier {
    @Environment(\.clayStageScale) private var scale
    func body(content: Content) -> some View {
        content
            .frame(minWidth: max(44, 44 / scale), minHeight: max(44, 44 / scale))
            .contentShape(Rectangle())
    }
}

struct ClayPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.offset(y: configuration.isPressed ? 2 : 0)
    }
}

extension View {
    func clayHitTarget() -> some View { modifier(ClayHitTarget()) }

    /// CSS inset 0 -depth 0 edge：仅底部可见的内阴影边。
    func claySurface(_ gradient: ClayGradient, radius: CGFloat, depth: CGFloat = 4,
                     edge: Color, shadow: ClayShadow = .panel) -> some View {
        background(gradient.view)
            .overlay(alignment: .bottom) { Rectangle().fill(edge).frame(height: depth) }
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .clayShadow(shadow)
    }
}

struct ClayIconButton: View {
    enum Size { case regular, small
        var side: CGFloat { self == .regular ? 48 : 40 }
    }
    let icon: ClayIcon
    var size: Size = .regular
    let id: String
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ClayIconView(icon: icon)
                .frame(width: icon == .back ? 30 : 26, height: icon == .back ? 30 : 26)
                .frame(width: size.side, height: size.side)
                .claySurface(.buttonCream, radius: size == .regular ? ClayRadius.button : ClayRadius.smallButton,
                             edge: ClayColor.creamEdge, shadow: .icon)
                .shadow(color: ClayColor.hex(0x966428).opacity(0.25), radius: 0, y: 3)
                .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel(label ?? icon.label)
        .accessibilityIdentifier(id)
    }
}

struct ClayButton: View {
    enum Style { case cream, orange }
    let title: String
    var style: Style = .orange
    var icon: ClayIcon? = nil
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).font(ClayFont.largeButton)
                if let icon { ClayIconView(icon: icon, color: foreground).frame(width: 18, height: 18) }
            }
            .foregroundStyle(foreground)
            .shadow(color: style == .orange ? ClayColor.creamText : .clear, radius: 0, y: 2)
            .padding(.horizontal, 24)
            .frame(height: 52)
            .claySurface(style == .cream ? .buttonCream : .buttonOrange, radius: ClayRadius.largeButton,
                         edge: style == .cream ? ClayColor.creamEdge : ClayColor.orangeDeep,
                         shadow: style == .cream ? .panel : .orange)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }
    private var foreground: Color { style == .cream ? ClayColor.creamText : ClayColor.white }
}

struct StepBar: View {
    let steps: [String]
    let current: Int
    let completed: Set<Int>
    var id = "clay-steps"
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(steps.indices, id: \.self) { index in
                Button { onTap(index) } label: {
                    Text(steps[index])
                        .font(ClayFont.step)
                        .foregroundStyle(index == current ? ClayColor.orangeBright :
                            completed.contains(index) ? ClayColor.completedText : ClayColor.white.opacity(0.4))
                        .shadow(color: index == current ? ClayColor.orangeBright.opacity(0.6) : .clear, radius: 6)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .bottom) {
                            if index == current {
                                Capsule().fill(ClayColor.orangeBright).frame(width: 20, height: 4).padding(.bottom, 3)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if completed.contains(index) {
                                Circle().fill(ClayColor.completed).frame(width: 9, height: 9)
                                    .background { Circle().fill(ClayColor.darkPill).padding(-2) }
                                    .padding(.top, 4).padding(.trailing, 3)
                            }
                        }
                        .clayHitTarget()
                }
                .buttonStyle(ClayPressStyle())
                .accessibilityLabel("第\(index + 1)步，\(steps[index])")
                .accessibilityValue(index == current ? "当前" : completed.contains(index) ? "已完成" : "未到")
                .accessibilityIdentifier("\(id)-\(index)")
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 48)
        .background(ClayColor.darkPill, in: RoundedRectangle(cornerRadius: ClayRadius.largeButton))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: ClayRadius.largeButton)
                .strokeBorder(ClayColor.white.opacity(0.08), lineWidth: 2)
                .mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center))
        }
        .shadow(color: ClayColor.black.opacity(0.15), radius: 5, y: 4)
    }
}

struct SayButton: View {
    var pinyin: String? = nil
    let id: String
    var label = "朗读"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                ClayIconView(icon: .speaker, color: ClayColor.white).frame(width: 20, height: 20)
                if let pinyin { Text(pinyin).font(ClayFont.say) }
            }
            .foregroundStyle(ClayColor.white)
            .padding(.leading, 8).padding(.trailing, pinyin == nil ? 8 : 12)
            .frame(height: 34)
            .claySurface(.buttonOrange, radius: 17, depth: 3, edge: ClayColor.orangeDeep,
                         shadow: ClayShadow(color: .clear, radius: 0, y: 0))
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel(pinyin.map { "\(label)，\($0)" } ?? label)
        .accessibilityIdentifier(id)
    }
}

struct GoButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var pausesAnimation = false
    let id: String
    let action: () -> Void
    private var motionPaused: Bool { reduceMotion || pausesAnimation }

    var body: some View {
        Button(action: action) {
            Group {
                if motionPaused {
                    face
                } else {
                    ClayGoPulse { face }
                }
            }
            .clayHitTarget()
            .transaction { transaction in
                if motionPaused { transaction.animation = nil; transaction.disablesAnimations = true }
            }
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel("开始闯关")
        .accessibilityValue(motionPaused ? "动态效果已减少" : "呼吸动画")
        .accessibilityIdentifier(id)
    }

    private var face: some View {
        VStack(spacing: 0) {
            ClayIconView(icon: .play, color: ClayColor.white).frame(width: 27, height: 27)
            Text("闯关").font(ClayFont.button).foregroundStyle(ClayColor.white)
                .shadow(color: ClayColor.creamText, radius: 0, y: 2)
        }
        .frame(width: 82, height: 82)
        .claySurface(.go, radius: 41, depth: 5, edge: ClayColor.hex(0xA03C00).opacity(0.3), shadow: .go)
        .overlay { Circle().strokeBorder(ClayColor.white, lineWidth: 4) }
    }
}

/// 减少动态效果时整个动画子树被移除，repeatForever 不会留在静止按钮上。
private struct ClayGoPulse<Content: View>: View {
    @State private var breathing = false
    @ViewBuilder let content: () -> Content
    var body: some View {
        content().scaleEffect(breathing ? 1.06 : 1).opacity(breathing ? 1 : 0.75)
            .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { breathing = true }
        }
    }
}
