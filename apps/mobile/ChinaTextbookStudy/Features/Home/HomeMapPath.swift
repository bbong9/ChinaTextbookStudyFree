import SwiftUI

struct HomeMapPath: View {
    let layout: HomeMapLayout
    let stage: StageLayout
    var onTap: (PathMapNode) -> Void
    var onGuideTap: (Int) -> Void
    var onJumpTap: (Int) -> Void
    var onPetHome: () -> Void = {}
    var onReadingRoom: () -> Void = {}
    var onMath: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.petEnvironment) private var pet
    @State private var offset: CGFloat = 0
    @State private var selected: HomeMapLayout.Entry?
    @State private var selectedUnit: HomeMapLayout.Unit?
    @State private var lockedHint: String?
    @State private var shake = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            HomeMapHorizon(offset: offset, reduceMotion: reduceMotion, size: stage.size)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(layout.units) { unit in
                            unitScene(unit)
                                .frame(width: unit.width, height: stage.size.height)
                        }
                    }
                    .frame(height: stage.size.height)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(key: HomeMapOffsetKey.self,
                                value: geometry.frame(in: .named("home-map-viewport")).minX)
                        }
                    }
                    // 定位锚点很轻，始终存在；画面仍按单元懒加载，远处当前节点也能直达。
                    .overlay(alignment: .topLeading) {
                        ForEach(layout.units) { unit in
                            ForEach(unit.entries) { entry in
                                Color.clear.frame(width: 1, height: 1)
                                    .position(x: unit.origin + entry.point.x, y: 1)
                                    .id(entry.id)
                            }
                        }
                    }
                }
                .coordinateSpace(name: "home-map-viewport")
                .accessibilityIdentifier("home-map-scroll")
                .accessibilityValue(reduceMotion ? "静态场景" : "分层视差")
                .onPreferenceChange(HomeMapOffsetKey.self) { value in
                    offset = value
                    if selected != nil { selected = nil }
                    if selectedUnit != nil { selectedUnit = nil }
                }
                .onAppear { locate(proxy, animated: false) }
                .onChange(of: layout.current?.id) { _, _ in locate(proxy, animated: true) }
                .onChange(of: stage.size.width) { _, _ in locate(proxy, animated: false) }
                .overlay(alignment: .trailing) {
                    if !HomeMapLayout.currentVisible(x: layout.currentX, offset: offset, viewport: stage.size.width) {
                        Button { locate(proxy, animated: true) } label: {
                            Label("回到当前", systemImage: "location.fill")
                                .font(ClayFont.label).foregroundStyle(ClayColor.ink)
                                .padding(.horizontal, 12)
                                .frame(minHeight: stage.minimumTapDimension)
                                .background(ClayGradient.buttonCream.view, in: Capsule())
                        }
                        .buttonStyle(ClayPressStyle())
                        .accessibilityLabel("回到当前关卡")
                        .accessibilityIdentifier("back-to-current")
                        .padding(.trailing, stage.safeArea.trailing + 12)
                    }
                }
            }
            if let selected {
                startPopup(selected)
                    .position(x: popupX(selected), y: stage.size.height - 260)
            }
            if let unit = selectedUnit {
                unitPopup(unit)
                    .position(x: min(stage.size.width - 140, max(140, unit.origin + 170 + offset)),
                              y: stage.size.height - 225)
            }
            if let hint = lockedHint {
                SpeechBubble {
                    Text("\(pet.kind.name)：\(hint)").font(ClayFont.caption)
                }
                .frame(maxWidth: 280)
                .position(x: stage.size.width / 2, y: stage.size.height - 285)
                .accessibilityIdentifier("map-locked-hint")
                .allowsHitTesting(false)
            }
        }
        .clipped()
    }

    private func locate(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let current = layout.current else { return }
        let move = { proxy.scrollTo(current.id, anchor: UnitPoint(x: 0.4, y: 0.5)) }
        if animated && !reduceMotion { withAnimation(.easeInOut(duration: 0.35), move) }
        else { move() }
    }

    private func popupX(_ entry: HomeMapLayout.Entry) -> CGFloat {
        let origin = layout.units.first { $0.number == entry.node.unitNumber }?.origin ?? 0
        return min(stage.size.width - 150 - stage.safeArea.trailing,
                   max(150 + stage.safeArea.leading, origin + entry.point.x + offset))
    }

    private func unitScene(_ unit: HomeMapLayout.Unit) -> some View {
        let localScroll = max(-unit.width, min(unit.width, -offset - unit.origin))
        let middleShift = HomeMapLayout.parallaxCorrection(offset: localScroll, rate: 0.6, reduceMotion: reduceMotion)
        let foregroundShift = HomeMapLayout.parallaxCorrection(offset: localScroll, rate: 1.1, reduceMotion: reduceMotion)
        return ZStack(alignment: .topLeading) {
            HomeMapMiddle(unit: unit.number, width: unit.width).equatable()
                .offset(x: middleShift)
            if unit.id == layout.units.first?.id {
                landmarks.offset(x: middleShift)
            }
            HomeMapForeground(width: unit.width).offset(x: foregroundShift)
            PathRoad(points: unit.road).drawingGroup()
            ForEach(unit.entries) { entry in nodeButton(entry) }
            unitSign(unit)
            if let current = layout.current, current.node.status == .current,
               current.node.unitNumber == unit.number {
                PetView(size: 70, reactTo: shake > 0 ? .wrong : nil, reactKey: shake)
                    .clayMotion(.bob)
                    .position(x: current.point.x, y: current.point.y - 78)
                    .accessibilityIdentifier("map-current-pet")
                    .allowsHitTesting(false)
            }
        }
        .frame(width: unit.width, height: 390)
        .offset(y: stage.size.height - 390)
    }

    private var landmarks: some View {
        ZStack(alignment: .topLeading) {
            HomeMapTree()
            MushroomHouseView(x: 276, y: 216, scale: 0.7)
            Canvas { context, _ in
                context.fill(Path(roundedRect: CGRect(x: 560, y: 176, width: 284, height: 4), cornerRadius: 2),
                             with: .color(ClayColor.rail))
            }
            TrainView(x: 812, y: 176, scale: 0.4, cars: [.init(), .init(gradient: .green2)])
            landmark("宠物小屋", id: "landmark-pet-home", at: CGPoint(x: 276, y: 162), width: 136, height: 126, action: onPetHome)
            landmark("课外书屋", id: "landmark-reading-room", at: CGPoint(x: 54, y: 258), width: 64, height: 80, action: onReadingRoom)
            landmark("数学小火车", id: "landmark-math", at: CGPoint(x: 718, y: 150), width: 230, height: 72, action: onMath)
        }.frame(width: 844, height: 390)
    }

    private func landmark(_ title: String, id: String, at point: CGPoint,
                          width: CGFloat, height: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) { Color.clear.frame(width: width, height: max(stage.minimumTapDimension, height)) }
            .buttonStyle(.plain).contentShape(Rectangle())
            .accessibilityLabel(title).accessibilityIdentifier(id).position(point)
    }

    private func nodeButton(_ entry: HomeMapLayout.Entry) -> some View {
        let node = entry.node
        return Button {
            selectedUnit = nil
            if node.status == .locked {
                HapticEngine.shared.wrong()
                shake += 1
                let hint = node.kind == .exam ? "完成本单元全部课程，就能开启单元挑战啦" : "先完成前面的课程再解锁哦"
                lockedHint = hint
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.5))
                    if lockedHint == hint { lockedHint = nil }
                }
            } else if node.kind == .chest {
                HapticEngine.shared.tap()
                if !node.chestClaimed { SFXEngine.shared.play(.tap); onTap(node) }
            } else {
                HapticEngine.shared.tap(); SFXEngine.shared.play(.tap)
                selected = selected?.id == entry.id ? nil : entry
            }
        } label: {
            ZStack(alignment: .topLeading) {
                if node.kind == .chest {
                    GiftView(x: 38, y: 65, scale: 0.85).opacity(node.chestClaimed ? 0.45 : 1)
                    Text("宝箱").font(ClayFont.label).foregroundStyle(ClayColor.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(ClayGradient.blue.view, in: Capsule()).position(x: 38, y: 2)
                } else {
                    CharCube(x: 38, y: 60, label: entry.label(),
                             state: node.kind == .exam ? .game : cubeState(node.status), stars: node.stars)
                    if node.kind == .exam {
                        Text("挑战").font(ClayFont.label).foregroundStyle(ClayColor.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(ClayColor.gameBadge, in: Capsule()).position(x: 38, y: 1)
                        if node.conquered {
                            Image(systemName: "trophy.fill").font(ClayFont.label).foregroundStyle(ClayColor.coinEdge)
                                .position(x: 58, y: 20)
                        }
                    }
                }
            }
            .frame(width: max(62, stage.minimumTapDimension), height: max(80, stage.minimumTapDimension))
            .contentShape(Rectangle())
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(node.kind == .chest ? "chest-node-\(node.id)" : node.kind == .exam ? "exam-node-\(node.id)" : "lesson-row-\(node.id)")
        .accessibilityLabel(node.kind == .chest
            ? "宝箱, \(node.status == .locked ? "未解锁" : node.chestClaimed ? "已领取" : "可领取")"
            : "\(node.title), \(node.status == .completed ? "已完成" : node.status == .current ? "当前" : "未解锁")")
        .position(x: entry.point.x, y: entry.point.y - 26)
    }

    private func cubeState(_ status: LessonStatus) -> CharCube.State {
        switch status { case .completed: return .done; case .current: return .current; case .locked: return .locked }
    }

    private func unitSign(_ unit: HomeMapLayout.Unit) -> some View {
        Button { selected = nil; selectedUnit = unit } label: {
            Text("第 \(unit.number) 单元 · \(unit.title)")
                .font(ClayFont.label).foregroundStyle(ClayColor.statText)
                .lineLimit(2).multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(width: 168, height: max(44, stage.minimumTapDimension))
                .background(ClayGradient.wood.view, in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
                .overlay { RoundedRectangle(cornerRadius: ClayRadius.smallButton).strokeBorder(ClayColor.chestRim, lineWidth: 2) }
        }
        .buttonStyle(ClayPressStyle()).accessibilityLabel("第\(unit.number)单元，\(unit.title)，\(unit.locked ? "未解锁" : "已解锁")")
        .accessibilityIdentifier("unit-sign-\(unit.number)")
        .position(x: 160, y: 122)
    }

    private func startPopup(_ entry: HomeMapLayout.Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.node.title).font(ClayFont.body).lineLimit(2)
            Text("第 \(entry.node.unitNumber) 单元 · \(entry.node.unitTitle)").font(ClayFont.caption).lineLimit(1)
            Text("最多 +\(HomeMapLayout.maxXP(entry.node)) XP").font(ClayFont.number)
            Button(entry.node.kind == .exam ? "开始挑战" : entry.node.status == .completed ? "再练一次" : "开始") {
                selected = nil; onTap(entry.node)
            }
            .font(ClayFont.button).frame(maxWidth: .infinity, minHeight: stage.minimumTapDimension)
            .foregroundStyle(ClayColor.white).background(ClayGradient.buttonOrange.view, in: Capsule())
            .accessibilityIdentifier(entry.node.kind == .exam ? "exam-start" : "lesson-start")
        }
        .padding(12).frame(width: 270)
        .foregroundStyle(ClayColor.ink)
        .background(ClayGradient.buttonCream.view, in: RoundedRectangle(cornerRadius: ClayRadius.bubble))
        .clayShadow(.bubble)
        .accessibilityIdentifier("map-start-popup")
    }

    private func unitPopup(_ unit: HomeMapLayout.Unit) -> some View {
        ClayButton(title: unit.locked ? "⚡ 跳到这里" : "单元手册", style: .cream,
                   id: unit.locked ? "unit-jump-\(unit.number)" : "unit-guide-\(unit.number)") {
            selectedUnit = nil
            if unit.locked { onJumpTap(unit.number) } else { onGuideTap(unit.number) }
        }
    }
}

private struct HomeMapOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
