import SwiftUI

struct PetShopView: View {
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]
    var now: () -> Date = PetScreenClock.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.clayMotionPaused) private var clayPaused
    @Environment(\.petAnimationsPaused) private var petPaused
    @State private var processing = false
    @State private var showConfirmation = false
    @State private var request: AdoptionRequest?
    @State private var celebration: PetKind?
    @State private var hatched: PetKind?

    private struct AdoptionRequest { let pet: Pets.Pet; let id = UUID() }
    private var selected: Pets.Pet { Pets.petById(progressStore.selectedPetShopId) ?? Pets.pets[1] }
    private var status: PetAdoptionStatus { progressStore.canAdopt(selected.id) }
    private var slots: [Pets.Pet] { Pets.pets.filter { $0.id != PetState.starterId && $0.acquisition != .egg } }
    private var paused: Bool { reduceMotion || clayPaused || petPaused }

    var body: some View {
        Stage { layout in PetShopBackdrop(layout: layout) } content: { layout in
            ClayIconButton(icon: .back, id: "shell-back") { path.removeLast() }
                .stageAnchor(.topLeading, in: layout, size: .init(width: 48, height: 48))
            TitleRibbon(title: "宠物商店").position(layout.place(x: 202, y: 36))
            PetBalance(gems: progressStore.gems)
                .stageAnchor(.topTrailing, in: layout, size: .init(width: 112, height: 34))
            Text(status == .available ? "学习赚金币，带新伙伴回家吧！" : PetScreenCopy.adoptionTitle(selected, status: status, gems: progressStore.gems))
                .font(ClayFont.label).foregroundStyle(ClayColor.greenEdge)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(ClayColor.white.opacity(0.8), in: Capsule())
                .position(layout.place(x: 555, y: 76))
            showcase.position(layout.place(x: 174, y: 224))
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, pet in
                shelfPet(pet)
                    .position(layout.place(x: 400 + CGFloat(index % 3) * 160, y: index < 3 ? 143 : 259))
            }
            PetToolShelf(progressStore: progressStore, now: now)
                .frame(width: 490, height: 46)
                .position(x: layout.place(x: 565, y: 0).x,
                          y: min(layout.place(x: 0, y: 367).y, layout.size.height - layout.safeArea.bottom - 31))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pet-shop-screen")
        .alert(confirmationTitle, isPresented: $showConfirmation) {
            Button("再想想", role: .cancel) { request = nil; processing = false }
                .accessibilityIdentifier("pet-shop-cancel")
            Button("确认领养") { confirmAdoption() }
                .accessibilityIdentifier("pet-shop-confirm")
        } message: { Text("只使用学习获得的金币。") }
        .overlay {
            if let celebration {
                ZStack {
                    ClayColor.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 10) {
                        TitleRibbon(title: "欢迎 \(celebration.name)！")
                        PetView(kind: celebration, mood: .cheer, size: 140, reactTo: .levelup, accessory: .noAccessory)
                            .environment(\.petAnimationsPaused, paused)
                        ClayButton(title: "去小屋", id: "pet-shop-visit") { visit(celebration) }
                    }
                    if !paused { ConfettiView(active: true).allowsHitTesting(false) }
                }
            }
        }
        .fullScreenCover(item: $hatched) { kind in
            EggHatchView(kind: kind) { visit(kind) }
        }
    }

    private var confirmationTitle: String {
        guard let pet = request?.pet else { return "领养伙伴" }
        return "花 \(pet.price ?? 0) 金币\(pet.id == "pet_egg" ? "孵化神秘蛋" : "领养\(pet.name)")？"
    }

    private var showcase: some View {
        ZStack {
            PetPortrait(kind: PetKind(rawValue: selected.id) ?? .fox, size: 164,
                        unavailable: status == .insufficientLevel || status == .insufficientStreak)
                .overlay(alignment: .bottomTrailing) {
                    if status == .insufficientLevel || status == .insufficientStreak {
                        ClayIconView(icon: .lock).frame(width: 30, height: 30)
                    }
                }
                .accessibilityIdentifier("pet-shop-preview")
                .position(x: 142, y: 119)
            Text("\(selected.name) · \(PetScreenCopy.introduction(selected.id))")
                .font(ClayFont.button).foregroundStyle(ClayColor.ink).lineLimit(1).minimumScaleFactor(0.7)
                .frame(width: 284).position(x: 142, y: 220)
            Text(selected.skill).font(ClayFont.caption).foregroundStyle(ClayColor.greenEdge)
                .multilineTextAlignment(.center).frame(width: 280, height: 26)
                .position(x: 142, y: 242)
            Button(action: beginAdoption) {
                Text(processing ? "处理中…" : PetScreenCopy.adoptionTitle(selected, status: status, gems: progressStore.gems))
                    .font(ClayFont.largeButton)
                    .foregroundStyle(status == .available || status == .alreadyOwned ? ClayColor.white : ClayColor.statText)
                    .frame(width: 244, height: 44)
                    .claySurface(status == .available || status == .alreadyOwned ? .buttonOrange : .buttonCream,
                                 radius: ClayRadius.largeButton, edge: ClayColor.orangeDeep)
                    .clayHitTarget()
            }
                .buttonStyle(ClayPressStyle())
                .accessibilityIdentifier("pet-shop-adopt")
                .disabled(processing || !(status == .available || status == .alreadyOwned))
                .saturation(status == .available || status == .alreadyOwned ? 1 : 0)
                .accessibilityValue(String(describing: status))
                .position(x: 142, y: 279)
        }
        .frame(width: 284, height: 310)
        .environment(\.petAnimationsPaused, paused)
    }

    private func shelfPet(_ pet: Pets.Pet) -> some View {
        let state = progressStore.canAdopt(pet.id)
        let locked = state == .insufficientLevel || state == .insufficientStreak
        let active = selected.id == pet.id
        return Button {
            guard !processing else { return }
            progressStore.selectedPetShopId = pet.id
        } label: {
            VStack(spacing: 5) {
                PetPortrait(kind: PetKind(rawValue: pet.id) ?? .egg, size: 70, unavailable: locked)
                    .frame(height: 76)
                    .background { if active { Ellipse().fill(ClayColor.white.opacity(0.35)).frame(width: 125, height: 90) } }
                    .accessibilityHidden(true)
                HStack(spacing: 3) {
                    Text(pet.name)
                    if locked { ClayIconView(icon: .lock).frame(width: 12, height: 12) }
                    if pet.price ?? 0 > 0 { PetCoin(size: 13) }
                    Text(state == .alreadyOwned ? "已领养" : state == .soldOut ? "已孵完" :
                         pet.price ?? 0 > 0 ? "\(pet.price ?? 0)" : PetScreenCopy.condition(pet))
                }
                .font(ClayFont.label).foregroundStyle(active ? ClayColor.white : ClayColor.statText)
                .padding(.horizontal, 9).frame(height: 27)
                .background(active ? ClayColor.orange : ClayColor.white, in: Capsule())
                .clayShadow(.stat)
            }
            .frame(width: 150, height: 110)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).disabled(processing)
        .environment(\.petAnimationsPaused, true)
        .accessibilityLabel("\(pet.name)，\(state == .alreadyOwned ? "已领养" : PetScreenCopy.condition(pet))")
        .accessibilityValue(active ? "已选中" : "未选中")
        .accessibilityIdentifier("pet-shop-\(pet.id)")
    }

    private func beginAdoption() {
        guard !processing else { return }
        if status == .alreadyOwned, let kind = PetKind(rawValue: selected.id) { visit(kind); return }
        guard status == .available else { return }
        processing = true // 首次点击即锁住货架和按钮，确认框也不能重复创建。
        request = AdoptionRequest(pet: selected)
        showConfirmation = true
    }

    private func confirmAdoption() {
        guard let pending = request else { return }
        request = nil
        guard let id = progressStore.adopt(pending.pet.id, requestId: pending.id, now: now()),
              let kind = PetKind(rawValue: id) else { processing = false; return }
        HapticEngine.shared.success(); SFXEngine.shared.play(.purchase)
        if pending.pet.id == "pet_egg" { hatched = kind }
        else { celebration = kind }
    }

    private func visit(_ kind: PetKind) {
        guard progressStore.setActivePet(kind.rawValue) else { return }
        celebration = nil; hatched = nil; processing = false
        path.append(.petHome)
    }
}

/// 原 ShopView 的两件功能道具共用原接口和价格，移到宠物商店底部。
struct PetToolShelf: View {
    @ObservedObject var progressStore: ProgressStore
    var now: () -> Date = PetScreenClock.now
    var body: some View {
        HStack(spacing: 10) {
            Text("道具").font(ClayFont.button).foregroundStyle(ClayColor.statText)
            tool("连胜护盾", detail: "\(progressStore.streakFreezes)/\(Economy.maxFreezes)", cost: Economy.freezeCost,
                 icon: "shield.fill", id: "pet-shop-shield",
                 enabled: progressStore.streakFreezes < Economy.maxFreezes && progressStore.gems >= Economy.freezeCost) {
                progressStore.buyStreakFreeze()
            }
            tool("补满红心", detail: "\(progressStore.hearts)/\(ProgressStore.maxHearts)", cost: Economy.heartRefillCost,
                 icon: "heart.fill", id: "pet-shop-refill",
                 enabled: progressStore.hearts < ProgressStore.maxHearts && progressStore.gems >= Economy.heartRefillCost) {
                progressStore.buyHeartRefill(now: now())
            }
        }
    }

    private func tool(_ title: String, detail: String, cost: Int, icon: String, id: String,
                      enabled: Bool, action: @escaping () -> Bool) -> some View {
        Button {
            if action() { HapticEngine.shared.success(); SFXEngine.shared.play(.purchase) }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).foregroundStyle(ClayColor.petCoral)
                Text(title).font(ClayFont.label)
                Text(detail).font(ClayFont.level)
                PetCoin(size: 14)
                Text("\(cost)").font(ClayFont.number)
            }
            .foregroundStyle(ClayColor.statText).padding(.horizontal, 9)
            .frame(height: 40)
            .claySurface(.buttonCream, radius: ClayRadius.smallButton, edge: ClayColor.creamEdge)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).disabled(!enabled).opacity(enabled ? 1 : 0.55)
        .accessibilityLabel("\(title)，\(detail)，\(cost) 金币")
        .accessibilityIdentifier(id)
    }
}
