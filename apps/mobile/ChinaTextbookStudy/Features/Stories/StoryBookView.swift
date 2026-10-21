import SwiftUI

/// 阅读阶段只管理分页与朗读；完成后的测验、奖励仍交给 StoryReaderView。
struct StoryBookView: View {
    let story: Story
    let pinyin: [[String]]?
    let bedtime: Bool
    let onExit: () -> Void
    let onFinished: (StoryPageFlow.Ending) -> Void
    let onNarratedPage: (Int) -> Void

    @State private var flow: StoryPageFlow
    @State private var showsPinyin = true
    @State private var autoPage: Bool
    @State private var narrationRun: Int?
    @State private var pendingAdvance: Task<Void, Never>?
    @State private var active = true
    @ObservedObject private var audio = AudioPlayer.shared
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(story: Story, pinyin: [[String]]?, bedtime: Bool, onExit: @escaping () -> Void,
         onFinished: @escaping (StoryPageFlow.Ending) -> Void, onNarratedPage: @escaping (Int) -> Void) {
        self.story = story; self.pinyin = pinyin; self.bedtime = bedtime
        self.onExit = onExit; self.onFinished = onFinished
        self.onNarratedPage = onNarratedPage
        _flow = State(initialValue: StoryPageFlow(count: story.sentences.count, bedtime: bedtime, hasQuestions: !story.questions.isEmpty))
        _autoPage = State(initialValue: bedtime)
    }

    private var sentence: PassageSentence? { story.sentences.indices.contains(flow.page) ? story.sentences[flow.page] : nil }
    private var english: Bool { StoryReading.isEnglish(story.language) }
    private var playing: Bool { narrationRun == audio.currentRunId && audio.isPlaying }

    var body: some View {
        Stage { _ in
            StoryIllustration(story: story, bedtime: bedtime, forceFallback: testFlag("-uitest-story-no-image"))
        } content: { ctx in
            let width = max(0, ctx.size.width - ctx.safeArea.leading - ctx.safeArea.trailing - 32)
            VStack(spacing: 0) {
                header
                HStack {
                    pageButton(previous: true)
                    Spacer()
                    pageButton(previous: false)
                }
                .frame(maxHeight: .infinity)
                HStack(alignment: .bottom, spacing: 14) {
                    textPanel.frame(maxWidth: .infinity)
                    VStack(spacing: 6) {
                        if !bedtime {
                            Button { toggleAutoPage() } label: {
                                Text("自动翻页 \(autoPage ? "开" : "关")").font(ClayFont.label)
                                    .padding(.horizontal, 12).frame(minHeight: ctx.minimumTapDimension)
                                    .background(ClayColor.darkPill, in: Capsule())
                            }
                            .foregroundStyle(ClayColor.white).buttonStyle(ClayPressStyle())
                            .accessibilityLabel("自动翻页").accessibilityValue(autoPage ? "开" : "关")
                            .accessibilityIdentifier("story-auto-page")
                        }
                        ClayButton(title: playing ? "停止朗读" : "读给我听", icon: .speaker, id: "story-narrate") {
                            if playing { stopNarration() } else { narrate() }
                        }
                    }
                }
            }
            .padding(.top, 14).padding(.bottom, 20)
            .frame(width: width, height: max(0, ctx.size.height - ctx.safeArea.top - ctx.safeArea.bottom))
            .offset(x: ctx.safeArea.leading + 16, y: ctx.safeArea.top)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 40).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            value.translation.width < 0 ? next() : previous()
        })
        .task {
            active = true
            #if DEBUG
            StoryNarrationTrace.reset()
            #endif
            if bedtime { narrate() }
        }
        .onChange(of: audio.queueCompletionCount) { _, _ in narrationFinished() }
        .onChange(of: settings.isMuted) { _, muted in
            if muted { stopNarration() } else if bedtime { narrate() }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { stopNarration() } }
        .onDisappear { active = false; stopNarration() }
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ClayIconButton(icon: .back, id: "story-back", label: "返回书架") { stopNarration(); onExit() }
            TitleRibbon(title: "\(story.title) · \(min(flow.page + 1, story.sentences.count))/\(story.sentences.count)", color: .blue)
                .accessibilityIdentifier("story-page-progress")
            Spacer(minLength: 4)
            if bedtime {
                Text("🌙 睡前模式").font(ClayFont.largeButton).foregroundStyle(ClayColor.white)
            }
            if pinyin != nil && !english {
                Button { showsPinyin.toggle() } label: {
                    Text("拼音 \(showsPinyin ? "开" : "关")").font(ClayFont.largeButton)
                        .foregroundStyle(ClayColor.blueEdge)
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(ClayColor.white.opacity(0.9), in: RoundedRectangle(cornerRadius: ClayRadius.button))
                        .clayHitTarget()
                }
                .buttonStyle(ClayPressStyle()).accessibilityLabel("拼音")
                .accessibilityValue(showsPinyin ? "开" : "关").accessibilityIdentifier("story-pinyin")
            }
            LessonSymbolButton(symbol: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                               label: settings.isMuted ? "打开声音" : "关闭声音", id: "story-mute") { settings.isMuted.toggle() }
                .accessibilityValue(settings.isMuted ? "关" : "开")
        }
    }

    private func pageButton(previous: Bool) -> some View {
        Button { previous ? self.previous() : next() } label: {
            Image(systemName: previous ? "chevron.left" : "chevron.right")
                .font(ClayFont.title).frame(width: 44, height: 64)
                .foregroundStyle(ClayColor.white)
                .background(ClayColor.darkPill.opacity(0.65), in: Capsule())
                .clayHitTarget()
        }
        .disabled(previous && flow.page == 0)
        .opacity(previous && flow.page == 0 ? 0.3 : 1)
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel(previous ? "上一页" : flow.page + 1 < story.sentences.count ? "下一页" : bedtime ? "听完了，晚安" : "开始答题")
        .accessibilityIdentifier(previous ? "story-previous" : "story-next")
    }

    private var textPanel: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: !playing)) { _ in
            let text = sentence?.text ?? "故事还没有内容"
            let highlight: Int? = playing ? audio.recordingDuration.map {
                StoryReading.highlight(text: text, elapsed: audio.recordingElapsed, duration: $0)
            } ?? StoryReading.characterIndex(text: text, speechRange: audio.speechRange) : nil
            let row = showsPinyin && pinyin?.indices.contains(flow.page) == true ? pinyin?[flow.page] : nil
            ScrollView {
                StoryRubyText(text: text, pinyin: row, highlight: highlight, english: english)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
            .fixedSize(horizontal: false, vertical: true)
            .background(ClayColor.creamTop.opacity(0.96), in: RoundedRectangle(cornerRadius: ClayRadius.card))
            .clayShadow(.panel)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityValue(highlight.map { "正在朗读第\($0 + 1)个字" } ?? "")
            .accessibilityIdentifier("story-sentence")
        }
    }

    private func narrate() {
        stopNarration()
        guard active, scenePhase == .active, let sentence, !settings.isMuted else { return }
        audio.play(text: sentence.text, audioPath: testFlag("-uitest-story-no-audio") ? nil : sentence.audio)
        if audio.isPlaying {
            narrationRun = audio.currentRunId
            #if DEBUG
            StoryNarrationTrace.record(story: story, page: flow.page, audio: audio)
            #endif
        }
    }

    private func stopNarration() {
        pendingAdvance?.cancel(); pendingAdvance = nil
        narrationRun = nil
        audio.stop()
    }

    private func narrationFinished() {
        guard active, narrationRun == audio.currentRunId else { return }
        onNarratedPage(flow.page)
        narrationRun = nil
        guard autoPage else { return }
        pendingAdvance?.cancel()
        pendingAdvance = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
            guard !Task.isCancelled, active, autoPage, scenePhase == .active else { return }
            next()
        }
    }

    private func next() {
        stopNarration()
        if let ending = flow.next() { onFinished(ending) }
        else if autoPage { narrate() }
    }

    private func previous() {
        stopNarration(); flow.previous()
        if autoPage { narrate() }
    }

    private func toggleAutoPage() {
        autoPage.toggle()
        if autoPage { if !playing { narrate() } }
        else { pendingAdvance?.cancel(); pendingAdvance = nil }
    }

    private func testFlag(_ flag: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-uitest") && ProcessInfo.processInfo.arguments.contains(flag)
        #else
        return false
        #endif
    }
}

private struct StoryRubyText: View {
    let text: String
    let pinyin: [String]?
    let highlight: Int?
    let english: Bool
    @Environment(\.clayStageScale) private var scale

    var body: some View {
        StoryRubyLayout(spacing: english ? 0 : 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                VStack(spacing: 0) {
                    if let pinyin {
                        Text(pinyin.indices.contains(index) ? pinyin[index] : "").font(ClayFont.storyRuby)
                            .foregroundStyle(ClayColor.storyPinyin).frame(height: 17)
                    }
                    Text(String(character)).font(ClayFont.story(scale: scale, english: english))
                        .foregroundStyle(index == highlight ? ClayColor.creamText : ClayColor.ink)
                }
                .background(index == highlight ? ClayColor.orangeBright.opacity(0.3) : .clear,
                            in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
            }
        }
    }
}

/// 每个字和自己的拼音作为一个排版单元换行，不靠空格拼接对齐。
private struct StoryRubyLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? 600, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrange(width: bounds.width, subviews: subviews)
        for (view, point) in zip(subviews, layout.points) {
            view.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), anchor: .topLeading, proposal: .unspecified)
        }
    }
    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0
        var points: [CGPoint] = []
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { x = 0; y += row + 6; row = 0 }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing; row = max(row, size.height)
        }
        return (CGSize(width: width, height: y + row), points)
    }
}
