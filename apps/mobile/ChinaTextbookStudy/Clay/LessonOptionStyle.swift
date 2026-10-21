import SwiftUI

/// 奶油选项的状态只控制表面；题目仍把同一个答案字符串交回原判分器。
struct LessonOptionStyle: ButtonStyle {
    var state: OptionCardState = .default
    @Environment(\.clayStageScale) private var scale

    private var edge: Color {
        switch state {
        case .selected: return ClayColor.orange
        case .correct: return ClayColor.greenEdge
        case .wrong: return ClayColor.balloonKnot
        default: return ClayColor.creamEdge
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClayFont.body).foregroundStyle(ClayColor.ink)
            .frame(minWidth: max(44, 44 / scale), minHeight: max(44, 44 / scale))
            .claySurface(.buttonCream, radius: ClayRadius.smallButton, edge: edge, shadow: .stat)
            .overlay {
                RoundedRectangle(cornerRadius: ClayRadius.smallButton)
                    .strokeBorder(state == .default || state == .disabled ? ClayColor.white : edge, lineWidth: 3)
            }
            .opacity(state == .disabled ? 0.6 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
    }
}
