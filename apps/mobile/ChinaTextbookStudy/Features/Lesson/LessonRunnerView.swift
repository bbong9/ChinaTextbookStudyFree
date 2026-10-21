import SwiftUI

/// 横屏课本关卡；判分、队列、续学与结算由原状态机持有。
struct LessonRunnerView: View {
    let bookId: String
    let lessonId: String
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]

    @State private var lesson: Lesson?
    @State private var loadError: String?

    // Runner state — `queue` grows when a wrong answer is re-queued.
    @State private var queue: [Question] = []
    @State private var index: Int = 0
    @State private var phase: QuestionPhase = .answering
    @State private var currentAnswer: String = ""
    @State private var isCorrect: Bool? = nil
    @State private var solvedIDs: Set<Int> = []
    @State private var missedIDs: Set<Int> = []
    @State private var combo: Int = 0
    @State private var maxCombo: Int = 0
    @State private var attemptedThisQuestion = false

    // Session persistence (ios-lesson-3 / parity-13)
    /// 本会话内累计展示过的 XP（恢复时接着累计；结算以 store 计算为准）。
    @State private var sessionXp = 0
    /// ISO8601 开始时间 —— 恢复会话时沿用原会话的时间。
    @State private var sessionStartedAt = ISO8601DateFormatter().string(from: Date())
    /// 检测到可恢复的挂起会话时弹「继续上次 / 重新开始」。
    @State private var pendingResume: ActiveLessonSession?

    // Feedback presentation
    @State private var mascotMood: MascotMood = .happy
    @State private var feedbackReaction: MascotReaction? = nil
    @State private var feedbackBubble: String = ""
    @State private var feedbackTitleText: String = ""
    @State private var showCombo = false
    @State private var comboDisplayValue = 0
    @State private var xpFloaters: [XPFloatItem] = []

    // Gates & effects
    @State private var showQuitConfirm = false
    @State private var showOutOfHearts = false
    @State private var wrongFlash = 0
    @State private var showLessonSettings = false
    @State private var showKnowledge = false
    /// 课前知识讲解（content-2）：该课未完成且没看过讲解时先进分步讲解。
    @State private var showIntro = false
    /// 题目报错小旗子（Wave E2）：反馈面板 → 三选弹层。
    @State private var showReportSheet = false
    /// 报错弹层里已提交的类型（打勾反馈）。
    @State private var reportedKind: QuestionReport.Kind?

    /// 掉心延迟(ios-lesson-15):答错后 heartLoss 音/触感与 `loseHeart()` 一起
    /// 延迟 0.4s。期间用户就点了「知道了」的话,`proceed` 用它把还没落账的
    /// 红心算进去,避免 0 心还能继续。
    ///
    /// 必须是**计数器**而不是布尔(ioslesson-1):连续两次快答错时,第一个
    /// 延迟闭包会把布尔清成 false,第二颗还没落账的心就凭空消失了,断心闸门
    /// 因此漏算。计数器只做 +1 / -1,几笔悬账都能算准。
    @State private var pendingHeartLosses = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var audioPlayer = AudioPlayer.shared

    private struct XPFloatItem: Identifiable { let id = UUID(); let amount: Int }
    enum QuestionPhase { case answering, checked }

    private var originalTotal: Int { max(1, lesson?.questions.count ?? 1) }
    private var progress: Double { Double(solvedIDs.count) / Double(originalTotal) }

    /// 单元挑战课（"{bookId}-u{n}-exam"）：XP ×2，头部亮「⚔️ 单元挑战」徽章。
    private var isExamLesson: Bool { Economy.isExamLessonId(lessonId) }

    var body: some View {
        Group {
            if showIntro, let lesson, let knowledge = lesson.knowledge {
                // 课前知识讲解（content-2）：先学一步步的小讲解，再进题目。
                IntroCardView(
                    lesson: lesson,
                    knowledge: knowledge,
                    onStart: {
                        progressStore.markIntroSeen(lessonId)
                        withAnimation(.easeOut(duration: 0.25)) { showIntro = false }
                    },
                    onExit: { path.removeLast() }
                )
            } else if lesson != nil, index < queue.count {
                runner(question: queue[index])
            } else if let loadError {
                VStack(spacing: Space.m) {
                    Text("加载失败").duoFont(.heading)
                    Text(loadError).duoFont(.caption).foregroundStyle(DuoColors.inkMuted)
                }
                .padding()
            } else {
                ProgressView().tint(DuoColors.primary)
            }
        }
        .environment(\.petEnvironment, PetEnvironment(progressStore: progressStore))
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
        .navigationBarHidden(true)
        .task { load() }
        .onDisappear { audioPlayer.stop() }
    }

    @ViewBuilder
    private func runner(question q: Question) -> some View {
        LessonShell(bookId: bookId, question: q, instruction: instructionText(q.type),
                    checked: phase == .checked, mood: mascotMood,
                    reaction: feedbackReaction, reactionKey: index + 1) {
            header
        } answers: {
            QuestionRendererView(question: q, answer: currentAnswer, phase: phase,
                                 isCorrect: isCorrect, onChange: { currentAnswer = $0 })
                .id("\(q.id)-\(index)")
        } action: {
            checkFooter(question: q)
        } feedback: {
            if phase == .checked, let ok = isCorrect { feedbackPanel(ok: ok, question: q) }
        }
        .onChange(of: index) { _, _ in autoNarrate(q) }
        .onAppear { autoNarrate(q) }
        .overlay { floaters }
        .overlay { comboOverlay }
        .overlay { FullScreenFlash(color: DuoColors.danger, trigger: wrongFlash) }
        .overlay { if showOutOfHearts { outOfHeartsGate } }
        .overlay { if showQuitConfirm { quitConfirmOverlay } }
        .overlay { if pendingResume != nil { resumePromptOverlay } }
        .sheet(isPresented: $showLessonSettings) { lessonSettingsSheet }
        .sheet(isPresented: $showKnowledge) {
            if let lesson, let knowledge = lesson.knowledge {
                IntroCardView(lesson: lesson, knowledge: knowledge,
                              onStart: { showKnowledge = false }, onExit: { showKnowledge = false })
            }
        }
        .sheet(isPresented: $showReportSheet, onDismiss: { reportedKind = nil }) {
            reportSheet(question: q)
        }
    }

    // MARK: - Header: [X] [progress] [❤️]

    private var header: some View {
        LessonHeader(progress: progress, count: "\(solvedIDs.count)/\(originalTotal)") {
            ClayIconButton(icon: .back, id: "lesson-close", label: "关闭") {
                if phase == .checked || !solvedIDs.isEmpty || !missedIDs.isEmpty {
                    HapticEngine.shared.tap()
                    withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = true }
                } else {
                    path.removeLast()
                }
            }
        } trailing: {
            if isExamLesson {
                Text("⚔️ ×2").font(ClayFont.number).foregroundStyle(ClayColor.creamText)
                    .accessibilityLabel("单元挑战双倍经验").accessibilityIdentifier("exam-badge")
            }
            if Economy.isWeekend() {
                Text("⚡ ×2").font(ClayFont.number).foregroundStyle(ClayColor.creamText)
                    .accessibilityLabel("周末双倍经验")
            }
            StatPill(icon: .heart, text: "\(progressStore.hearts)").accessibilityIdentifier("lesson-hearts")
            LessonSymbolButton(symbol: "gearshape.fill", label: "课堂设置", id: "lesson-settings") {
                HapticEngine.shared.tap()
                showLessonSettings = true
            }
            ClayIconButton(icon: .help, id: "lesson-help", label: "知识讲解") { showKnowledge = true }
                .disabled(lesson?.knowledge == nil)
        }
    }

    // MARK: - In-lesson settings sheet (ios-lesson-14)

    private var lessonSettingsSheet: some View {
        HStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("课堂设置").font(ClayFont.title)
                PetView(mood: .think, size: 100)
            }.frame(maxWidth: .infinity)
            VStack(spacing: 8) {
                settingToggle(icon: "speaker.wave.2.fill", title: "音效", subtitle: "答题反馈与庆祝的声音",
                              isOn: Binding(get: { !settings.isMuted }, set: { settings.isMuted = !$0 }))
                settingToggle(icon: "iphone.radiowaves.left.and.right", title: "触感振动", subtitle: "答对答错时的轻微振动",
                              isOn: $settings.hapticEnabled)
                settingToggle(icon: "text.bubble.fill", title: "自动朗读", subtitle: "进入新题目时自动朗读题干",
                              isOn: $settings.autoNarrate)
                ClayButton(title: "好了", id: "lesson-settings-done") { showLessonSettings = false }
            }.frame(maxWidth: .infinity)
        }
        .foregroundStyle(ClayColor.ink).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClayGradient.buttonCream.view)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }

    private func settingToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(ClayFont.largeButton).foregroundStyle(ClayColor.orange).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(ClayFont.body)
                Text(subtitle).font(ClayFont.caption)
            }
            Spacer()
            Toggle(title, isOn: isOn).labelsHidden().tint(ClayColor.completed)
                .accessibilityLabel(title).accessibilityIdentifier("lesson-setting-\(title)")
        }
        .padding(10).background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
    }

    // MARK: - Overlays

    @ViewBuilder private var floaters: some View {
        ForEach(xpFloaters) { f in
            XPFloaterView(amount: f.amount) { xpFloaters.removeAll { $0.id == f.id } }
        }
    }

    @ViewBuilder private var comboOverlay: some View {
        if showCombo {
            ComboOverlayView(combo: comboDisplayValue)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCombo = false }
                }
        }
    }

    // MARK: - Instruction text

    private func instructionText(_ type: QuestionType) -> String {
        switch type {
        case .trueFalse:     return "判断对错"
        case .choice:        return "选择正确答案"
        case .fillBlank:     return "填写答案"
        case .calculation:   return "计算结果"
        case .fillBlankText: return "填写答案"
        case .wordOrder:     return "组成正确的句子"
        case .matching:      return "将配对连线"
        case .wordProblem:   return "解答应用题"
        }
    }

    // MARK: - Feedback panel (mascot + accent title + big CTA)

    private func feedbackPanel(ok: Bool, question: Question) -> some View {
        LessonFeedback(ok: ok) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedbackTitleText.isEmpty ? (ok ? "正确" : "答错了") : feedbackTitleText)
                        .font(ClayFont.largeButton).foregroundStyle(ok ? ClayColor.greenEdge : ClayColor.balloonKnot)
                    if !ok {
                        Text("正确答案：\(MathText.render(question.answer))").font(ClayFont.body)
                    } else if !feedbackBubble.isEmpty {
                        Text(feedbackBubble).font(ClayFont.caption)
                    }
                    if !question.explanation.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text(MathText.render(question.explanation)).font(ClayFont.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TTSButton(path: question.audio?.explanation, size: 16).clayHitTarget()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                LessonSymbolButton(symbol: "flag", label: "报告题目问题", id: "question-report-flag") {
                    HapticEngine.shared.tap()
                    showReportSheet = true
                }
            }
            .foregroundStyle(ClayColor.ink)
        } action: {
            ClayButton(title: ok ? "继续" : "知道了", id: ok ? "继续" : "知道了") { proceed(question: question) }
        }
    }

    // MARK: - Report sheet (Wave E2 小旗子)

    /// 三选报错弹层。选中即写入本地 reports 列表（不上传），打勾致谢后自动收起。
    private func reportSheet(question: Question) -> some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("这道题怎么了？").font(ClayFont.title)
                Text("你的反馈只保存在这台设备上，可在「设置」里查看。").font(ClayFont.body)
                if reportedKind != nil {
                    Text("已记录，谢谢小侦探！🕵️").font(ClayFont.body).foregroundStyle(ClayColor.greenEdge)
                        .transition(.scale.combined(with: .opacity))
                }
            }.frame(maxWidth: .infinity)
            VStack(spacing: 10) {
                ForEach(QuestionReport.Kind.allCases, id: \.self) { kind in
                    Button {
                        submitReport(kind: kind, question: question)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: kind.symbol)
                            Text(kind.label)
                            Spacer()
                            if reportedKind == kind { Image(systemName: "checkmark.circle.fill") }
                        }.padding(.horizontal, 14).frame(minHeight: 48)
                    }
                    .buttonStyle(LessonOptionStyle(state: reportedKind == kind ? .correct : .default))
                    .disabled(reportedKind != nil)
                    .accessibilityLabel(kind.label).accessibilityIdentifier("report-\(kind.rawValue)")
                }
                ClayButton(title: "取消", style: .cream, id: "lesson-report-cancel") { showReportSheet = false }
            }.frame(maxWidth: .infinity)
        }
        .foregroundStyle(ClayColor.ink).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClayGradient.buttonCream.view)
        .presentationDetents([.large]).presentationDragIndicator(.visible)
    }

    private func submitReport(kind: QuestionReport.Kind, question: Question) {
        _ = progressStore.addReport(
            lessonId: lessonId,
            questionId: question.id,
            kind: kind,
            userAnswer: currentAnswer,
            questionText: question.question
        )
        HapticEngine.shared.success()
        SFXEngine.shared.play(.tap)
        withAnimation(Motion.bounce) { reportedKind = kind }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showReportSheet = false
        }
    }

    // MARK: - Check footer

    private func checkFooter(question: Question) -> some View {
        let empty = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ClayButton(title: "检查", id: "检查答案") { check(question: question) }
            .disabled(empty).opacity(empty ? 0.55 : 1)
    }

    // MARK: - Out-of-hearts gate

    private var outOfHeartsGate: some View {
        OutOfHeartsGate(
            progressStore: progressStore,
            onRefill: {
                if progressStore.buyHeartRefill(cost: Economy.heartRefillCost) {
                    HapticEngine.shared.success()
                    SFXEngine.shared.play(.purchase)   // 宝石消费统一走收银双音(ios-feel-12)
                    showOutOfHearts = false
                    advance()
                } else {
                    HapticEngine.shared.wrong()
                }
            },
            // 断心闭环（ios-lesson-7）：去错题本做一组复习赚回 1 颗心。
            // 会话已持久化 —— 复习完回到这节课会从当前题目继续。
            onReview: {
                HapticEngine.shared.tap()
                path.removeLast()
                path.append(.reviewRunner)
            },
            onQuit: { path.removeLast() }   // 被迫退出：保留会话，回来可续
        )
        .transition(.opacity)
    }

    // MARK: - Quit confirm overlay (ios-lesson-13 / ios-feel-7)

    /// 零进度直接退出；已作答时沿用原有挽留与会话清理操作。
    private var quitConfirmOverlay: some View {
        ZStack {
            ClayColor.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = false }
                }
            LessonDialog {
                VStack(spacing: 8) {
                    PetView(mood: .sad, size: 92)
                    Text(solvedIDs.count * 2 >= originalTotal ? "再坚持一下，快完成了！" : "确定要退出吗？")
                        .font(ClayFont.title)
                    Text("已答对 \(solvedIDs.count) / \(originalTotal) 题，退出后可以从这里继续")
                        .font(ClayFont.body)
                }.foregroundStyle(ClayColor.ink).multilineTextAlignment(.center)
            } actions: {
                ClayButton(title: "继续学习", id: "lesson-keep-learning") {
                    HapticEngine.shared.tap()
                    withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = false }
                }
                ClayButton(title: "退出", style: .cream, id: "lesson-quit") {
                    progressStore.clearLessonSession()
                    path.removeLast()
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Resume prompt overlay (ios-lesson-3)

    private var resumePromptOverlay: some View {
        ZStack {
            ClayColor.black.opacity(0.55).ignoresSafeArea()
            LessonDialog {
                VStack(spacing: 8) {
                    PetView(mood: .wave, size: 92)
                    Text("上次学到一半哦").font(ClayFont.title)
                    if let session = pendingResume {
                        Text("已答对 \(session.solvedIds.count) / \(originalTotal) 题，接着做还是重新来？")
                            .font(ClayFont.body)
                    }
                }.foregroundStyle(ClayColor.ink).multilineTextAlignment(.center)
            } actions: {
                ClayButton(title: "继续上次（第 \((pendingResume?.solvedIds.count ?? 0) + 1) 题）", id: "lesson-resume") {
                    HapticEngine.shared.tap()
                    if let session = pendingResume { applyResume(session) }
                    withAnimation(.easeOut(duration: 0.2)) { pendingResume = nil }
                }
                ClayButton(title: "重新开始", style: .cream, id: "lesson-restart") {
                    HapticEngine.shared.tap()
                    progressStore.clearLessonSession()
                    withAnimation(.easeOut(duration: 0.2)) { pendingResume = nil }
                }
            }
        }
        .transition(.opacity)
    }

    private func autoNarrate(_ q: Question) {
        guard settings.autoNarrate, !settings.isMuted else { return }
        guard let path = q.audio?.question else { return }
        audioPlayer.play(path: path, settings: settings)
    }

    // MARK: - Actions

    private func check(question: Question) {
        let ok = Grade.gradeAnswer(question: question, userAnswer: currentAnswer)
        feedbackTitleText = pickTitle(ok: ok)

        withAnimation(Motion.reveal) {
            phase = .checked
            isCorrect = ok
        }

        if ok {
            solvedIDs.insert(question.id)
            combo += 1; maxCombo = max(maxCombo, combo)
            // 连对升调(ios-lesson-12):第 1 连对是基准音,之后每级约 +1 半音,
            // 引擎内封顶 8 级 —— 连对越长音越亮。correct 即刻播,不错峰。
            SFXEngine.shared.play(.correct, pitchStep: combo - 1)
            HapticEngine.shared.correct()
            // Per-correct XP floater — mirrors the real per-question rate,
            // doubled on weekends / in unit challenges so the promise matches
            // the payout (both stack, same as the settlement formula).
            let floatXp = Economy.xpPerCorrect
                * (isExamLesson ? Economy.examXpMultiplier : 1)
                * (Economy.isWeekend() ? Economy.weekendXpMultiplier : 1)
            sessionXp += floatXp
            xpFloaters.append(XPFloatItem(amount: floatXp))
            if [3, 5, 10].contains(combo) {
                // 反馈错峰(ios-feel-17):让 correct 音先落定,0.32s 后连击横幅
                // 带着自己的音效(ComboOverlayView.onAppear 播 .combo)再登场。
                let milestone = combo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    comboDisplayValue = milestone
                    showCombo = true
                }
            }
        } else {
            attemptedThisQuestion = true
            missedIDs.insert(question.id)
            combo = 0
            queue.append(question)                       // re-practice later
            // 反馈错峰(ios-lesson-15):wrong 音 + error 触感即刻;
            // heartLoss 音 + heavy 触感延迟 0.4s,并把 loseHeart() 一起挪过去 ——
            // 红心图标的 symbolEffect(.bounce) 由 hearts 变化触发,这样掉心音、
            // 重触感、心数 bounce 三者同帧落地,而不是和 wrong 糊成一团。
            SFXEngine.shared.play(.wrong); HapticEngine.shared.wrong()
            if !reduceMotion { wrongFlash += 1 }         // 全屏闪红属强动效,Reduce Motion 下跳过
            pendingHeartLosses += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                progressStore.loseHeart()
                SFXEngine.shared.play(.heartLoss)
                HapticEngine.shared.heartLoss()
                pendingHeartLosses = max(0, pendingHeartLosses - 1)
            }
            progressStore.recordMistake(lessonId: lessonId, lessonTitle: lesson?.title, question: question)
        }

        // loseHeart() 被延迟了 0.4s,吉祥物的心数要按「悬账全部落定后」的值算
        // —— 快速连错时可能同时挂着不止一笔。
        let remainingHearts = max(0, progressStore.hearts - pendingHeartLosses)
        let ctx = MascotTriggerContext(
            isCorrect: ok,
            isPerfectSession: missedIDs.isEmpty,
            attemptCount: attemptedThisQuestion ? 2 : 1,
            remainingHearts: remainingHearts, combo: combo, maxCombo: maxCombo,
            index: solvedIDs.count, total: originalTotal, totalCorrectInSession: solvedIDs.count
        )
        mascotMood = MascotTriggers.decideMood(ctx)
        feedbackReaction = MascotTriggers.decideReaction(ctx)
        feedbackBubble = ok ? MascotTriggers.pickBubble(mood: mascotMood) : ""

        // 每次判定后立即落盘会话（ios-lesson-3）：App 被杀 / 断心退出后，
        // 下次进入同一课可从下一题无缝恢复。
        persistSession()
    }

    /// Persist the in-flight session. `queue[(index+1)...]` is the remaining
    /// queue as of "after this question" — a wrong answer already re-appended
    /// the question to the tail, so resuming never re-asks the front card.
    private func persistSession() {
        guard index + 1 <= queue.count else { return }
        let remaining = queue[(index + 1)...].map(\.id)
        // 全部答完（结算在即）就没有可恢复的会话了。
        guard solvedIDs.count < originalTotal, !remaining.isEmpty else { return }
        progressStore.upsertLessonSession(ActiveLessonSession(
            bookId: bookId,
            lessonId: lessonId,
            queueIds: Array(remaining),
            solvedIds: Array(solvedIDs).sorted(),
            missedIds: Array(missedIDs).sorted(),
            combo: combo,
            maxCombo: maxCombo,
            sessionXp: sessionXp,
            startedAt: sessionStartedAt
        ))
    }

    /// Restore runner state from a persisted session (resume path).
    private func applyResume(_ session: ActiveLessonSession) {
        guard let lesson else { return }
        let byId = Dictionary(uniqueKeysWithValues: lesson.questions.map { ($0.id, $0) })
        let restoredQueue = session.queueIds.compactMap { byId[$0] }
        // 课程内容更新导致队列失效 → 放弃恢复，从头来。
        guard !restoredQueue.isEmpty else {
            progressStore.clearLessonSession()
            return
        }
        queue = restoredQueue
        index = 0
        solvedIDs = Set(session.solvedIds).intersection(byId.keys)
        missedIDs = Set(session.missedIds).intersection(byId.keys)
        combo = session.combo
        maxCombo = session.maxCombo
        sessionXp = session.sessionXp
        sessionStartedAt = session.startedAt
        currentAnswer = ""
        isCorrect = nil
        phase = .answering
        attemptedThisQuestion = false
    }

    /// Called by the feedback panel's continue button. Gates on hearts.
    private func proceed(question: Question) {
        // 掉心账可能还悬在 0.4s 的延迟里(见 check),这里手动把**每一笔**都算
        // 进去,防止最后一颗红心「还没扣到界面上」时溜过断心闸门。
        let effectiveHearts = progressStore.hearts - pendingHeartLosses
        if !isCorrectValue && effectiveHearts <= 0 {
            withAnimation(.easeOut(duration: 0.2)) { showOutOfHearts = true }
            return
        }
        advance()
    }

    private var isCorrectValue: Bool { isCorrect ?? false }

    private func advance() {
        // progressTick 只在进度条真正前进(答对后的「继续」)时播(ios-lesson-20);
        // 答错后的「知道了」进度没动,只给轻触感。
        if isCorrectValue { SFXEngine.shared.play(.progressTick) }
        HapticEngine.shared.tap()
        guard let lesson else { return }
        if solvedIDs.count >= originalTotal || index + 1 >= queue.count {
            finish(lesson: lesson)
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                index += 1
                currentAnswer = ""
                isCorrect = nil
                phase = .answering
                attemptedThisQuestion = false
            }
        }
    }

    private func finish(lesson: Lesson) {
        // 首答口径：missedIDs 记录的是「首答就错过」的题，correctCount = 首答答对数。
        let correctCount = originalTotal - missedIDs.count
        let outcome = progressStore.completeLesson(lessonId: lessonId, correctCount: correctCount, questionCount: originalTotal)
        let result = LessonRunResult(
            bookId: bookId, lessonId: lessonId, lessonTitle: lesson.title,
            questionCount: originalTotal, correctCount: correctCount, outcome: outcome
        )
        path.removeLast(); path.append(.lessonResult(result))
    }

    private func pickTitle(ok: Bool) -> String {
        let pool = ok
            ? ["太棒了！", "完美！", "做得好！", "天才！", "继续保持！", "漂亮！"]
            : ["答错了", "差一点", "加油", "没关系", "下次就对！"]
        return pool.randomElement() ?? (ok ? "正确" : "答错了")
    }

    private func load() {
        do {
            let l = try DataLoader.shared.loadLesson(bookId: bookId, lessonId: lessonId)
            self.lesson = l
            self.queue = l.questions
            // 检测挂起会话（ios-lesson-3）：有实际进度才值得弹恢复层。
            if let session = progressStore.activeSession(for: lessonId),
               !session.solvedIds.isEmpty || !session.missedIds.isEmpty {
                self.pendingResume = session
            }
            // 课前知识讲解（content-2）：该课未完成、没看过讲解、也没有挂起
            // 会话（恢复优先）时，先进分步讲解再做题。
            if pendingResume == nil,
               l.knowledge != nil,
               !progressStore.isLessonCompleted(lessonId),
               !progressStore.hasSeenIntro(lessonId) {
                self.showIntro = true
            }
        } catch {
            self.loadError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }
}

// MARK: - Out-of-hearts gate

/// Blocking modal shown when the learner runs out of hearts mid-lesson.
/// Offers a gem refill, a review path that earns back one heart
/// (ios-lesson-7), or an exit, plus a live recharge countdown.
private struct OutOfHeartsGate: View {
    @ObservedObject var progressStore: ProgressStore
    let onRefill: () -> Void
    let onReview: () -> Void
    let onQuit: () -> Void

    private let refillCost = Economy.heartRefillCost
    @State private var tick = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hasDueMistakes: Bool { !progressStore.dueMistakes.isEmpty }

    var body: some View {
        ZStack {
            ClayColor.black.opacity(0.55).ignoresSafeArea()
            LessonDialog {
                VStack(spacing: 10) {
                    ClayIconView(icon: .heart).frame(width: 60, height: 60)
                    Text("红心用完了").font(ClayFont.title)
                    if let next = progressStore.nextHeartAt {
                        Text("下一颗红心还需").font(ClayFont.caption)
                        Text(countdown(to: next)).font(ClayFont.happy(size: 26)).foregroundStyle(ClayColor.balloonKnot)
                    }
                }.foregroundStyle(ClayColor.ink)
            } actions: {
                ClayButton(title: "用金币补满  \(refillCost)", style: .cream, id: "lesson-hearts-refill", action: onRefill)
                    .disabled(progressStore.gems < refillCost)
                if hasDueMistakes {
                    ClayButton(title: "做一组复习回 1 颗红心 ❤️", id: "hearts-review-earnback", action: onReview)
                    Text("这节课已帮你记住进度，复习完回来接着学")
                        .font(ClayFont.caption).foregroundStyle(ClayColor.ink).multilineTextAlignment(.center)
                }
                ClayButton(title: "退出练习", style: .cream, id: "lesson-hearts-quit", action: onQuit)
            }
        }
        .onReceive(timer) { _ in
            tick = Date()
            progressStore.tickHeartRecharge()
        }
    }

    private func countdown(to date: Date) -> String {
        let remaining = max(0, date.timeIntervalSince(tick))
        return String(format: "%d:%02d", Int(remaining) / 60, Int(remaining) % 60)
    }
}
