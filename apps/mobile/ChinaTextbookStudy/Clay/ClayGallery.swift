#if DEBUG
import SwiftUI

/// 只展示本卡基础素材；完整场景插画由 RD-03 提供。
struct ClayGallery: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @ObservedObject private var kai = ClayKaiFontStore.shared
    @State private var page = 0
    @State private var currentStep = 1
    @State private var lastTappedStep: Int?
    @State private var reduceMotionOverride: Bool?
    @State private var message = "我饿啦，想吃"
    let onClose: () -> Void

    private let titles = ["黏土组件", "全部渐变 · 50", "图标与字体", "宠物"]
    private var reduceMotion: Bool { systemReduceMotion || (reduceMotionOverride ?? false) }

    var body: some View {
        Stage { ctx in
            ZStack(alignment: .topLeading) {
                ClayGradient.sky.view
                ClayGradient.hill1.view
                    .frame(width: ctx.size.width, height: 170)
                    .position(x: ctx.size.width / 2, y: ctx.size.height - 85)
            }
        } content: { ctx in
            // 竖屏预览时 44pt 点击区会撑高三行按钮；向上借用天空，避免盖住信息区。
            // 横屏内容能放进原有 206 舞台点时，所有设计坐标保持不变。
            let petExtraHeight = page == titles.count - 1
                ? max(0, 3 * max(52, ctx.minimumTapDimension) + 16 - 206) : 0
            ZStack(alignment: .topLeading) {
                TitleRibbon(title: titles[page]).position(ctx.place(x: 422, y: 40 - petExtraHeight))
                Text("舞台 \(Int(ctx.size.width)) × \(Int(ctx.size.height)) · 第 \(page + 1)/\(titles.count) 页")
                    .font(ClayFont.caption).foregroundStyle(ClayColor.ink)
                    .accessibilityIdentifier("clay-stage-metrics")
                    .accessibilityValue("\(ctx.scale),\(ctx.safeArea.top),\(ctx.safeArea.leading),\(ctx.safeArea.bottom),\(ctx.safeArea.trailing)")
                    .position(ctx.place(x: 422, y: 73 - petExtraHeight))
                switch page {
                case 0: components(ctx)
                case 1: gradients(ctx)
                case 2: iconsAndFonts(ctx)
                default:
                    PetGallery()
                        .environment(\.petAnimationsPaused, reduceMotion)
                        .frame(width: 700, height: 206 + petExtraHeight)
                        .position(ctx.place(x: 422, y: 197 - petExtraHeight / 2))
                }
                hud(ctx)
            }
        }
        .preferredColorScheme(.light)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden()
    }

    @ViewBuilder private func hud(_ ctx: StageLayout) -> some View {
        let side = max(48, ctx.minimumTapDimension)
        let size = CGSize(width: side, height: side)
        ClayIconButton(icon: .back, id: "stage-top-leading", label: "关闭黏土组件预览", action: onClose)
            .stageAnchor(.topLeading, in: ctx, size: size)
        ClayIconButton(icon: .pause, id: "stage-top-trailing", label: "切换减少动态效果") {
            reduceMotionOverride = !reduceMotion
        }
        .accessibilityValue(reduceMotion ? "开启" : "关闭")
        .stageAnchor(.topTrailing, in: ctx, size: size)
        ClayIconButton(icon: .left, id: "stage-bottom-leading", label: "上一组组件") { page = (page + titles.count - 1) % titles.count }
            .stageAnchor(.bottomLeading, in: ctx, size: size)
        ClayIconButton(icon: .right, id: "stage-bottom-trailing", label: "下一组组件") { page = (page + 1) % titles.count }
            .stageAnchor(.bottomTrailing, in: ctx, size: size)
    }

    @ViewBuilder private func components(_ ctx: StageLayout) -> some View {
        StepBar(steps: ["玩", "认", "练", "写", "说"], current: currentStep, completed: [0]) { index in
            lastTappedStep = index
            currentStep = index
        }
        .position(ctx.place(x: 285, y: 107))
        Text(lastTappedStep.map { "步骤索引：\($0)（从 0 开始）" } ?? "已完成 · 当前 · 未到")
            .font(ClayFont.caption).foregroundStyle(ClayColor.ink)
            .accessibilityIdentifier("clay-step-result")
            .position(ctx.place(x: 285, y: 147))
        StatPill(icon: .flame, text: "连续 4 天").position(ctx.place(x: 555, y: 108))
        AvatarBadge(level: 3) { Text("山").clayKaiFont(size: 34).foregroundStyle(ClayColor.ink) }
            .position(ctx.place(x: 710, y: 113))
        TitleRibbon(title: "识字闯关").position(ctx.place(x: 170, y: 193))
        TitleRibbon(title: "看图识物", color: .green).position(ctx.place(x: 365, y: 193))
        TitleRibbon(title: "小狐狸绘本", color: .blue).position(ctx.place(x: 570, y: 193))
        SpeechBubble(tail: .left) {
            HStack(spacing: 8) {
                Text(message)
                SayButton(pinyin: "shān", id: "clay-say") { message = "一起读，山" }
            }
        }.position(ctx.place(x: 265, y: 260))
        SpeechBubble(tail: .right) { Text("真棒！") }.position(ctx.place(x: 535, y: 260))
        GoButton(pausesAnimation: reduceMotion, id: "clay-go") { message = "准备闯关！" }.position(ctx.place(x: 675, y: 280))
        ClayButton(title: "再练一次", style: .cream, id: "clay-cream") { message = "再练一次" }
            .position(ctx.place(x: 230, y: 335))
        ClayButton(title: "下一关", icon: .play, id: "clay-orange") { message = "下一关" }
            .position(ctx.place(x: 425, y: 335))
        OutlinedLabel(text: "课外书屋").padding(8).background(ClayColor.white)
            .position(ctx.place(x: 570, y: 332))
        OutlinedLabel(text: "识字游戏").position(ctx.place(x: 660, y: 349))
    }

    @ViewBuilder private func gradients(_ ctx: StageLayout) -> some View {
        ForEach(Array(ClayGradient.allCases.enumerated()), id: \.element.id) { index, gradient in
            VStack(spacing: 3) {
                gradient.view.frame(width: 60, height: 29)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(ClayColor.white, lineWidth: 1) }
                Text(gradient.rawValue).font(ClayFont.swatch).foregroundStyle(ClayColor.ink)
            }
            .position(ctx.place(x: 110 + CGFloat(index % 10) * 69, y: 104 + CGFloat(index / 10) * 44))
        }
    }

    @ViewBuilder private func iconsAndFonts(_ ctx: StageLayout) -> some View {
        ForEach(Array(ClayIcon.allCases.enumerated()), id: \.element.id) { index, icon in
            VStack(spacing: 6) {
                ClayIconButton(icon: icon, size: index.isMultiple(of: 2) ? .regular : .small,
                               id: "clay-icon-\(icon.rawValue)") { message = icon.label }
                Text(icon.label).font(ClayFont.caption).foregroundStyle(ClayColor.ink)
            }
            .position(ctx.place(x: 150 + CGFloat(index % 7) * 90, y: 115 + CGFloat(index / 7) * 85))
        }
        HStack(spacing: 24) {
            VStack(spacing: 5) {
                Text("山水").clayKaiFont(size: 44)
                Text(fontStatus).font(ClayFont.caption).accessibilityIdentifier("clay-kai-status")
            }
            VStack(spacing: 5) {
                Text("shān shuǐ").font(ClayFont.pinyin)
                Text("800 · 1,280").font(ClayFont.nunito(size: 16, weight: 800))
                Text("900 · 1,280").font(ClayFont.number)
            }
            VStack(spacing: 5) {
                Text("快乐学习").font(ClayFont.title)
                Text("标题 / 按钮 / 正文").font(ClayFont.body)
                OutlinedLabel(text: "标签描边")
            }
        }
        .foregroundStyle(ClayColor.ink).padding(14)
        .background(ClayGradient.buttonCream.view)
        .clipShape(RoundedRectangle(cornerRadius: ClayRadius.card))
        .clayShadow()
        .position(ctx.place(x: 422, y: 305))
    }

    private var fontStatus: String {
        switch kai.state {
        case .idle: return "PingFang · 等待下载"
        case .downloading: return "PingFang · 楷体下载中"
        case .available: return "楷体已就绪"
        case .unavailable: return "PingFang · 离线回退"
        }
    }
}
#endif
