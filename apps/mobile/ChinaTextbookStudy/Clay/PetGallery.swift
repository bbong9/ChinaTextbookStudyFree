#if DEBUG
import SwiftUI

/// RD-04 只在现有预览页增加这一页，不改变路由与屏幕方向。
struct PetGallery: View {
    @State private var section = 0
    @State private var reaction: MascotReaction?
    @State private var reactionKey = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.petAnimationsPaused) private var paused

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(Array(["表情与形态", "配饰", "反应"].enumerated()), id: \.offset) { index, title in
                    ClayButton(title: title, style: section == index ? .orange : .cream,
                               id: "pet-section-\(index)") { section = index }
                }
            }
            if section == 2 {
                reactions
            } else {
                ScrollView(.vertical) {
                    if section == 0 {
                        PetMoodGrid()
                        PetVariantStrip()
                    } else {
                        PetAccessoryGrid()
                    }
                }
                .accessibilityIdentifier("pet-gallery-scroll")
            }
        }
        .foregroundStyle(ClayColor.ink)
    }

    private var reactions: some View {
        HStack(spacing: 28) {
            PetView(mood: reaction == .wrong ? .sad : .wave, size: 128,
                    reactTo: reaction, reactKey: reactionKey, allowsTap: true)
                .accessibilityIdentifier("pet-reaction-preview")
                .accessibilityHint("点击米团也会跳一下")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach([MascotReaction.correct, .wrong, .levelup], id: \.self) { value in
                    ClayButton(title: value.petLabel, style: .cream, id: "pet-react-\(value.rawValue)") {
                        reaction = value
                        reactionKey += 1
                    }
                }
                VStack(spacing: 4) {
                    Text("点击米团也会跳一下").font(ClayFont.caption)
                    Text(reduceMotion || paused ? "动态效果已减少" : "呼吸 · 眨眼 · 挥手")
                        .font(ClayFont.caption)
                        .accessibilityIdentifier("pet-motion-status")
                        .accessibilityValue("\(reaction?.rawValue ?? "none"),\(reactionKey)")
                }
            }
            .frame(width: 450)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PetMoodGrid: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("伙伴").frame(width: 64)
                ForEach(MascotMood.petMoods, id: \.self) { mood in
                    Text(mood.petLabel).frame(width: 77)
                }
            }
            .font(ClayFont.caption)
            ForEach(PetKind.allCases) { kind in
                HStack(spacing: 0) {
                    Text(kind.name).font(ClayFont.caption).frame(width: 64)
                    ForEach(MascotMood.petMoods, id: \.self) { mood in
                        PetView(kind: kind, mood: mood, size: 70, accessory: PetAccessory.noAccessory)
                            .frame(width: 77, height: 83)
                            .accessibilityIdentifier("pet-sample-\(kind.artKey)-\(mood.rawValue)")
                    }
                }
            }
        }
        .padding(8)
        .background(ClayGradient.buttonCream.view)
        .clipShape(RoundedRectangle(cornerRadius: ClayRadius.smallButton))
        .environment(\.petAnimationsPaused, true)
    }
}

struct PetVariantStrip: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                PetView(kind: .mituan, size: 88, accessory: PetAccessory.noAccessory)
                Text("米团 · 新芽")
            }
            VStack {
                PetView(kind: .mituan, size: 88, accessory: PetAccessory.noAccessory, bloom: true)
                Text("米团 · 开花")
            }
            ForEach(0..<4) { crack in
                VStack {
                    PetView(kind: .egg, size: 88, accessory: PetAccessory.noAccessory, crack: crack)
                    Text("裂纹 \(crack)")
                }
            }
        }
        .font(ClayFont.caption)
        .padding(12)
        .background(ClayGradient.buttonCream.view)
        .clipShape(RoundedRectangle(cornerRadius: ClayRadius.smallButton))
        .environment(\.petAnimationsPaused, true)
        .accessibilityIdentifier("pet-variants")
    }
}

struct PetAccessoryGrid: View {
    static let kinds: [PetKind] = [.mituan, .fox, .penguin]
    var body: some View {
        VStack(spacing: 8) {
            ForEach(PetAccessory.decorations) { accessory in
                HStack(spacing: 20) {
                    Text(accessory.name).font(ClayFont.body).frame(width: 110)
                    ForEach(Self.kinds) { kind in
                        VStack(spacing: 0) {
                            PetView(kind: kind, size: 120, accessory: accessory)
                                .accessibilityIdentifier("pet-accessory-\(kind.artKey)-\(accessory.rawValue)")
                            Text(kind.name).font(ClayFont.caption)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(ClayGradient.buttonCream.view)
        .clipShape(RoundedRectangle(cornerRadius: ClayRadius.smallButton))
        .environment(\.petAnimationsPaused, true)
    }
}

extension MascotReaction {
    var petLabel: String {
        switch self {
        case .correct: return "答对 · 跳一下"
        case .wrong: return "答错 · 轻摇"
        case .levelup: return "升级 · 跳转一圈"
        }
    }
}
#endif
