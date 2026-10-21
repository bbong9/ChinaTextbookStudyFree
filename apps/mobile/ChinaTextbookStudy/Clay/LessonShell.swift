import SwiftUI

private struct LessonKeyboardVisibleKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var lessonKeyboardVisible: Bool {
        get { self[LessonKeyboardVisibleKey.self] }
        set { self[LessonKeyboardVisibleKey.self] = newValue }
    }
}

/// 普通课、跳级与错题复习共用的展示壳；答案、判分和推进均由调用者持有。
struct LessonShell<Header: View, Answers: View, Action: View, Feedback: View>: View {
    let bookId: String
    let question: Question
    let instruction: String
    let checked: Bool
    var slowNarration = false
    var mood: MascotMood = .happy
    var reaction: MascotReaction? = nil
    var reactionKey = 0
    @ViewBuilder let header: () -> Header
    @ViewBuilder let answers: () -> Answers
    @ViewBuilder let action: () -> Action
    @ViewBuilder let feedback: () -> Feedback

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        Stage(background: { _ in LessonScene(bookId: bookId) }) { ctx in
            let keyboard = keyboardHeight > 0
            let bottom = keyboard ? keyboardHeight / ctx.scale : ctx.safeArea.bottom
            let width = ctx.size.width - ctx.safeArea.leading - ctx.safeArea.trailing - 32
            let availableHeight = max(0, ctx.size.height - bottom - ctx.safeArea.top)
            VStack(spacing: keyboard ? 6 : 12) {
                header()
                HStack(alignment: .top, spacing: 18) {
                    LessonPromptCard(question: question, instruction: instruction, mood: mood,
                                     reaction: checked ? reaction : nil, reactionKey: reactionKey, slowNarration: slowNarration)
                        .frame(width: (width - 18) * 0.46)
                    VStack(spacing: 6) {
                        answers().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        if !checked { action().frame(maxWidth: .infinity, alignment: .trailing) }
                    }
                    .frame(width: (width - 18) * 0.54)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.top, keyboard ? 6 : 16)
            .padding(.bottom, keyboard ? 6 : 12)
            .frame(width: width, height: availableHeight)
            .offset(x: ctx.safeArea.leading + 16, y: ctx.safeArea.top)
            .environment(\.lessonKeyboardVisible, keyboard)

            if checked {
                feedback()
                    .frame(width: ctx.size.width, height: ctx.size.height * 0.34)
                    .position(x: ctx.size.width / 2, y: ctx.size.height * 0.83)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = max(0, UIScreen.main.bounds.maxY - frame.minY)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardHeight = 0 }
        .transaction { if reduceMotion { $0.animation = nil; $0.disablesAnimations = true } }
    }
}

struct LessonHeader<Leading: View, Trailing: View>: View {
    let progress: Double
    let count: String
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            leading()
            HStack(spacing: 12) {
                GeometryReader { proxy in
                    Capsule().fill(ClayColor.white.opacity(0.16))
                    ClayGradient.buttonOrange.view.clipShape(Capsule())
                        .frame(width: proxy.size.width * min(1, max(0, progress)))
                }
                .frame(height: 12)
                Text(count).font(ClayFont.number).foregroundStyle(ClayColor.white).fixedSize()
            }
            .padding(.horizontal, 14).frame(height: 48)
            .background(ClayColor.darkPill, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("答题进度")
            .accessibilityValue(count)
            .accessibilityIdentifier("lesson-progress")
            trailing()
        }
    }
}

struct LessonPromptCard: View {
    let question: Question
    let instruction: String
    var mood: MascotMood = .happy
    var reaction: MascotReaction? = nil
    var reactionKey = 0
    var slowNarration = false
    @Environment(\.lessonKeyboardVisible) private var compact
    @Environment(\.petEnvironment) private var pet

    var body: some View {
        if compact {
            HStack(spacing: 6) {
                Text(MathText.render(question.question)).font(ClayFont.body).lineLimit(1)
                    .accessibilityIdentifier("lesson-prompt-summary")
                narration
            }
            .padding(12).clayLessonCard()
        } else {
            ZStack(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(instruction).font(ClayFont.largeButton).foregroundStyle(ClayColor.creamText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        narration
                    }
                    ScrollView {
                        Text(MathText.render(question.question))
                            .font(ClayFont.body).foregroundStyle(ClayColor.ink)
                            .lineSpacing(5).frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .accessibilityIdentifier("lesson-prompt-scroll")
                }
                .padding(16).clayLessonCard()
                .padding(.bottom, 42)
                HStack(alignment: .bottom, spacing: 4) {
                    PetView(mood: mood, size: 76, reactTo: reaction, reactKey: reactionKey)
                    Text("\(pet.kind.name)陪你一起学").font(ClayFont.label)
                        .foregroundStyle(ClayColor.ink)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(ClayColor.creamTop, in: Capsule())
                        .padding(.bottom, 8)
                }
                .padding(.leading, 8)
            }
        }
    }
    @ViewBuilder private var narration: some View {
        if slowNarration { SlowTTSButton(path: question.audio?.question).clayHitTarget() }
        else { TTSButton(path: question.audio?.question).clayHitTarget() }
    }

}

/// 内容允许内部滚动，右侧推进按钮始终留在反馈面板内。
struct LessonFeedback<Detail: View, Action: View>: View {
    let ok: Bool
    @ViewBuilder let detail: () -> Detail
    @ViewBuilder let action: () -> Action
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 20) {
                ScrollView { detail().frame(maxWidth: .infinity, alignment: .leading) }
                action().frame(width: max(160, geometry.size.width * 0.25))
            }
            .padding(.horizontal, geometry.safeAreaInsets.leading + 24)
            .padding(.top, 10).padding(.bottom, max(10, geometry.safeAreaInsets.bottom))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ok ? ClayColor.hillHighlight : ClayColor.bookPicture)
        .overlay(alignment: .top) {
            Rectangle().fill(ok ? ClayColor.completed : ClayColor.balloonKnot).frame(height: 3)
        }
    }
}

struct LessonDialog<Info: View, Actions: View>: View {
    @ViewBuilder let info: () -> Info
    @ViewBuilder let actions: () -> Actions
    var body: some View {
        HStack(spacing: 24) {
            ScrollView { info().frame(maxWidth: .infinity) }
            VStack(spacing: 10, content: actions).frame(maxWidth: .infinity)
        }
        .padding(24).frame(maxWidth: 700, maxHeight: 300)
        .clayLessonCard().padding(16)
    }
}

struct LessonSymbolButton: View {
    let symbol: String
    let label: String
    let id: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(ClayFont.largeButton).foregroundStyle(ClayColor.orange)
                .frame(width: 48, height: 48)
                .claySurface(.buttonCream, radius: ClayRadius.button, edge: ClayColor.creamEdge, shadow: .icon)
                .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).accessibilityLabel(label).accessibilityIdentifier(id)
    }
}

/// 复用横屏场景与卡片的说明 / 结果展示，不承担测试和复习的结算。
struct LessonInterlude<Leading: View, Detail: View, Actions: View>: View {
    let bookId: String
    let title: String
    let subtitle: String
    var mood: MascotMood = .happy
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let detail: () -> Detail
    @ViewBuilder let actions: () -> Actions
    var body: some View {
        Stage(background: { _ in LessonScene(bookId: bookId) }) { ctx in
            VStack(spacing: 10) {
                HStack { leading(); Spacer(); Text(title).font(ClayFont.title); Spacer() }
                HStack(spacing: 24) {
                    ScrollView {
                        VStack(spacing: 10) {
                            PetView(mood: mood, size: 84)
                            Text(subtitle).font(ClayFont.body).multilineTextAlignment(.center)
                            detail()
                        }.frame(maxWidth: .infinity).padding(16)
                    }
                    .clayLessonCard()
                    VStack(spacing: 10, content: actions).frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(ClayColor.ink)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .frame(width: ctx.size.width - ctx.safeArea.leading - ctx.safeArea.trailing,
                   height: ctx.size.height - ctx.safeArea.top - ctx.safeArea.bottom)
            .offset(x: ctx.safeArea.leading, y: ctx.safeArea.top)
        }
    }
}

extension View {
    func clayLessonCard(edge: Color = ClayColor.creamEdge) -> some View {
        background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.card))
            .overlay { RoundedRectangle(cornerRadius: ClayRadius.card).strokeBorder(ClayColor.white, lineWidth: 4) }
            .compositingGroup()
            .shadow(color: edge, radius: 0, y: 6)
            .clayShadow(.panel)
    }
}
