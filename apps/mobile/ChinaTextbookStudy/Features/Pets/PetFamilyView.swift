import SwiftUI

struct PetFamilyView: View {
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]

    var body: some View {
        Stage { _ in MeadowLayer(horizon: 230) } content: { layout in
            FlowerView(x: layout.place(x: 30, y: 330).x, y: layout.place(x: 30, y: 330).y)
            TuftView(x: layout.place(x: 790, y: 370).x, y: layout.place(x: 790, y: 370).y)
            ClayIconButton(icon: .back, id: "shell-back") { path.removeLast() }
                .stageAnchor(.topLeading, in: layout, size: .init(width: 48, height: 48))
            TitleRibbon(title: "宠物家族 · 10 位小伙伴")
                .position(layout.place(x: 422, y: 36))
            Text("一起学习，一起长大 · 图鉴 \(PetScreenCopy.collectionCount(progressStore.ownedPets))/\(Pets.pets.count) · 左右滑动发现更多")
                .font(ClayFont.label).foregroundStyle(ClayColor.greenEdge)
                .padding(.horizontal, 20).padding(.vertical, 7)
                .background(ClayColor.white.opacity(0.8), in: Capsule())
                .position(layout.place(x: 422, y: 86))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Pets.pets, id: \.id) { pet in familyMember(pet) }
                }
                .padding(.horizontal, 8)
            }
            .frame(width: max(0, layout.size.width - layout.safeArea.leading - layout.safeArea.trailing - 24), height: 270)
            .position(x: layout.size.width / 2, y: layout.place(x: 0, y: 244).y)
            .accessibilityIdentifier("pet-family-scroll")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pet-family-screen")
    }

    private func familyMember(_ pet: Pets.Pet) -> some View {
        let owned = progressStore.ownedPets.contains(pet.id)
        let discoveredEgg = pet.id == "pet_egg" && PetScreenCopy.discoveredEgg(progressStore.ownedPets)
        let unknown = pet.acquisition == .egg && !owned
        return Button {
            if owned {
                guard progressStore.setActivePet(pet.id) else { return }
                path.append(.petHome)
            } else {
                progressStore.selectedPetShopId = unknown ? "pet_egg" : pet.id
                path.append(.petShop)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    Ellipse().fill(ClayColor.petGrassShadow.opacity(0.25)).frame(width: 104, height: 24).offset(y: 5)
                    ClayGradient.stone.view.clipShape(Ellipse()).frame(width: 98, height: 22)
                    PetPortrait(kind: PetKind(rawValue: pet.id) ?? .egg, size: 94,
                                unavailable: !owned && !discoveredEgg, unknownEgg: unknown).padding(.bottom, 6)
                        .accessibilityHidden(true)
                }
                .frame(height: 146)
                OutlinedLabel(text: unknown ? "神秘伙伴" : pet.name, font: ClayFont.happy(size: 20))
                Text(owned ? "\(progressStore.activePet == pet.id ? "出战中" : "已结识 · 去小屋")" : discoveredEgg ? "已发现 · 去孵化" : PetScreenCopy.condition(pet))
                    .font(ClayFont.label).foregroundStyle(ClayColor.statText)
                    .padding(.horizontal, 7).frame(height: 25)
                    .background(ClayColor.white, in: Capsule())
                Text(unknown ? "孵化神秘蛋，认识新朋友" : pet.skill)
                    .font(ClayFont.caption).foregroundStyle(ClayColor.greenEdge)
                    .multilineTextAlignment(.center).lineLimit(3)
                    .frame(height: 48, alignment: .top)
                    .padding(.horizontal, 4)
            }
            .frame(width: 108, height: 256)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle())
        .environment(\.petAnimationsPaused, true)
        .accessibilityLabel("\(unknown ? "神秘伙伴" : pet.name)，\(owned ? "已拥有，进入小屋" : PetScreenCopy.condition(pet))")
        .accessibilityIdentifier("pet-family-\(pet.id)")
    }
}
