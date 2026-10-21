import SwiftUI

/// 原故事数据、判分与 Reading 记账保留；阅读阶段替换成一句一页的绘本。
struct StoryReaderView: View {
    let bookId: String
    let storyId: String
    var bedtime = false

    private enum Phase { case reading, quiz, result, completion, goodnight }
    @State private var story: Story?
    @State private var pinyin: [[String]]?
    @State private var phase: Phase = .reading
    @State private var loadFailed = false
    @State private var narratedPages: Set<Int> = []
    @State private var qIndex = 0
    @State private var qPhase: LessonRunnerView.QuestionPhase = .answering
    @State private var currentAnswer = ""
    @State private var isCorrect: Bool?
    @State private var correctCount = 0
    @State private var awarded = false
    @ObservedObject private var progressStore = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var storyRewardId: String { Reading.id(.story, storyId) }

    var body: some View {
        Group {
            if let story {
                switch phase {
                case .reading:
                    StoryBookView(story: story, pinyin: pinyin, bedtime: bedtime,
                                  onExit: { dismiss() }, onFinished: finishReading,
                                  onNarratedPage: { narratedPages.insert($0) })
                case .quiz: quizPhase(story)
                case .result: resultPhase(story)
                case .completion: completionPhase(story)
                case .goodnight: goodnight
                }
            } else if loadFailed {
                VStack(spacing: 16) {
                    Text("故事暂时打不开").font(ClayFont.title)
                    ClayButton(title: "返回书架", id: "story-load-back") { dismiss() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ClayColor.creamTop)
            } else { ProgressView() }
        }
        .environment(\.petEnvironment, PetEnvironment(progressStore: progressStore))
        .task {
            story = (try? DataLoader.shared.loadStories(bookId: bookId))?.stories.first { $0.id == storyId }
            if let story {
                pinyin = StoryReading.pinyin(DataLoader.shared.loadStoryPinyin(bookId: bookId)?[storyId], for: story)
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-uitest-story-no-pinyin") { pinyin = nil }
                #endif
            }
            loadFailed = story == nil
        }
        .onDisappear { AudioPlayer.shared.stop() }
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
    }

    private func finishReading(_ ending: StoryPageFlow.Ending) {
        AudioPlayer.shared.stop()
        switch ending {
        case .goodnight: phase = .goodnight
        case .completion: phase = .completion
        case .quiz:
            qIndex = 0; currentAnswer = ""; qPhase = .answering; isCorrect = nil; correctCount = 0
            phase = .quiz
        }
    }

    private var goodnight: some View {
        Stage { _ in StoryNightScene().overlay(ClayColor.black.opacity(0.32)) } content: { ctx in
            VStack(spacing: 20) {
                Text("晚安").font(ClayFont.happy(size: 44)).foregroundStyle(ClayColor.white)
                    .accessibilityIdentifier("story-goodnight")
                Text("故事听完啦，做个甜甜的梦吧").font(ClayFont.body).foregroundStyle(ClayColor.white)
                ClayButton(title: "回到书架", style: .cream, id: "story-goodnight-back") { dismiss() }
            }.position(x: ctx.size.width / 2, y: ctx.size.height / 2)
        }
        // 睡前模式没有 completeReading，也不发 XP，不改系统亮度。
    }

    private func quizPhase(_ story: Story) -> some View {
        let q = Self.question(from: story.questions[qIndex])
        return LessonShell(bookId: bookId, question: q, instruction: "阅读理解", checked: qPhase == .checked) {
            LessonHeader(progress: Double(qIndex + (qPhase == .checked ? 1 : 0)) / Double(story.questions.count),
                         count: "\(qIndex + 1)/\(story.questions.count)") {
                ClayIconButton(icon: .back, id: "story-quiz-back", label: "返回故事") {
                    AudioPlayer.shared.stop(); phase = .reading
                }
            } trailing: { EmptyView() }
        } answers: {
            QuestionRendererView(question: q, answer: currentAnswer, phase: qPhase,
                                 isCorrect: isCorrect, onChange: { currentAnswer = $0 }).id(q.id)
        } action: {
            ClayButton(title: "检查", id: "story-quiz-check") { check(q) }
                .disabled(currentAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(currentAnswer.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        } feedback: {
            LessonFeedback(ok: isCorrect == true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isCorrect == true ? "答对了！" : "正确答案：\(MathText.render(q.answer))")
                        .font(ClayFont.largeButton)
                    Text(MathText.render(q.explanation)).font(ClayFont.body)
                }.foregroundStyle(ClayColor.ink)
            } action: {
                ClayButton(title: qIndex + 1 >= story.questions.count ? "看结果" : "下一题", id: "story-quiz-next") { advance(story) }
            }
        }
    }

    private func check(_ q: Question) {
        let ok = Grade.gradeAnswer(question: q, userAnswer: currentAnswer)
        withAnimation(Motion.reveal) { isCorrect = ok; qPhase = .checked }
        if ok {
            correctCount += 1
            SFXEngine.shared.play(.correct); HapticEngine.shared.correct()
        } else {
            SFXEngine.shared.play(.wrong); HapticEngine.shared.wrong()
        }
    }

    private func advance(_ story: Story) {
        AudioPlayer.shared.stop()
        SFXEngine.shared.play(.progressTick); HapticEngine.shared.tap()
        if qIndex + 1 < story.questions.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                qIndex += 1; currentAnswer = ""; isCorrect = nil; qPhase = .answering
            }
        } else { withAnimation(Motion.reveal) { phase = .result } }
    }

    private func accuracy(_ story: Story) -> Double {
        guard !story.questions.isEmpty else { return 1 }
        return Double(correctCount) / Double(story.questions.count)
    }

    private func stars(_ story: Story) -> Int {
        let a = accuracy(story)
        return a >= 0.95 ? 3 : (a >= 0.75 ? 2 : 1)
    }

    private func resultPhase(_ story: Story) -> some View {
        let acc = accuracy(story)
        let xp = Economy.storyQuizXp(accuracy: acc)
        let alreadyDone = progressStore.isReadingCompleted(storyRewardId)
        return LessonInterlude(bookId: bookId, title: acc >= Economy.ReadingXP.goodThreshold ? "读得真棒！" : "读完啦！",
                               subtitle: "答对 \(correctCount) / \(story.questions.count) 题 · 正确率 \(Int((acc * 100).rounded()))%",
                               mood: acc >= Economy.ReadingXP.goodThreshold ? .proud : .think) {
            ClayIconButton(icon: .back, id: "story-result-back") { dismiss() }
        } detail: {
            StarRevealView(earnedStars: stars(story))
            Text(alreadyDone && !awarded ? "已领过奖励" : "+\(xp) XP")
                .font(ClayFont.title).accessibilityIdentifier("story-result-xp")
        } actions: {
            ClayButton(title: "完成", id: "story-result-done") { dismiss() }
        }
        .onAppear {
            guard !bedtime, !awarded else { return }
            if !alreadyDone {
                awarded = true
                progressStore.completeReading(id: storyRewardId, xp: xp)
            }
            SFXEngine.shared.play(.complete); HapticEngine.shared.success()
        }
    }

    private func completionPhase(_ story: Story) -> some View {
        let done = progressStore.isReadingCompleted(storyRewardId)
        let audioReady = AudioPlayer.shared.hasAnyResolvable(story.sentences.map(\.audio))
        let eligible = done || narratedPages.count == story.sentences.count || !audioReady
        return LessonInterlude(bookId: bookId, title: "故事读完啦", subtitle: eligible ? "把故事里的温暖带回家吧" : "先听完整个故事，就能领奖励啦") {
            ClayIconButton(icon: .back, id: "story-completion-back") { dismiss() }
        } detail: { EmptyView() } actions: {
            ClayButton(title: done ? "已读完 ✓" : "读完了 +\(Economy.ReadingXP.storyGood) XP", id: "story-complete") {
                guard !bedtime, !done, eligible else { return }
                progressStore.completeReading(id: storyRewardId, xp: Economy.ReadingXP.storyGood)
            }.disabled(done || !eligible)
            ClayButton(title: "再听一遍", style: .cream, id: "story-read-again") { phase = .reading }
        }
    }

    // MARK: - Adapter

    static func question(from q: StoryQuestion) -> Question {
        let type: QuestionType
        switch q.type {
        case "true_false": type = .trueFalse
        case "choice": type = .choice
        default: type = .fillBlankText
        }
        return Question(
            id: q.id, type: type, score: 1, difficulty: 1, knowledgePoint: "",
            question: q.question, options: q.options, answer: q.answer,
            explanation: q.explanation, audio: q.audio
        )
    }
}
