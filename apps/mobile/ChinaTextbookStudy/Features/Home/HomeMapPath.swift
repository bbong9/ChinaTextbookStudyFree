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

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.clayMotionPaused) private var locallyPaused
    @Environment(\.petEnvironment) private var pet
    // 偏移只让视差、回当前按钮和诊断探针刷新，不订阅到整个地图节点树。
    @State private var scrolling = HomeMapScrollState()
    @State private var selected: HomeMapLayout.Entry?
    @State private var selectedUnit: HomeMapLayout.Unit?
    @State private var lockedHint: String?
    @State private var shake = 0

    private var reduceMotion: Bool { systemReduceMotion || locallyPaused }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HomeMapScrollingHorizon(scrolling: scrolling, reduceMotion: reduceMotion, size: stage.size)
                .allowsHitTesting(false)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(layout.units) { unit in
                            HomeMapUnitScene(unit: unit, current: layout.current, stage: stage,
                                shake: shake, reduceMotion: reduceMotion, onNodeTap: tapNode,
                                onUnitTap: { selected = nil; selectedUnit = $0 },
                                onPetHome: onPetHome, onReadingRoom: onReadingRoom, onMath: onMath)
                                .equatable()
                                .frame(width: unit.width, height: stage.size.height, alignment: .topLeading)
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
                        HStack(spacing: 0) {
                            ForEach(layout.anchors) { anchor in
                                Color.clear.frame(width: anchor.gap, height: 1)
                                Color.clear.frame(width: 1, height: 1).id(anchor.id)
                            }
                        }
                        .allowsHitTesting(false).accessibilityHidden(true)
                    }
                }
                .accessibilityIdentifier("home-map-scroll")
                .accessibilityValue(reduceMotion ? "静态场景" : "分层视差")
                .modifier(HomeMapScrollTracking { value in
                    scrolling.offset = value
                    if selected != nil { selected = nil }
                    if selectedUnit != nil { selectedUnit = nil }
                })
                .onAppear { locate(proxy, animated: false) }
                .onChange(of: layout.current?.id) { _, _ in locate(proxy, animated: true) }
                .onChange(of: stage.size.width) { _, _ in locate(proxy, animated: false) }
                .overlay(alignment: .trailing) {
                    HomeMapCurrentLocator(scrolling: scrolling, currentX: layout.currentX, stage: stage) {
                        locate(proxy, animated: true)
                    }
                }
            }
            #if DEBUG
            if HomeMapTestSeed.flag("-uitest-map-fps") {
                HomeMapScrollingFPS(scrolling: scrolling).frame(width: 310, height: 16)
                    .position(x: stage.size.width / 2, y: 90)
            }
            #endif
            if let selected {
                startPopup(selected)
                    .position(x: popupX(selected), y: stage.size.height - 225)
            }
            if let unit = selectedUnit {
                unitPopup(unit)
                    .position(x: min(stage.size.width - 140, max(140, unit.origin + 170 + scrolling.offset)),
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
        .coordinateSpace(name: "home-map-viewport")
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
                   max(150 + stage.safeArea.leading, origin + entry.point.x + scrolling.offset))
    }

    private func tapNode(_ entry: HomeMapLayout.Entry) {
        let node = entry.node
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
            .foregroundStyle(ClayColor.white).background { ClayGradient.buttonOrange.view.clipShape(Capsule()) }
            .accessibilityIdentifier(entry.node.kind == .exam ? "exam-start" : "lesson-start")
        }
        .padding(12).frame(width: 270)
        .foregroundStyle(ClayColor.ink)
        .background { ClayGradient.buttonCream.view.clipShape(RoundedRectangle(cornerRadius: ClayRadius.bubble)) }
        .clayShadow(.bubble)
        .accessibilityElement(children: .contain)
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

private final class HomeMapScrollState: ObservableObject {
    @Published var offset: CGFloat = 0
}

private struct HomeMapScrollingHorizon: View {
    @ObservedObject var scrolling: HomeMapScrollState
    let reduceMotion: Bool
    let size: CGSize
    var body: some View { HomeMapHorizon(offset: scrolling.offset, reduceMotion: reduceMotion, size: size) }
}

private struct HomeMapCurrentLocator: View {
    @ObservedObject var scrolling: HomeMapScrollState
    let currentX: CGFloat?
    let stage: StageLayout
    let onLocate: () -> Void

    var body: some View {
        if !HomeMapLayout.currentVisible(x: currentX, offset: scrolling.offset, viewport: stage.size.width) {
            Button(action: onLocate) {
                Label("回到当前", systemImage: "location.fill")
                    .font(ClayFont.label).foregroundStyle(ClayColor.ink)
                    .padding(.horizontal, 12).frame(minHeight: stage.minimumTapDimension)
                    .background { ClayGradient.buttonCream.view.clipShape(Capsule()) }
            }
            .buttonStyle(ClayPressStyle())
            .accessibilityLabel("回到当前关卡").accessibilityIdentifier("back-to-current")
            .padding(.trailing, stage.safeArea.trailing + 12)
        }
    }
}

#if DEBUG
private struct HomeMapScrollingFPS: View {
    @ObservedObject var scrolling: HomeMapScrollState
    var body: some View { HomeMapFPSProbe(offset: scrolling.offset) }
}
#endif

private struct HomeMapScrollTracking: ViewModifier {
    let onOffset: (CGFloat) -> Void
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { -$0.contentOffset.x } action: { _, value in onOffset(value) }
        } else {
            content.onPreferenceChange(HomeMapOffsetKey.self, perform: onOffset)
        }
    }
}

/// 静态字块只随节点状态重绘；滚动偏移不触发素材重新合成。
private struct HomeMapNodeFace: View, Equatable {
    let node: PathMapNode
    let label: String
    let minimumTapDimension: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if node.kind == .chest {
                GiftView(x: 38, y: 65, scale: 0.85).opacity(node.chestClaimed ? 0.45 : 1)
                Text("宝箱").font(ClayFont.label).foregroundStyle(ClayColor.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background { ClayGradient.blue.view.clipShape(Capsule()) }.position(x: 38, y: 2)
            } else {
                CharCube(x: 38, y: 60, label: label,
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
        .frame(width: 76, height: 80)
        .padding(18) // 合成范围包含字块光晕和礼盒飘带，命中区仍使用节点间距。
        .drawingGroup()
        .frame(width: max(62, minimumTapDimension), height: max(80, minimumTapDimension))
        .contentShape(Rectangle()).accessibilityHidden(true)
    }

    private func cubeState(_ status: LessonStatus) -> CharCube.State {
        switch status { case .completed: return .done; case .current: return .current; case .locked: return .locked }
    }

}

/// 滚动的几何变换由 visualEffect 更新；节点树只在进度或宠物反应变化时重建。
private struct HomeMapUnitScene: View, Equatable {
    let unit: HomeMapLayout.Unit
    let current: HomeMapLayout.Entry?
    let stage: StageLayout
    let shake: Int
    let reduceMotion: Bool
    let onNodeTap: (HomeMapLayout.Entry) -> Void
    let onUnitTap: (HomeMapLayout.Unit) -> Void
    let onPetHome: () -> Void
    let onReadingRoom: () -> Void
    let onMath: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.unit == rhs.unit && lhs.current == rhs.current && lhs.stage.size == rhs.stage.size
            && lhs.stage.minimumTapDimension == rhs.stage.minimumTapDimension
            && lhs.shake == rhs.shake && lhs.reduceMotion == rhs.reduceMotion
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HomeMapMiddle(unit: unit.number, width: unit.width).equatable()
                .modifier(HomeMapParallax(rate: 0.6, width: unit.width, paused: reduceMotion))
                .allowsHitTesting(false)
            if unit.origin == 0 {
                landmarks.modifier(HomeMapParallax(rate: 0.6, width: unit.width, paused: reduceMotion))
            }
            HomeMapForeground(width: unit.width).equatable()
                .modifier(HomeMapParallax(rate: 1.1, width: unit.width, paused: reduceMotion))
                .allowsHitTesting(false)
            HomeMapRoad(points: unit.road).equatable().allowsHitTesting(false)
            ForEach(unit.entries) { entry in nodeButton(entry) }
            unitSign(unit)
            if let current, current.node.status == .current,
               current.node.unitNumber == unit.number {
                PetView(size: 70, reactTo: shake > 0 ? .wrong : nil, reactKey: shake)
                    .clayMotion(.bob)
                    .position(x: current.point.x, y: current.point.y - 78)
                    .accessibilityIdentifier("map-current-pet")
                    .allowsHitTesting(false)
            }
        }
        .frame(width: unit.width, height: 390)
        .contentShape(Rectangle())
        .clipShape(HomeMapUnitClip(skyExtension: max(0, stage.size.height - 390)))
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
        Button(action: action) {
            Color.clear.frame(width: width, height: max(stage.minimumTapDimension, height)).contentShape(Rectangle())
        }
            .buttonStyle(.plain)
            .accessibilityLabel(title).accessibilityIdentifier(id).position(point)
    }

    private func nodeButton(_ entry: HomeMapLayout.Entry) -> some View {
        let node = entry.node
        return Button { onNodeTap(entry) } label: {
            HomeMapNodeFace(node: node, label: entry.label(), minimumTapDimension: stage.minimumTapDimension)
                .equatable()
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityIdentifier(node.kind == .chest ? "chest-node-\(node.id)" : node.kind == .exam ? "exam-node-\(node.id)" : "lesson-row-\(node.id)")
        .accessibilityLabel(node.kind == .chest
            ? "宝箱, \(node.status == .locked ? "未解锁" : node.chestClaimed ? "已领取" : "可领取")"
            : "\(node.title), \(node.status == .completed ? "已完成" : node.status == .current ? "当前" : "未解锁")")
        .position(x: entry.point.x, y: entry.point.y - 26)
    }

    private func unitSign(_ unit: HomeMapLayout.Unit) -> some View {
        Button { onUnitTap(unit) } label: {
            Text("第 \(unit.number) 单元 · \(unit.title)")
                .font(ClayFont.label).foregroundStyle(ClayColor.statText)
                .lineLimit(2).multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(width: 168, height: max(44, stage.minimumTapDimension))
                .background { ClayGradient.wood.view.clipShape(RoundedRectangle(cornerRadius: ClayRadius.smallButton)) }
                .overlay { RoundedRectangle(cornerRadius: ClayRadius.smallButton).strokeBorder(ClayColor.chestRim, lineWidth: 2) }
        }
        .buttonStyle(ClayPressStyle()).accessibilityLabel("第\(unit.number)单元，\(unit.title)，\(unit.locked ? "未解锁" : "已解锁")")
        .accessibilityIdentifier("unit-sign-\(unit.number)")
        .position(x: 160, y: 122)
    }

}

/// 单元横向裁切保留视差边界；增高舞台时，让原稿顶部的树冠完整伸进补出的天空。
private struct HomeMapUnitClip: Shape {
    let skyExtension: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: -skyExtension, width: rect.width, height: rect.height + skyExtension))
    }
}

private struct HomeMapParallax: ViewModifier {
    let rate: CGFloat
    let width: CGFloat
    let paused: Bool
    func body(content: Content) -> some View {
        content.visualEffect { effect, geometry in
            let localScroll = max(-width, min(width, -geometry.frame(in: .named("home-map-viewport")).minX))
            return effect.offset(x: HomeMapLayout.parallaxCorrection(offset: localScroll, rate: rate, reduceMotion: paused))
        }
    }
}
