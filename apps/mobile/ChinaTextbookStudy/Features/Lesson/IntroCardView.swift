import SwiftUI

/// 课前知识讲解（content-2）—— web IntroCard 的 SwiftUI 移植。
///
/// 多邻国 Tips 风格的分步讲解：每屏只讲一件事
/// （core_concept / key_formula / common_mistakes / tips），
/// 出战宠物 + 气泡 + TTS 音频 + 进度点 + 最后一页「开始做题」CTA。
/// 缺字段的页自动跳过；知识点全空时直接进题目。
struct IntroCardView: View {
    let lesson: Lesson
    let knowledge: KnowledgeSummary
    let onStart: () -> Void
    let onExit: () -> Void

    private enum Tone { case concept, rule, mistake, tip }

    private struct Page: Identifiable {
        let id: Int
        let tone: Tone
        let title: String
        let icon: String
        let accent: Color
        let mood: MascotMood
        let bubble: String
        /// 本页按顺序自动播的 TTS 音频段。
        let audioPaths: [String?]
        /// 标题旁 TTSButton 的代表音频（多段页留空避免重复）。
        let titleAudio: String?
    }

    private var pages: [Page] {
        var result: [Page] = []
        if !knowledge.coreConcept.isEmpty {
            result.append(Page(
                id: result.count, tone: .concept, title: "这是什么？",
                icon: "book.fill", accent: ClayColor.blueEdge,
                mood: .think, bubble: "一起学！",
                audioPaths: [knowledge.audio?.coreConcept],
                titleAudio: knowledge.audio?.coreConcept
            ))
        }
        if !knowledge.keyFormula.isEmpty {
            result.append(Page(
                id: result.count, tone: .rule, title: "记住这个！",
                icon: "target", accent: ClayColor.greenEdge,
                mood: .wave, bubble: "超级重要!",
                audioPaths: [knowledge.audio?.keyFormula],
                titleAudio: knowledge.audio?.keyFormula
            ))
        }
        if !knowledge.commonMistakes.isEmpty {
            result.append(Page(
                id: result.count, tone: .mistake, title: "小心这些坑！",
                icon: "xmark.circle.fill", accent: ClayColor.balloonKnot,
                mood: .surprise, bubble: "别踩坑哦!",
                audioPaths: knowledge.audio?.commonMistakes ?? [],
                titleAudio: nil
            ))
        }
        if !knowledge.tips.isEmpty {
            result.append(Page(
                id: result.count, tone: .tip, title: "学习小妙招",
                icon: "bolt.fill", accent: ClayColor.flameCore,
                mood: .cheer, bubble: "你最棒!",
                audioPaths: [knowledge.audio?.tips],
                titleAudio: knowledge.audio?.tips
            ))
        }
        return result
    }

    @State private var pageIdx = 0
    @State private var mascotReactKey = 0

    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var audioPlayer = AudioPlayer.shared

    @Environment(\.petEnvironment) private var pet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLast: Bool { pageIdx >= pages.count - 1 }

    var body: some View {
        let all = pages
        Group {
            if all.isEmpty {
                // 异常保护：知识点全空就直接开始做题。
                Color.clear.onAppear { onStart() }
            } else {
                content(pages: all, current: all[min(pageIdx, all.count - 1)])
            }
        }
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
        .onAppear { enterPage(all.first) }
        .onDisappear { audioPlayer.stop() }
    }

    @ViewBuilder
    private func content(pages all: [Page], current: Page) -> some View {
        Stage(background: { _ in LessonScene(bookId: lesson.bookId) }) { ctx in
            let width = ctx.size.width - ctx.safeArea.leading - ctx.safeArea.trailing - 32
            VStack(spacing: 12) {
                LessonHeader(progress: Double(pageIdx + 1) / Double(all.count), count: "\(pageIdx + 1)/\(all.count)") {
                    ClayIconButton(icon: .back, id: "intro-exit", label: "退出课程") {
                        HapticEngine.shared.tap()
                        onExit()
                    }
                } trailing: {
                    Text("知识讲解").font(ClayFont.largeButton).foregroundStyle(ClayColor.creamText)
                }
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("第 \(lesson.unitNumber) 单元 · \(lesson.unitTitle)").font(ClayFont.caption)
                        Text(lesson.title).font(ClayFont.body).lineLimit(1)
                        HStack {
                            Image(systemName: current.icon).foregroundStyle(current.accent)
                            Text(current.title).font(ClayFont.title)
                            if let titleAudio = current.titleAudio { TTSButton(path: titleAudio).clayHitTarget() }
                        }
                        ScrollView { pageBody(current).frame(maxWidth: .infinity, alignment: .leading) }
                            .accessibilityIdentifier("intro-content")
                    }
                    .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .clayLessonCard(edge: current.accent)
                    VStack(spacing: 8) {
                        SpeechBubble { Text("\(pet.kind.name)：\(current.bubble)") }
                        PetView(mood: current.mood, size: 100, reactTo: .levelup, reactKey: mascotReactKey)
                        footer(pages: all)
                    }
                    .frame(width: width * 0.34).frame(maxHeight: .infinity)
                }
                .foregroundStyle(ClayColor.ink)
            }
            .padding(.top, 16).padding(.bottom, 16)
            .frame(width: width, height: ctx.size.height - ctx.safeArea.top - ctx.safeArea.bottom)
            .offset(x: ctx.safeArea.leading + 16, y: ctx.safeArea.top)
        }
    }

    // MARK: - 每页内容

    @ViewBuilder
    private func pageBody(_ page: Page) -> some View {
        switch page.tone {
        case .concept:
            Text(MathText.render(knowledge.coreConcept))
                .font(ClayFont.body)
                .foregroundStyle(ClayColor.ink)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
        case .rule:
            Text(MathText.render(knowledge.keyFormula))
                .font(ClayFont.largeButton)
                .foregroundStyle(ClayColor.ink)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(ClayColor.creamBottom, in: .rect(cornerRadius: ClayRadius.smallButton))
                .overlay {
                    RoundedRectangle(cornerRadius: ClayRadius.smallButton)
                        .strokeBorder(ClayColor.creamEdge, lineWidth: 2)
                }
        case .mistake:
            VStack(spacing: 10) {
                ForEach(Array(knowledge.commonMistakes.enumerated()), id: \.offset) { i, mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(ClayFont.largeButton)
                            .foregroundStyle(ClayColor.balloonKnot)
                            .padding(.top, 2)
                        Text(MathText.render(mistake))
                            .font(ClayFont.body)
                            .foregroundStyle(ClayColor.ink)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TTSButton(path: mistakeAudio(at: i), size: 15).clayHitTarget()
                    }
                    .padding(12)
                    .background(ClayColor.balloonKnot.opacity(0.07), in: .rect(cornerRadius: ClayRadius.smallButton))
                    .overlay {
                        RoundedRectangle(cornerRadius: ClayRadius.smallButton)
                            .strokeBorder(ClayColor.balloonKnot.opacity(0.25), lineWidth: 2)
                    }
                }
            }
        case .tip:
            Text(MathText.render(knowledge.tips))
                .font(ClayFont.body)
                .foregroundStyle(ClayColor.ink)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
        }
    }

    private func mistakeAudio(at index: Int) -> String? {
        guard let list = knowledge.audio?.commonMistakes, index < list.count else { return nil }
        return list[index]
    }

    // MARK: - 底部：上一步 + 主按钮

    private func footer(pages all: [Page]) -> some View {
        HStack(spacing: 10) {
            if pageIdx > 0 {
                ClayIconButton(icon: .left, id: "intro-previous", label: "上一步") {
                    HapticEngine.shared.tap()
                    SFXEngine.shared.play(.tap)
                    withAnimation(Motion.bounce) { pageIdx -= 1 }
                    enterPage(all[pageIdx])
                }
            }
            ClayButton(title: isLast ? "我知道了" : "下一步", id: isLast ? "intro-start" : "intro-next") {
                if isLast {
                    SFXEngine.shared.play(.unlock)
                    HapticEngine.shared.success()
                    audioPlayer.stop()
                    onStart()
                } else {
                    HapticEngine.shared.tap()
                    SFXEngine.shared.play(.tap)
                    withAnimation(Motion.bounce) { pageIdx += 1 }
                    enterPage(all[pageIdx])
                }
            }
        }
    }

    // MARK: - 翻页副作用（吉祥物反应 + 自动朗读该页音频）

    private func enterPage(_ page: Page?) {
        guard let page else { return }
        mascotReactKey += 1
        SFXEngine.shared.play(.progressTick)
        guard settings.autoNarrate, !settings.isMuted else { return }
        let paths = page.audioPaths.compactMap { $0 }
        guard !paths.isEmpty else { return }
        audioPlayer.play(paths: paths, settings: settings)
    }
}
