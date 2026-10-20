import SwiftUI
import CoreText

enum ClayIcon: String, CaseIterable, Identifiable {
    case back, pause, help, gu, left, right, speaker, mic, redo, play, close, heart, flame, lock
    var id: String { rawValue }
    var label: String {
        switch self {
        case .back: return "返回"
        case .pause: return "暂停"
        case .help: return "帮助"
        case .gu: return "字源"
        case .left: return "上一步"
        case .right: return "下一步"
        case .speaker: return "朗读"
        case .mic: return "开始跟读"
        case .redo: return "重来"
        case .play: return "播放"
        case .close: return "关闭"
        case .heart: return "红心"
        case .flame: return "连续学习"
        case .lock: return "未解锁"
        }
    }
}

/// 路径坐标逐项对应 art.js IC；描线先展开为填充轮廓，图标本身仍是 Shape。
struct ClayIconShape: Shape {
    let icon: ClayIcon
    var detail = false

    func path(in rect: CGRect) -> Path {
        var p = Path()
        func line(_ width: CGFloat, _ draw: (inout Path) -> Void) -> Path {
            var value = Path(); draw(&value)
            return value.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        let side: CGFloat
        switch icon {
        case .back:
            side = 32
            p = line(5.5) {
                $0.addLines([CGPoint(x: 12, y: 7), CGPoint(x: 5, y: 14), CGPoint(x: 12, y: 21)])
                $0.move(to: CGPoint(x: 6, y: 14)); $0.addLine(to: CGPoint(x: 18, y: 14))
                $0.addCurve(to: CGPoint(x: 27, y: 25), control1: CGPoint(x: 24, y: 14), control2: CGPoint(x: 27, y: 18))
            }
        case .pause:
            side = 26
            p.addRoundedRect(in: CGRect(x: 5, y: 3, width: 6, height: 18), cornerSize: CGSize(width: 3, height: 3))
            p.addRoundedRect(in: CGRect(x: 15, y: 3, width: 6, height: 18), cornerSize: CGSize(width: 3, height: 3))
        case .help, .gu:
            side = 30
            let font = CTFontCreateWithName((icon == .gu ? "ZCOOLKuaiLe-Regular" : "Nunito-Black") as CFString,
                                          icon == .gu ? 26 : 28, nil)
            var character: UniChar = icon == .gu ? 0x53E4 : 0x003F
            var glyph: CGGlyph = 0
            CTFontGetGlyphsForCharacters(font, &character, &glyph, 1)
            if let outline = CTFontCreatePathForGlyph(font, glyph, nil) {
                let box = outline.boundingBoxOfPath
                p = Path(outline).applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1,
                                                           tx: 15 - box.midX, ty: 15 + box.midY))
            }
        case .left, .right:
            side = 26
            p = line(5.5) {
                let a: CGFloat = icon == .left ? 17 : 9, b: CGFloat = icon == .left ? 8 : 18
                $0.addLines([CGPoint(x: a, y: 5), CGPoint(x: b, y: 13), CGPoint(x: a, y: 21)])
            }
        case .speaker:
            side = 26
            p.addLines([CGPoint(x: 3, y: 10), CGPoint(x: 8, y: 10), CGPoint(x: 14, y: 5),
                CGPoint(x: 14, y: 21), CGPoint(x: 8, y: 16), CGPoint(x: 3, y: 16)]); p.closeSubpath()
            p = p.union(p.strokedPath(StrokeStyle(lineWidth: 2, lineJoin: .round)))
            p.addPath(line(2.6) {
                $0.move(to: CGPoint(x: 17.5, y: 9.5))
                $0.addCurve(to: CGPoint(x: 17.5, y: 16.5), control1: CGPoint(x: 19.5, y: 11.5), control2: CGPoint(x: 19.5, y: 14.5))
                $0.move(to: CGPoint(x: 20.5, y: 6.5))
                $0.addCurve(to: CGPoint(x: 20.5, y: 19.5), control1: CGPoint(x: 24, y: 10), control2: CGPoint(x: 24, y: 16))
            })
        case .mic:
            side = 34
            p.addRoundedRect(in: CGRect(x: 11, y: 3, width: 12, height: 19), cornerSize: CGSize(width: 6, height: 6))
            p.addPath(line(3) {
                $0.move(to: CGPoint(x: 6, y: 15))
                $0.addCurve(to: CGPoint(x: 17, y: 26), control1: CGPoint(x: 6, y: 22), control2: CGPoint(x: 11, y: 26))
                $0.addCurve(to: CGPoint(x: 28, y: 15), control1: CGPoint(x: 23, y: 26), control2: CGPoint(x: 28, y: 22))
                $0.move(to: CGPoint(x: 17, y: 26)); $0.addLine(to: CGPoint(x: 17, y: 31))
                $0.move(to: CGPoint(x: 11, y: 31)); $0.addLine(to: CGPoint(x: 23, y: 31))
            })
        case .redo:
            side = 26
            p = line(4) {
                // SVG A8.5 8.5 0 1 0 21 16，圆心由端点和半径求得。
                let center = CGPoint(x: 12.847385, y: 13.593231)
                $0.addArc(center: center, radius: 8.5,
                          startAngle: .radians(atan2(9 - center.y, 20 - center.x)),
                          endAngle: .radians(atan2(16 - center.y, 21 - center.x)), clockwise: true)
                $0.addLines([CGPoint(x: 21, y: 3), CGPoint(x: 21, y: 10), CGPoint(x: 14, y: 10)])
            }
        case .play:
            side = 22
            p.addLines([CGPoint(x: 6, y: 3.5), CGPoint(x: 18, y: 11), CGPoint(x: 6, y: 18.5)]); p.closeSubpath()
            p = p.union(p.strokedPath(StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
        case .close:
            side = 20
            p = line(4) {
                $0.move(to: CGPoint(x: 5, y: 5)); $0.addLine(to: CGPoint(x: 15, y: 15))
                $0.move(to: CGPoint(x: 15, y: 5)); $0.addLine(to: CGPoint(x: 5, y: 15))
            }
        case .heart:
            side = 20
            p.move(to: CGPoint(x: 10, y: 17))
            p.addCurve(to: CGPoint(x: 6, y: 4), control1: CGPoint(x: 2, y: 11), control2: CGPoint(x: 2, y: 5))
            p.addCurve(to: CGPoint(x: 10, y: 6), control1: CGPoint(x: 8, y: 3.5), control2: CGPoint(x: 9.5, y: 5))
            p.addCurve(to: CGPoint(x: 14, y: 4), control1: CGPoint(x: 10.5, y: 5), control2: CGPoint(x: 12, y: 3.5))
            p.addCurve(to: CGPoint(x: 10, y: 17), control1: CGPoint(x: 18, y: 5), control2: CGPoint(x: 18, y: 11)); p.closeSubpath()
        case .flame:
            side = 20
            if detail {
                p.move(to: CGPoint(x: 10, y: 10))
                p.addCurve(to: CGPoint(x: 13, y: 15), control1: CGPoint(x: 11, y: 12), control2: CGPoint(x: 13, y: 13))
                p.addCurve(to: CGPoint(x: 10, y: 18), control1: CGPoint(x: 13, y: 17), control2: CGPoint(x: 11.5, y: 18))
                p.addCurve(to: CGPoint(x: 7, y: 15), control1: CGPoint(x: 8.5, y: 18), control2: CGPoint(x: 7, y: 17))
                p.addCurve(to: CGPoint(x: 10, y: 10), control1: CGPoint(x: 7, y: 13.5), control2: CGPoint(x: 8.5, y: 12.5))
            } else {
                p.move(to: CGPoint(x: 10, y: 2))
                p.addCurve(to: CGPoint(x: 16, y: 12.5), control1: CGPoint(x: 12, y: 6), control2: CGPoint(x: 16, y: 8))
                p.addCurve(to: CGPoint(x: 10, y: 18.5), control1: CGPoint(x: 16, y: 16), control2: CGPoint(x: 13, y: 18.5))
                p.addCurve(to: CGPoint(x: 4, y: 12.5), control1: CGPoint(x: 7, y: 18.5), control2: CGPoint(x: 4, y: 16))
                p.addCurve(to: CGPoint(x: 7, y: 6), control1: CGPoint(x: 4, y: 9.5), control2: CGPoint(x: 6, y: 8))
                p.addCurve(to: CGPoint(x: 9.5, y: 9), control1: CGPoint(x: 7.5, y: 8), control2: CGPoint(x: 8.5, y: 9))
                p.addCurve(to: CGPoint(x: 10, y: 2), control1: CGPoint(x: 9.5, y: 6), control2: CGPoint(x: 9, y: 4))
            }
            p.closeSubpath()
        case .lock:
            side = 22
            p.addRoundedRect(in: CGRect(x: 4, y: 9.5, width: 14, height: 10), cornerSize: CGSize(width: 3, height: 3))
            p.addPath(line(2.6) {
                $0.move(to: CGPoint(x: 7, y: 10)); $0.addLine(to: CGPoint(x: 7, y: 7))
                $0.addArc(center: CGPoint(x: 11, y: 7), radius: 4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                $0.addLine(to: CGPoint(x: 15, y: 10))
            })
        }
        return p.applying(CGAffineTransform(scaleX: rect.width / side, y: rect.height / side)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

struct ClayIconView: View {
    let icon: ClayIcon
    var color: Color = ClayColor.orange

    var body: some View {
        ZStack {
            if [.back, .pause, .left, .right, .help, .gu].contains(icon) {
                ClayIconShape(icon: icon).fill(ClayColor.orangeDeep).offset(y: icon == .pause ? 2 : 1.5)
            }
            if icon == .heart {
                ClayGradient.coral.view.mask(ClayIconShape(icon: icon))
            } else {
                ClayIconShape(icon: icon).fill(icon == .flame ? ClayColor.flame : color)
            }
            if icon == .flame { ClayIconShape(icon: icon, detail: true).fill(ClayColor.flameCore) }
        }
        .accessibilityHidden(true)
    }
}
