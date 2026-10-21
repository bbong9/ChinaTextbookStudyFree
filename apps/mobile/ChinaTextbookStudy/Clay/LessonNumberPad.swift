import SwiftUI

/// 三行键盘；只编辑调用者的同一份答案文本，不解析或规范化答案。
struct LessonNumberPad: View {
    let answer: String
    let idPrefix: String
    let onChange: (String) -> Void
    @Environment(\.clayStageScale) private var scale

    private let rows = [["1", "2", "3", "4", "5"], ["6", "7", "8", "9", "0"], [".", "/", "⌫"]]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(rows[row], id: \.self) { key in
                        Button {
                            HapticEngine.shared.tap()
                            SFXEngine.shared.play(.tap)
                            onChange(key == "⌫" ? String(answer.dropLast()) : answer + key)
                        } label: {
                            Text(key).font(ClayFont.happy(size: 26))
                                .frame(maxWidth: .infinity)
                                .frame(minWidth: max(52, 52 / scale), minHeight: max(52, 52 / scale))
                        }
                        .buttonStyle(LessonOptionStyle())
                        .accessibilityLabel(Self.label(for: key))
                        .accessibilityIdentifier("\(idPrefix)-key-\(key == "⌫" ? "delete" : key == "." ? "decimal" : key == "/" ? "fraction" : key)")
                    }
                }
            }
        }
        .accessibilityIdentifier("\(idPrefix)-keypad")
    }

    static func label(for key: String) -> String {
        switch key {
        case ".": return "小数点"
        case "/": return "分数线"
        case "⌫": return "退格"
        default: return "数字 \(key)"
        }
    }
}
