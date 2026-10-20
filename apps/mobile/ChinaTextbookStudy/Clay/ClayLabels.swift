import SwiftUI

struct OutlinedLabel: View {
    let text: String
    var font: Font = ClayFont.label
    // CSS 的八方向偏移，斜向为 1.5，水平/垂直为 2。
    private let offsets: [CGSize] = [CGSize(width: 0, height: 2), CGSize(width: 2, height: 0),
        CGSize(width: -2, height: 0), CGSize(width: 0, height: -2),
        CGSize(width: 1.5, height: 1.5), CGSize(width: -1.5, height: 1.5),
        CGSize(width: 1.5, height: -1.5), CGSize(width: -1.5, height: -1.5)]

    var body: some View {
        ZStack {
            ForEach(offsets.indices, id: \.self) { index in
                Text(text).foregroundStyle(ClayColor.outline).offset(offsets[index])
                    .accessibilityHidden(true)
            }
            Text(text).foregroundStyle(ClayColor.white)
        }
        .font(font)
        .fixedSize()
        .compositingGroup()
        .shadow(color: ClayColor.black.opacity(0.2), radius: 2, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

struct StatPill: View {
    let icon: ClayIcon
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            ClayIconView(icon: icon).frame(width: 24, height: 24)
            Text(text).font(ClayFont.number).foregroundStyle(ClayColor.statText)
        }
        .padding(.leading, 5).padding(.trailing, 14)
        .frame(height: 34)
        .background(ClayColor.white.opacity(0.92))
        .overlay(alignment: .bottom) { Rectangle().fill(ClayColor.black.opacity(0.06)).frame(height: 3) }
        .clipShape(Capsule())
        .clayShadow(.stat)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(icon.label)，\(text)")
    }
}

struct TitleRibbon: View {
    enum Color { case orange, green, blue }
    let title: String
    var color: Color = .orange

    private var gradient: ClayGradient {
        switch color { case .orange: return .buttonOrange; case .green: return .ribbonGreen; case .blue: return .ribbonBlue }
    }
    private var edge: SwiftUI.Color {
        switch color { case .orange: return ClayColor.orangeDeep; case .green: return ClayColor.greenEdge; case .blue: return ClayColor.blueEdge }
    }
    var body: some View {
        Text(title)
            .font(ClayFont.ribbon)
            .foregroundStyle(ClayColor.white)
            .shadow(color: color == .orange ? ClayColor.creamText : edge, radius: 0, y: 2)
            .padding(.horizontal, 24)
            .frame(height: 44)
            .claySurface(gradient, radius: ClayRadius.ribbon, edge: edge,
                         shadow: color == .blue ? .blueRibbon : .panel)
    }
}

struct SpeechBubble<Content: View>: View {
    enum Tail { case left, right }
    var tail: Tail = .left
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .font(ClayFont.body)
            .foregroundStyle(ClayColor.ink)
            .padding(.vertical, 10).padding(.horizontal, 14)
            .background(ClayColor.white, in: RoundedRectangle(cornerRadius: ClayRadius.bubble))
            .overlay(alignment: tail == .left ? .leading : .trailing) {
                BubbleTail(right: tail == .right).fill(ClayColor.white)
                    .frame(width: 12, height: 16).offset(x: tail == .left ? -10 : 10)
            }
            .clayShadow(.bubble)
    }
}

private struct BubbleTail: Shape {
    var right: Bool
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: right ? 0 : rect.maxX, y: 0))
            p.addLine(to: CGPoint(x: right ? rect.maxX : 0, y: rect.midY))
            p.addLine(to: CGPoint(x: right ? 0 : rect.maxX, y: rect.maxY)); p.closeSubpath()
        }
    }
}

struct AvatarBadge<Content: View>: View {
    let level: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(width: 52, height: 52)
            .background(ClayGradient.avatar.view)
            .clipShape(Circle())
            .padding(4)
            .background(ClayColor.avatarBorder, in: Circle())
            .compositingGroup()
            .shadow(color: ClayColor.black.opacity(0.2), radius: 5, y: 4)
            .overlay(alignment: .bottomTrailing) {
                Text("Lv\(level)").font(ClayFont.level).foregroundStyle(ClayColor.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(ClayGradient.level.view)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(ClayColor.white, lineWidth: 2) }
                    .offset(x: 8, y: 6)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("头像，等级\(level)")
    }
}
