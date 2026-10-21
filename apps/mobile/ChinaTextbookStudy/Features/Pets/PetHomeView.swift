import SwiftUI

struct PetHomeView: View {
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]
    var now: () -> Date = PetScreenClock.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.clayMotionPaused) private var clayPaused
    @Environment(\.petAnimationsPaused) private var petPaused
    @State private var dressing = false
    @State private var reactionKey = 0
    @State private var effect: CareEffect?
    @State private var effectProgress: CGFloat = 0
    @State private var message: String?

    private enum CareEffect { case feed, bathe, play }
    private var paused: Bool { reduceMotion || clayPaused || petPaused }
    private var active: Pets.Pet { Pets.petById(progressStore.activePet) ?? Pets.pets[0] }
    private var companions: [Pets.Pet] {
        Pets.pets.filter { progressStore.ownedPets.contains($0.id) && $0.id != "pet_egg" }
    }

    var body: some View {
        TimelineView(.periodic(from: .distantPast, by: 1)) { _ in
            let instant = now()
            let care = progressStore.careState(for: active.id, now: instant)
            Stage { layout in PetRoomBackdrop(layout: layout) } content: { layout in
                topBar(layout)
                nameTag.position(layout.place(x: 422, y: 48))
                SpeechBubble {
                    Text(message ?? PetScreenCopy.message(care: care, progress: progressStore.progress, now: instant))
                        .font(ClayFont.button).frame(width: 134, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                }
                .position(layout.place(x: 605, y: 142))
                .accessibilityIdentifier("pet-home-message")
                PetView(mood: PetCare.mood(for: care), size: 176,
                        reactTo: .correct, reactKey: reactionKey,
                        bloom: active.floweringLevel.map { Level.levelInfo(progressStore.progress.xp).level >= $0 } ?? false,
                        allowsTap: true)
                    .position(layout.place(x: 422, y: 210))
                    .environment(\.petAnimationsPaused, paused)
                    .accessibilityIdentifier("pet-home-pet")
                    .accessibilityLabel(active.name)
                ClayIconButton(icon: .left, size: .small, id: "pet-home-previous", label: "上一只宠物") { switchPet(-1) }
                    .position(layout.place(x: 302, y: 220)).disabled(companions.count < 2)
                ClayIconButton(icon: .right, size: .small, id: "pet-home-next", label: "下一只宠物") { switchPet(1) }
                    .position(layout.place(x: 542, y: 220)).disabled(companions.count < 2)
                stats(care).frame(width: 190).position(layout.place(x: 135, y: 308))
                actions(care, instant: instant).position(layout.place(x: 704, y: 311))
                companionStrip.frame(width: 248, height: 48)
                    .position(x: layout.place(x: 422, y: 0).x,
                              y: min(layout.place(x: 0, y: 363).y, layout.size.height - layout.safeArea.bottom - 32))
                careEffect.position(layout.place(x: 422, y: 222))
            }
            .simultaneousGesture(DragGesture(minimumDistance: 45).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 60 else { return }
                switchPet(value.translation.width < 0 ? 1 : -1)
            })
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pet-home-screen")
        .sheet(isPresented: $dressing) { PetAccessoryDrawer(progressStore: progressStore) }
        .onChange(of: progressStore.activePet) { _, _ in message = nil; effect = nil }
        .task(id: reactionKey) {
            guard effect != nil else { return }
            if !paused { withAnimation(.easeInOut(duration: 0.9)) { effectProgress = 1 } }
            do { try await Task.sleep(for: .milliseconds(1100)) } catch { return }
            effect = nil
            message = nil
        }
    }

    private func topBar(_ layout: StageLayout) -> some View {
        Group {
            HStack(spacing: 12) {
                ClayIconButton(icon: .back, id: "shell-back") { path.removeLast() }
                PetBalance(gems: progressStore.gems)
            }
            .stageAnchor(.topLeading, in: layout, size: .init(width: 164, height: 48))
            HStack(spacing: 10) {
                destinationButton("图鉴 \(PetScreenCopy.collectionCount(progressStore.ownedPets))/\(Pets.pets.count)", icon: "list.bullet.clipboard.fill", id: "pet-home-family") { path.append(.petFamily) }
                destinationButton("宠物店", icon: "storefront.fill", id: "pet-home-shop") { path.append(.petShop) }
            }
            .stageAnchor(.topTrailing, in: layout, size: .init(width: 148, height: 54))
        }
    }

    private func destinationButton(_ title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(ClayFont.happy(size: 25)).foregroundStyle(ClayColor.orange)
                Text(title).font(ClayFont.label).foregroundStyle(ClayColor.statText)
            }
            .frame(width: 68, height: 54).clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).accessibilityLabel(title).accessibilityIdentifier(id)
    }

    private var nameTag: some View {
        let level = Level.levelInfo(progressStore.progress.xp)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 10) {
                Text(active.name).font(ClayFont.happy(size: 24))
                Text("Lv\(level.level)").font(ClayFont.number).foregroundStyle(ClayColor.white)
                    .padding(.horizontal, 8).padding(.vertical, 2).background(ClayColor.petClean, in: Capsule())
            }
            GeometryReader { geometry in
                Capsule().fill(ClayColor.petTrack)
                Capsule().fill(ClayColor.completed)
                    .frame(width: geometry.size.width * CGFloat(level.xpIntoLevel) / CGFloat(level.xpForNextLevel))
            }.frame(height: 9)
            Text(PetScreenCopy.growth(active, xp: progressStore.progress.xp)).font(ClayFont.caption).foregroundStyle(ClayColor.statText)
        }
        .foregroundStyle(ClayColor.ink).padding(.horizontal, 14).padding(.vertical, 9)
        .frame(width: 224).background(ClayColor.white.opacity(0.94), in: RoundedRectangle(cornerRadius: ClayRadius.bubble))
        .clayShadow(.panel)
        .accessibilityIdentifier("pet-home-name")
    }

    private func stats(_ care: PetCareState) -> some View {
        VStack(spacing: 9) {
            stateBar("开心", value: care.happy, icon: "heart.fill", color: ClayColor.petHappy, id: "happy")
            stateBar("饱饱", value: care.fullness, icon: "star.circle.fill", color: ClayColor.petFull, id: "fullness")
            stateBar("干净", value: care.clean, icon: "drop.fill", color: ClayColor.petClean, id: "clean")
        }
        .padding(14).background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.bubble))
    }

    private func stateBar(_ name: String, value: Double, icon: String, color: Color, id: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 16)
            Text(name).font(ClayFont.button)
            GeometryReader { geometry in
                Capsule().fill(ClayColor.petTrack)
                Capsule().fill(color).frame(width: geometry.size.width * min(1, max(0, value / 100)))
            }.frame(height: 12)
        }
        .foregroundStyle(ClayColor.ink).frame(height: 19)
        .accessibilityElement(children: .ignore).accessibilityLabel(name)
        .accessibilityValue(String(Int(value.rounded())))
        .accessibilityIdentifier("pet-home-\(id)")
    }

    private func actions(_ care: PetCareState, instant: Date) -> some View {
        let bath = PetScreenCopy.remaining(last: care.lastBathAt, cooldown: PetCare.bathCooldown, now: instant)
        let play = PetScreenCopy.remaining(last: care.lastPlayAt, cooldown: PetCare.playCooldown, now: instant)
        return VStack(spacing: 9) {
            HStack(spacing: 9) {
                actionButton("喂食", icon: "🍪", detail: "×\(progressStore.petTreats)", id: "feed", enabled: progressStore.petTreats > 0 && effect == nil) {
                    if progressStore.feed(now: now()) { animate(.feed, message: "好香的饼干，谢谢你！") }
                }
                actionButton("洗澡", icon: "🫧", detail: bath > 0 ? PetScreenCopy.countdown(bath) : nil, id: "bathe", enabled: bath == 0 && effect == nil) {
                    if progressStore.bathe(now: now()) { animate(.bathe, message: "香喷喷的，谢谢你照顾我！") }
                }
            }
            HStack(spacing: 9) {
                actionButton("玩耍", icon: "⚽", detail: play > 0 ? PetScreenCopy.countdown(play) : nil, id: "play", enabled: play == 0 && effect == nil) {
                    if progressStore.play(now: now()) { animate(.play, message: "和你玩球最开心啦！") }
                }
                actionButton("装扮", icon: "🎀", detail: nil, id: "dress", enabled: effect == nil) { dressing = true }
            }
            if progressStore.petTreats == 0 {
                Text(progressStore.feedUnavailableReason ?? "").font(ClayFont.caption).foregroundStyle(ClayColor.statText)
            }
        }
        .frame(width: 210)
    }

    private func actionButton(_ title: String, icon: String, detail: String?, id: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 5) { Text(icon); Text(title) }.font(ClayFont.button)
                if let detail { Text(detail).font(ClayFont.caption).monospacedDigit() }
            }
            .foregroundStyle(ClayColor.statText).frame(width: 100, height: 51)
            .claySurface(.buttonCream, radius: ClayRadius.largeButton, edge: ClayColor.creamEdge)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).disabled(!enabled).opacity(enabled ? 1 : 0.65)
        .accessibilityLabel(title).accessibilityValue(detail ?? "可使用")
        .accessibilityIdentifier("pet-home-\(id)")
    }

    private var companionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(companions, id: \.id) { pet in
                    Button {
                        _ = progressStore.setActivePet(pet.id)
                    } label: {
                        HStack(spacing: 1) {
                            PetPortrait(kind: PetKind(rawValue: pet.id) ?? .mituan, size: 27)
                            Text(pet.name).font(ClayFont.caption)
                        }
                        .foregroundStyle(ClayColor.statText).padding(.horizontal, 6).frame(height: 44)
                        .background(ClayColor.white.opacity(active.id == pet.id ? 0.95 : 0.6), in: Capsule())
                        .clayHitTarget()
                    }
                    .buttonStyle(ClayPressStyle())
                    .accessibilityLabel("切换出战为\(pet.name)")
                    .accessibilityValue(active.id == pet.id ? "出战中" : "未出战")
                    .accessibilityIdentifier("pet-home-switch-\(pet.id)")
                }
            }
        }
        .environment(\.petAnimationsPaused, true)
        .accessibilityIdentifier("pet-home-companions")
    }

    @ViewBuilder private var careEffect: some View {
        if let effect, !paused {
            ZStack {
                switch effect {
                case .feed:
                    Text("🍪").font(ClayFont.happy(size: 30))
                        .offset(x: 180 * (1 - effectProgress), y: 65 * (1 - effectProgress))
                        .scaleEffect(1 - effectProgress * 0.7).opacity(1 - Double(effectProgress) * 0.6)
                case .bathe:
                    ForEach(0..<7) { index in
                        Circle().fill(ClayColor.white.opacity(0.6))
                            .overlay { Circle().strokeBorder(ClayColor.petBowl, lineWidth: 2) }
                            .frame(width: CGFloat(15 + index * 3), height: CGFloat(15 + index * 3))
                            .offset(x: CGFloat(index - 3) * 24, y: 70 - effectProgress * CGFloat(70 + index * 12))
                            .opacity(1 - Double(effectProgress) * 0.5)
                    }
                case .play:
                    Text("⚽").font(ClayFont.happy(size: 32))
                        .offset(x: -130 + effectProgress * 75, y: 75 - sin(effectProgress * .pi * 2) * 40)
                }
            }
            .allowsHitTesting(false).accessibilityHidden(true)
        }
    }

    private func animate(_ value: CareEffect, message text: String) {
        effectProgress = 0; effect = value; message = text; reactionKey += 1
        HapticEngine.shared.success()
    }

    private func switchPet(_ direction: Int) {
        guard companions.count > 1, let index = companions.firstIndex(where: { $0.id == active.id }) else { return }
        _ = progressStore.setActivePet(companions[(index + direction + companions.count) % companions.count].id)
    }
}

struct PetAccessoryDrawer: View {
    @ObservedObject var progressStore: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var preview: CosmeticItem?
    @State private var showConfirmation = false
    private var equipped: String { progressStore.petAccessory[progressStore.activePet] ?? PetAccessory.noAccessory.rawValue }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("给\(Pets.petById(progressStore.activePet)?.name ?? "伙伴")装扮").font(ClayFont.title)
                PetBalance(gems: progressStore.gems)
                Spacer()
                ClayIconButton(icon: .close, id: "pet-dress-close", label: "关闭装扮") { dismiss() }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
                    ForEach(Cosmetics.mascotSkins) { item in accessory(item) }
                }
                .padding(4)
            }.accessibilityIdentifier("pet-dress-scroll")
        }
        .padding(20).foregroundStyle(ClayColor.ink).background(ClayColor.creamTop)
        .presentationDetents([.large]).interactiveDismissDisabled(false)
        .alert("购买配饰", isPresented: $showConfirmation, presenting: preview) { item in
            Button("再想想", role: .cancel) { preview = nil }.accessibilityIdentifier("cosmetic-cancel-buy")
            Button("确认购买") {
                preview = nil
                if progressStore.buyCosmetic(item) {
                    _ = progressStore.setAccessory(item.id, for: progressStore.activePet)
                    HapticEngine.shared.success(); SFXEngine.shared.play(.purchase)
                }
            }
            .disabled(progressStore.gems < item.cost)
            .accessibilityIdentifier("cosmetic-confirm-buy")
        } message: { item in
            if progressStore.gems < item.cost {
                Text("还差 \(item.cost - progressStore.gems) 金币，去学习赚金币吧！")
            } else {
                Text("花 \(item.cost) 金币购买\(item.name)？")
            }
        }
    }

    private func accessory(_ item: CosmeticItem) -> some View {
        let isDefault = item.id == PetAccessory.noAccessory.rawValue
        let owned = progressStore.isOwned(item.id)
        let current = equipped == item.id
        return Button {
            if owned { _ = progressStore.setAccessory(isDefault ? nil : item.id, for: progressStore.activePet) }
            else { preview = item; showConfirmation = true }
        } label: {
            VStack(spacing: 4) {
                PetView(size: 65, accessory: PetAccessory(rawValue: item.id))
                Text(isDefault ? "无配饰" : item.name).font(ClayFont.button)
                HStack(spacing: 4) {
                    if !owned { PetCoin(size: 14) }
                    Text(current ? "使用中" : owned ? "点击佩戴" : "\(item.cost) 金币").font(ClayFont.caption)
                }
            }
            .foregroundStyle(ClayColor.statText).frame(maxWidth: .infinity).padding(8)
            .background(current ? ClayColor.petSkirting : ClayColor.white, in: RoundedRectangle(cornerRadius: ClayRadius.largeButton))
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).environment(\.petAnimationsPaused, true)
        .accessibilityIdentifier("cosmetic-\(item.id)")
        .accessibilityLabel("\(isDefault ? "无配饰" : item.name)，\(current ? "使用中" : owned ? "已拥有" : "\(item.cost) 金币")")
    }
}
