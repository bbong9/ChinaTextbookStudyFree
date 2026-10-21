import SwiftUI

/// 8 种题型共用原答案字符串接口；这里只负责横屏作答区。
///
/// Each sub-view is a controlled component: the parent owns `answer` and
/// `phase` (.answering | .checked); the child calls `onChange` with the
/// stringified answer, mirroring `Grade.gradeAnswer` exactly.

// MARK: - Dispatcher

struct QuestionRendererView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let isCorrect: Bool?
    let onChange: (String) -> Void

    var body: some View {
        switch question.type {
        case .choice:
            ChoiceQuestionView(question: question, answer: answer, phase: phase, isCorrect: isCorrect, onChange: onChange)
        case .trueFalse:
            TrueFalseQuestionView(question: question, answer: answer, phase: phase, isCorrect: isCorrect, onChange: onChange)
        case .fillBlank, .calculation, .wordProblem:
            FillBlankQuestionView(question: question, answer: answer, phase: phase, isCorrect: isCorrect, onChange: onChange, keyboard: .decimalPad)
        case .fillBlankText:
            FillBlankQuestionView(question: question, answer: answer, phase: phase, isCorrect: isCorrect, onChange: onChange, keyboard: .default)
        case .wordOrder:
            WordOrderQuestionView(question: question, answer: answer, phase: phase, onChange: onChange)
        case .matching:
            MatchingQuestionView(question: question, answer: answer, phase: phase, onChange: onChange)
        }
    }
}

// MARK: - Choice

private struct ChoiceQuestionView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let isCorrect: Bool?
    let onChange: (String) -> Void

    @State private var shakeTrigger = 0

    var body: some View {
        Group {
            if question.options.count > 4 {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(question.options.indices, id: \.self) { option($0) }
                    }.padding(4)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(question.options.indices, id: \.self) { option($0) }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .checked, isCorrect == false {
                withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
            }
        }
    }

    private func option(_ i: Int) -> some View {
        let opt = question.options[i]
        let letter = letterFor(i)
        let isSelected = answer.uppercased() == letter
        let state = cardState(letter: letter, isSelected: isSelected)
        return Button {
            guard phase == .answering else { return }
            HapticEngine.shared.tap()
            SFXEngine.shared.play(.tap)
            withAnimation(Motion.press) { onChange(letter) }
            if let optAudio = question.audio?.options?[safe: i] ?? nil {
                AudioPlayer.shared.play(path: optAudio)
            }
        } label: {
            HStack(spacing: 8) {
                Text(MathText.render(opt)).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                checkMark(for: state)
            }
            .padding(12).frame(minHeight: 74)
        }
        .buttonStyle(LessonOptionStyle(state: state))
        .disabled(phase == .checked)
        .modifier(ShakeEffect(animatableData: CGFloat(state == .wrong ? shakeTrigger : 0)))
        .accessibilityLabel(MathText.render(opt))
        .accessibilityIdentifier("lesson-choice-\(i)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(optionA11yValue(for: state))
    }

    private func cardState(letter: String, isSelected: Bool) -> OptionCardState {
        guard phase == .checked else { return isSelected ? .selected : .default }
        if Grade.gradeAnswer(question: question, userAnswer: letter) { return .correct }
        if isSelected { return .wrong }
        return .disabled
    }

    private func letterFor(_ i: Int) -> String {
        guard let scalar = Unicode.Scalar(65 + i) else { return "?" }
        return String(scalar)
    }
}

/// VoiceOver：判卷后把「对 / 错」读出来（ios-lesson-21）。
private func optionA11yValue(for state: OptionCardState) -> String {
    switch state {
    case .correct: return "正确答案"
    case .wrong:   return "答错了"
    case .selected: return "已选择"
    default:       return ""
    }
}

@ViewBuilder
private func checkMark(for state: OptionCardState) -> some View {
    switch state {
    case .correct:
        Image(systemName: "checkmark.circle.fill")
            .font(ClayFont.largeButton)
            .foregroundStyle(ClayColor.greenEdge)
    case .wrong:
        Image(systemName: "xmark.circle.fill")
            .font(ClayFont.largeButton)
            .foregroundStyle(ClayColor.balloonKnot)
    default:
        EmptyView()
    }
}

// MARK: - True / False

private struct TrueFalseQuestionView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let isCorrect: Bool?
    let onChange: (String) -> Void

    @State private var shakeTrigger = 0

    var body: some View {
        HStack(spacing: 16) {
            tile(label: "对", value: "对", icon: "checkmark.circle.fill")
            tile(label: "错", value: "错", icon: "xmark.circle.fill")
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .checked, isCorrect == false {
                withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
            }
        }
    }

    private func tile(label: String, value: String, icon: String) -> some View {
        let isSelected = answer == value
        let state = tfCardState(value: value, isSelected: isSelected)
        return Button {
            guard phase == .answering else { return }
            HapticEngine.shared.tap()
            SFXEngine.shared.play(.tap)
            withAnimation(Motion.press) { onChange(value) }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(ClayFont.happy(size: 34))
                Text(label).font(ClayFont.title)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(12)
        }
        .buttonStyle(LessonOptionStyle(state: state))
        .disabled(phase == .checked)
        .modifier(ShakeEffect(animatableData: CGFloat(state == .wrong ? shakeTrigger : 0)))
        .accessibilityLabel(label + (value == "对" ? "，正确" : "，错误"))
        .accessibilityIdentifier("tf-\(value)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(optionA11yValue(for: state))
    }

    private func tfCardState(value: String, isSelected: Bool) -> OptionCardState {
        guard phase == .checked else { return isSelected ? .selected : .default }
        if Grade.gradeAnswer(question: question, userAnswer: value) { return .correct }
        if isSelected { return .wrong }
        return .disabled
    }
}

// MARK: - Fill blank (numeric / text)

private struct FillBlankQuestionView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let isCorrect: Bool?
    let onChange: (String) -> Void
    let keyboard: UIKeyboardType

    @State private var shakeTrigger = 0
    @FocusState private var textFocused: Bool
    @Environment(\.clayStageScale) private var scale

    private var state: OptionCardState {
        guard phase == .checked else { return answer.isEmpty ? .default : .selected }
        return (isCorrect ?? false) ? .correct : .wrong
    }

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if keyboard == .default {
                    TextField("在这里作答", text: Binding(get: { answer }, set: onChange))
                        .keyboardType(.default).textInputAutocapitalization(.never)
                        .autocorrectionDisabled().focused($textFocused)
                        .submitLabel(.done).onSubmit { textFocused = false }
                        .font(ClayFont.body)
                } else {
                    Text(answer.isEmpty ? "输入数字" : answer)
                        .font(ClayFont.happy(size: 26))
                        .accessibilityValue(answer.isEmpty ? "尚未输入" : answer)
                }
            }
            .foregroundStyle(state == .wrong ? ClayColor.balloonKnot : ClayColor.ink)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: max(44, 44 / scale), alignment: .leading)
            .background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
            .overlay {
                RoundedRectangle(cornerRadius: ClayRadius.smallButton)
                    .strokeBorder(state == .wrong ? ClayColor.balloonKnot : state == .correct ? ClayColor.greenEdge : ClayColor.orange, lineWidth: 3)
            }
            .accessibilityLabel("答案")
            .accessibilityIdentifier("lesson-\(question.type.rawValue)-0")
            .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
            .disabled(phase == .checked)
            if keyboard != .default {
                LessonNumberPad(answer: answer, idPrefix: "lesson-\(question.type.rawValue)", onChange: onChange)
                    .disabled(phase == .checked)
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .checked {
                textFocused = false
                if isCorrect == false {
                    withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
                }
            }
        }
    }
}

// MARK: - Word order

private struct WordOrderQuestionView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let onChange: (String) -> Void

    @State private var picked: [Int] = []
    @Namespace private var ns

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(picked.isEmpty ? "点下面的词，组成句子" : "点词块可以放回去")
                        .font(ClayFont.caption).foregroundStyle(ClayColor.creamText)
                    FlowRow {
                        ForEach(picked, id: \.self) { i in
                            chip(text: question.options[i], filled: true, id: "lesson-word_order-answer-\(i)") {
                                if phase == .answering { unpick(i) }
                            }
                            .matchedGeometryEffect(id: i, in: ns)
                        }
                    }
                    if phase == .checked, !Grade.gradeAnswer(question: question, userAnswer: answer) {
                        Text("正确的句子是：" + MathText.render(WordOrderFormat.readableAnswer(question.answer)))
                            .font(ClayFont.body).foregroundStyle(ClayColor.greenEdge)
                    }
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 64, maxHeight: .infinity)
            .clayLessonCard(edge: ClayColor.cubeCurrentSide)
            .accessibilityIdentifier("lesson-word_order-answer")
            ScrollView {
                FlowRow {
                    ForEach(question.options.indices, id: \.self) { i in
                        if picked.contains(i) {
                            chipGhost(text: question.options[i])
                        } else {
                            chip(text: question.options[i], filled: false, id: "lesson-word_order-\(i)") {
                                if phase == .answering { pick(i) }
                            }
                            .matchedGeometryEffect(id: i, in: ns)
                        }
                    }
                }.padding(4)
            }
            .frame(maxHeight: .infinity)
            .accessibilityIdentifier("lesson-word_order-shelf")
        }
        .onChange(of: picked) { _, newValue in
            let text = newValue.map { question.options[$0] }.joined(separator: ",")
            if text != answer { onChange(text) }
        }
    }

    private func pick(_ i: Int) {
        HapticEngine.shared.tap(); SFXEngine.shared.play(.tap)
        withAnimation(Motion.reveal) { picked.append(i) }
    }
    private func unpick(_ i: Int) {
        HapticEngine.shared.tap(); SFXEngine.shared.play(.tap)
        withAnimation(Motion.reveal) { picked.removeAll { $0 == i } }
    }

    private func chip(text: String, filled: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(MathText.render(text)).font(ClayFont.body)
                .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .buttonStyle(LessonOptionStyle(state: filled ? .selected : .default))
        .accessibilityLabel(MathText.render(text))
        .accessibilityIdentifier(id)
        .disabled(phase == .checked)
    }

    private func chipGhost(text: String) -> some View {
        Text(MathText.render(text)).font(ClayFont.body)
            .padding(.horizontal, 12).padding(.vertical, 8).clayHitTarget()
            .hidden().accessibilityHidden(true)
    }

}

/// wordOrder 正确答案的「人话」格式化：
/// 含英文/拉丁词块 → 空格连接；纯中文 → 直接连接。
enum WordOrderFormat {
    static func readableAnswer(_ answer: String) -> String {
        let parts = answer
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return answer }
        let hasLatin = parts.contains { $0.range(of: "[A-Za-z]", options: .regularExpression) != nil }
        return parts.joined(separator: hasLatin ? " " : "")
    }
}

// MARK: - Matching (flash-green-and-vanish)

private struct MatchingQuestionView: View {
    let question: Question
    let answer: String
    let phase: LessonRunnerView.QuestionPhase
    let onChange: (String) -> Void

    @State private var pairs: [String: String] = [:]     // "A" → "1" (confirmed correct)
    @State private var matched: Set<String> = []          // left keys resolved & hidden
    @State private var activeLeft: String? = nil
    @State private var flashWrong: (left: String, right: String)? = nil
    @State private var shakeTrigger = 0

    private let leftKeys = ["A", "B", "C", "D"]
    private let rightKeys = ["1", "2", "3", "4"]

    private var correctMap: [String: String] { Grade.matchingPairs(question.answer) }

    var body: some View {
        let leftItems = Array(question.options.prefix(4))
        let rightItems = Array(question.options.dropFirst(4).prefix(4))
        return ScrollView {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 4) {
                    ForEach(leftKeys.indices, id: \.self) { i in
                        let key = leftKeys[i]
                        if !matched.contains(key) {
                            Button { if phase == .answering { tapLeft(key) } } label: {
                                matchTile(label: leftItems[safe: i] ?? "", side: .left, key: key)
                            }
                            .buttonStyle(LessonOptionStyle(state: activeLeft == key ? .selected : .default))
                            .modifier(ShakeEffect(animatableData: CGFloat(flashWrong?.left == key ? shakeTrigger : 0)))
                            .accessibilityLabel("左边，" + (leftItems[safe: i] ?? ""))
                            .accessibilityIdentifier("lesson-matching-left-\(i)")
                            .accessibilityValue(activeLeft == key ? "已选择" : "")
                            .disabled(phase == .checked)
                        } else { matchedGhost() }
                    }
                }
                VStack(spacing: 4) {
                    ForEach(rightKeys.indices, id: \.self) { i in
                        let key = rightKeys[i]
                        let ownerLeft = matched.first { matched.contains($0) && correctMap[$0] == key }
                        if ownerLeft == nil {
                            Button { if phase == .answering { tapRight(key) } } label: {
                                matchTile(label: rightItems[safe: i] ?? "", side: .right, key: key)
                            }
                            .buttonStyle(LessonOptionStyle())
                            .modifier(ShakeEffect(animatableData: CGFloat(flashWrong?.right == key ? shakeTrigger : 0)))
                            .accessibilityLabel("右边，" + (rightItems[safe: i] ?? ""))
                            .accessibilityIdentifier("lesson-matching-right-\(i)")
                            .disabled(phase == .checked)
                        } else { matchedGhost() }
                    }
                }
            }.padding(4)
        }
        .accessibilityIdentifier("lesson-matching-pairs")
    }

    private enum Side { case left, right }

    private func tapLeft(_ key: String) {
        HapticEngine.shared.tap(); SFXEngine.shared.play(.tap)
        activeLeft = (activeLeft == key) ? nil : key
    }

    private func tapRight(_ key: String) {
        guard let left = activeLeft else { return }
        if correctMap[left] == key {
            // Correct pair — flash green, then vanish both tiles.
            // ios-feel-10：配对成功播上行双音，每多配一对整体升一级音高。
            HapticEngine.shared.correct()
            SFXEngine.shared.play(.pairMatch, pitchStep: matched.count)
            pairs[left] = key
            withAnimation(Motion.reveal) {
                _ = matched.insert(left)
                activeLeft = nil
            }
            if matched.count == leftKeys.count { commitAllMatched() }
        } else {
            // Wrong — flash red + shake, then deselect.
            HapticEngine.shared.wrong()
            flashWrong = (left, key)
            withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flashWrong = nil
                activeLeft = nil
            }
        }
    }

    /// When every pair is matched, hand the grader the canonical string.
    private func commitAllMatched() {
        let text = leftKeys.compactMap { k in correctMap[k].map { "\(k)-\($0)" } }.joined(separator: ",")
        onChange(text)
    }

    private func matchedGhost() -> some View {
        Color.clear.frame(maxWidth: .infinity).frame(height: 44).clayHitTarget().accessibilityHidden(true)
    }

    private func matchTile(label: String, side: Side, key: String) -> some View {
        let isWrong = (side == .left && flashWrong?.left == key) || (side == .right && flashWrong?.right == key)
        return Text(MathText.render(label)).font(ClayFont.body)
            .foregroundStyle(isWrong ? ClayColor.balloonKnot : ClayColor.ink)
            .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 10)
            .frame(minHeight: 44)
    }

}

// MARK: - Helpers

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

/// Minimal flow-row layout for chip rows.
struct FlowRow<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { WrappingHStack { content } }
}

private struct WrappingHStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, totalW: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxW { x = 0; y += lineH + 6; lineH = 0 }
            x += s.width + 8
            lineH = max(lineH, s.height)
            totalW = max(totalW, x)
        }
        return CGSize(width: maxW.isFinite ? maxW : totalW, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width - bounds.minX > maxW { x = bounds.minX; y += lineH + 6; lineH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + 8
            lineH = max(lineH, s.height)
        }
    }
}
