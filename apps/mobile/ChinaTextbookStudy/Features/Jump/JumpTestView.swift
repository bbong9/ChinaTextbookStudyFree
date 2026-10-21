import SwiftUI

/// 跳级测试（Wave E2，jump ahead）—— 锁定单元 banner「⚡ 跳到这里」入口。
///
/// 口径（双端一致）：
///   - 从目标单元之前所有单元的课程题库均匀抽 15 题，无课前讲解、无跳过；
///   - 每题只答一次（答错不重练、不扣心、不进错题本 —— 合成会话）；
///   - 正确率 ≥ 0.80 通过：前置未完成课程批量 completed{stars:1, accuracy:0.8}，
///     不发 XP / 宝石，庆祝后回路径（视口自动落到新当前节点）；
///   - 失败：扣 1 颗红心，可换一套题重试（0 心时给补心入口）。
struct JumpTestView: View {
    let bookId: String
    let unitNumber: Int
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]

    private enum Stage {
        case briefing        // 规则说明
        case running         // 做题中
        case passed(Int)     // 通过（解锁课程数）
        case failed(Int)     // 未通过（答对题数）
    }

    @State private var stage: Stage = .briefing
    @State private var questions: [Jump.SampledQuestion] = []
    /// 前置未完成课程 id（通过时批量标记）。
    @State private var priorUncompletedIds: [String] = []
    @State private var loadError: String?
    @State private var attempt = 1

    // Runner state（轻量：一题一次，不重练）
    @State private var index = 0
    @State private var currentAnswer = ""
    @State private var phase: LessonRunnerView.QuestionPhase = .answering
    @State private var isCorrect: Bool?
    @State private var correctCount = 0
    @State private var showConfetti = false
    @State private var showQuitConfirm = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var total: Int { max(1, questions.count) }
    private var progress: Double { Double(index) / Double(total) }
    private var accuracy: Double { Double(correctCount) / Double(total) }

    var body: some View {
        Group {
            switch stage {
            case .briefing:
                briefing
            case .running:
                if let loadError {
                    errorView(loadError)
                } else if index < questions.count {
                    runner(question: questions[index].question)
                } else {
                    ProgressView().tint(DuoColors.primary)
                }
            case .passed(let unlocked):
                passedView(unlocked: unlocked)
            case .failed(let correct):
                failedView(correct: correct)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DuoColors.bg.ignoresSafeArea())
        .environment(\.petEnvironment, PetEnvironment(progressStore: progressStore))
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
        .navigationBarHidden(true)
        .task { prepare() }
    }

    // MARK: - Briefing

    private var briefing: some View {
        LessonInterlude(bookId: bookId, title: "跳级测试", subtitle: "证明你已经掌握了前面的内容，就能直接跳到第 \(unitNumber) 单元！") {
            closeButton
        } detail: {
            VStack(alignment: .leading, spacing: 8) {
                briefRow(icon: "list.number", text: "\(Jump.testSize) 道题，来自前面所有单元")
                briefRow(icon: "target", text: "答对 80% 以上就通过")
                briefRow(icon: "heart.fill", text: "没通过会扣 1 颗心，可以再试")
                briefRow(icon: "bolt.slash.fill", text: "跳过的课程不发经验和金币")
            }
        } actions: {
            ClayButton(title: "开始测试", id: "jump-start") {
                HapticEngine.shared.tap()
                SFXEngine.shared.play(.tap)
                withAnimation(Motion.reveal) { stage = .running }
            }
            .disabled(questions.isEmpty && loadError == nil)
            ClayButton(title: "我再想想", style: .cream, id: "jump-cancel") { path.removeLast() }
        }
    }

    private func briefRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(DuoColors.secondary)
                .frame(width: 24)
            Text(text)
                .duoFont(.caption)
                .foregroundStyle(DuoColors.ink)
        }
    }

    // MARK: - Runner

    @ViewBuilder
    private func runner(question q: Question) -> some View {
        LessonShell(bookId: bookId, question: q, instruction: "跳级测试 · 每题一次机会", checked: phase == .checked,
                    mood: isCorrect == false ? .think : .happy) {
            LessonHeader(progress: progress, count: "\(index + 1)/\(total)") {
                closeButton
            } trailing: {
                Text("⚡ 跳级").font(ClayFont.largeButton).foregroundStyle(ClayColor.creamText)
            }
        } answers: {
            QuestionRendererView(question: q, answer: currentAnswer, phase: phase,
                                 isCorrect: isCorrect, onChange: { currentAnswer = $0 })
                .id("jump-\(attempt)-\(index)")
        } action: {
            checkFooter(question: q)
        } feedback: {
            if phase == .checked, let ok = isCorrect { jumpFeedback(ok: ok, question: q) }
        }
        .overlay { if showQuitConfirm { quitConfirmOverlay } }
    }

    private func checkFooter(question: Question) -> some View {
        let empty = currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ClayButton(title: "检查", id: "检查答案") {
            let ok = Grade.gradeAnswer(question: question, userAnswer: currentAnswer)
            withAnimation(Motion.reveal) {
                phase = .checked
                isCorrect = ok
            }
            if ok {
                correctCount += 1
                SFXEngine.shared.play(.correct)
                HapticEngine.shared.correct()
            } else {
                // 测试口径：不扣心、不进错题本，只记分。
                SFXEngine.shared.play(.wrong)
                HapticEngine.shared.wrong()
            }
        }
        .disabled(empty).opacity(empty ? 0.55 : 1)
    }

    private func jumpFeedback(ok: Bool, question: Question) -> some View {
        LessonFeedback(ok: ok) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ok ? "答对了！" : "这题不对").font(ClayFont.title)
                if !ok { Text("正确答案：\(MathText.render(question.answer))").font(ClayFont.body) }
            }.foregroundStyle(ok ? ClayColor.greenEdge : ClayColor.balloonKnot)
        } action: {
            ClayButton(title: index + 1 >= total ? "看结果" : "继续", id: "jump-continue") { advance() }
        }
    }

    private func advance() {
        SFXEngine.shared.play(.progressTick)
        HapticEngine.shared.tap()
        if index + 1 >= total {
            finish()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                index += 1
                currentAnswer = ""
                isCorrect = nil
                phase = .answering
            }
        }
    }

    private func finish() {
        if accuracy >= Jump.passAccuracy {
            // 通过：前置未完成课程批量标记（无 XP / 宝石），庆祝。
            let unlocked = progressStore.applyJumpUnlock(lessonIds: priorUncompletedIds)
            SFXEngine.shared.play(.complete)
            HapticEngine.shared.success()
            withAnimation(Motion.reveal) { stage = .passed(unlocked) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showConfetti = true }
        } else {
            // 失败：扣 1 颗红心，可重试。
            progressStore.loseHeart()
            SFXEngine.shared.play(.heartLoss)
            HapticEngine.shared.heartLoss()
            withAnimation(Motion.reveal) { stage = .failed(correctCount) }
        }
    }

    // MARK: - Passed

    private func passedView(unlocked: Int) -> some View {
        LessonInterlude(bookId: bookId, title: "跳级成功！",
                        subtitle: "正确率 \(Int(round(accuracy * 100)))%，前面的 \(unlocked) 节课都算你过啦", mood: .proud) {
            EmptyView()
        } detail: {
            Text("现在可以从第 \(unitNumber) 单元继续冒险 🗺️").font(ClayFont.body)
        } actions: {
            ClayButton(title: "回到路径", id: "jump-pass-continue") {
                HapticEngine.shared.tap()
                path.removeAll()
            }
        }
        .overlay { ConfettiView(active: showConfetti).ignoresSafeArea().allowsHitTesting(false) }
    }

    private func failedView(correct: Int) -> some View {
        let canRetry = progressStore.hearts > 0
        let canRefill = progressStore.gems >= Economy.heartRefillCost
        return LessonInterlude(bookId: bookId, title: "还差一点点",
                               subtitle: "答对了 \(correct) / \(total) 题（需要 \(Int(Jump.passAccuracy * 100))%）\n先把前面的课程学扎实，或者再试一次！", mood: .sad) {
            EmptyView()
        } detail: {
            StatPill(icon: .heart, text: "已扣 1 颗心 · 剩余 \(progressStore.hearts)")
        } actions: {
            if canRetry {
                ClayButton(title: "换一套题再试", id: "jump-retry") {
                    HapticEngine.shared.tap()
                    retry()
                }
            } else {
                ClayButton(title: "用金币补满心再试  \(Economy.heartRefillCost)", id: "jump-refill") {
                    if progressStore.buyHeartRefill(cost: Economy.heartRefillCost) {
                        HapticEngine.shared.success()
                        SFXEngine.shared.play(.unlock)
                        retry()
                    } else {
                        HapticEngine.shared.wrong()
                    }
                }.disabled(!canRefill)
            }
            ClayButton(title: "下次再来", style: .cream, id: "jump-later") { path.removeLast() }
        }
    }

    /// 换一套题重试：新 seed 重抽，状态清零。
    private func retry() {
        attempt += 1
        index = 0
        correctCount = 0
        currentAnswer = ""
        isCorrect = nil
        phase = .answering
        sampleQuestions()
        withAnimation(Motion.reveal) { stage = .running }
    }

    // MARK: - Quit confirm

    private var closeButton: some View {
        ClayIconButton(icon: .back, id: "jump-close", label: "关闭") {
            if case .running = stage, index > 0 || phase == .checked {
                HapticEngine.shared.tap()
                withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = true }
            } else {
                path.removeLast()
            }
        }
    }

    private var quitConfirmOverlay: some View {
        ZStack {
            ClayColor.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = false } }
            LessonDialog {
                VStack(spacing: 10) {
                    PetView(mood: .sad, size: 92)
                    Text("现在退出，测试不算数哦").font(ClayFont.title)
                    Text("退出不扣心，下次可以重新来").font(ClayFont.body)
                }.foregroundStyle(ClayColor.ink)
            } actions: {
                ClayButton(title: "继续测试", id: "jump-keep") {
                    withAnimation(.easeOut(duration: 0.2)) { showQuitConfirm = false }
                }
                ClayButton(title: "退出", style: .cream, id: "jump-quit") { path.removeLast() }
            }
        }.transition(.opacity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Space.m) {
            Text("加载失败").duoFont(.heading)
            Text(message).duoFont(.caption).foregroundStyle(DuoColors.inkMuted)
            Button("返回") { path.removeLast() }
                .buttonStyle(ChunkyButtonStyle(.ghost))
                .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Data

    /// 收集目标单元之前所有普通课（kp 课，不含单元挑战）的题库与
    /// 未完成课程清单，然后抽第一套题。
    private func prepare() {
        do {
            let outline = try DataLoader.shared.loadOutline(bookId: bookId)
            let priorMetas = outline
                .pathLessonMetas(bookId: bookId)
                .filter { $0.unitNumber < unitNumber }
            guard !priorMetas.isEmpty else {
                loadError = "前面没有可以测试的课程"
                return
            }
            priorUncompletedIds = priorMetas
                .map(\.id)
                .filter { !progressStore.isLessonCompleted($0) }
            jumpSources = priorMetas.compactMap { meta in
                guard let lesson = try? DataLoader.shared.loadLesson(bookId: bookId, lessonId: meta.id),
                      !lesson.questions.isEmpty
                else { return nil }
                return Jump.QuestionSource(lessonId: meta.id, questions: lesson.questions)
            }
            guard !jumpSources.isEmpty else {
                loadError = "题库还没下载好，先回去下载课本吧"
                return
            }
            sampleQuestions()
        } catch {
            loadError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    /// 前置课程题库缓存（重试重抽不用重读文件）。
    @State private var jumpSources: [Jump.QuestionSource] = []

    private func sampleQuestions() {
        questions = Jump.sampleQuestions(
            sources: jumpSources,
            seed: "jump-\(bookId)-u\(unitNumber)-\(attempt)-\(progressStore.leagueSalt ?? "local")"
        )
    }
}
