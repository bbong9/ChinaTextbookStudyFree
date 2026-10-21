import SwiftUI

enum PetPaint {
    case color(Color)
    case gradient(ClayGradient)
}

extension PetArtwork {
    func fill(_ path: Path, _ paint: PetPaint, bounds: CGRect? = nil) {
        switch paint {
        case .color(let color): context.fill(path, with: .color(color))
        case .gradient(let token):
            let box = bounds ?? path.boundingRect
            guard box.width > 0, box.height > 0 else { return }
            var ctx = context
            ctx.translateBy(x: box.minX, y: box.minY)
            ctx.scaleBy(x: box.width, y: box.height)
            let normalized = path.applying(.init(translationX: -box.minX, y: -box.minY))
                .applying(.init(scaleX: 1 / box.width, y: 1 / box.height))
            switch token.geometry {
            case .radial(let center, let radius):
                ctx.fill(normalized, with: .radialGradient(Gradient(stops: token.stops),
                    center: .init(x: center.x, y: center.y), startRadius: 0, endRadius: radius))
            case .linear(let end):
                ctx.fill(normalized, with: .linearGradient(Gradient(stops: token.stops),
                    startPoint: .zero, endPoint: .init(x: end.x, y: end.y)))
            }
        }
    }

    func stroke(_ path: Path, _ paint: PetPaint, width: CGFloat) {
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        if case .color(let color) = paint {
            context.stroke(path, with: .color(color), style: style)
        } else {
            fill(path.strokedPath(style), paint, bounds: path.boundingRect)
        }
    }

    func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ paint: PetPaint, rotation: Double = 0) {
        var ctx = context
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: .degrees(rotation))
        PetArtwork(context: ctx).fill(Path(ellipseIn: .init(x: -rx, y: -ry, width: rx * 2, height: ry * 2)), paint)
    }

    func polygon(_ points: [CGPoint], _ paint: PetPaint) {
        fill(Path { p in
            guard let first = points.first else { return }
            p.move(to: first)
            for point in points.dropFirst() { p.addLine(to: point) }
            p.closeSubpath()
        }, paint)
    }

    func flower() {
        // 原稿的五瓣花替换新芽，保留茎。
        for angle in stride(from: 0.0, to: 360, by: 72) {
            let a = angle * .pi / 180
            ellipse(60 + cos(a) * 7, 14 + sin(a) * 7, 6, 6, .color(ClayColor.Pet.bloom))
        }
        ellipse(60, 14, 4.5, 4.5, .color(ClayColor.flameCore))
    }

    func cracks(_ requested: Int) {
        let level = min(3, max(0, requested))
        guard level > 0 else { return }
        // 第一层逐点沿用原稿，后两层增加支裂；0 表示完整蛋壳。
        let lines: [[CGPoint]] = [
            [.init(x: 26, y: 70), .init(x: 38, y: 62), .init(x: 46, y: 72), .init(x: 56, y: 62), .init(x: 66, y: 72), .init(x: 76, y: 62), .init(x: 94, y: 70)],
            [.init(x: 56, y: 62), .init(x: 51, y: 53), .init(x: 58, y: 44), .init(x: 54, y: 32)],
            [.init(x: 66, y: 72), .init(x: 63, y: 86), .init(x: 54, y: 94), .init(x: 58, y: 108)]
        ]
        for points in lines.prefix(level) {
            stroke(Path { p in
                p.move(to: points[0])
                for point in points.dropFirst() { p.addLine(to: point) }
            }, .color(ClayColor.Pet.crack), width: 3)
        }
    }

    func face(_ kind: PetKind, mood: MascotMood, blink: Bool) {
        let a = kind.anchors
        let separation: CGFloat
        let eyeScale: CGFloat
        let mouthY: CGFloat
        switch kind {
        case .penguin: separation = 12; eyeScale = 0.9; mouthY = 83
        case .owl: separation = 15; eyeScale = 1.05; mouthY = 85
        case .duck: separation = 9; eyeScale = 0.8; mouthY = 67
        case .sheep: separation = 9; eyeScale = 0.75; mouthY = 88
        case .fox: separation = 15; eyeScale = 1; mouthY = 96
        case .cat: separation = 15; eyeScale = 1; mouthY = 93
        case .pig: separation = 16; eyeScale = 1; mouthY = 104
        case .egg: separation = 12; eyeScale = 0.75; mouthY = 103
        case .dragon: separation = 14; eyeScale = 1; mouthY = 88
        case .mituan: separation = 14; eyeScale = 1; mouthY = 88
        }
        for x in [a.eyes.x - separation, a.eyes.x + separation] {
            let y = a.eyes.y
            if blink {
                stroke(curve(x - 6 * eyeScale, y, x, y + 3 * eyeScale, x + 6 * eyeScale, y), .color(ClayColor.Pet.ink), width: 2.6)
            } else {
                switch mood {
                case .happy, .cheer, .proud, .wave:
                    let lift: CGFloat = mood == .cheer ? 9 : (mood == .proud ? 5 : 7)
                    stroke(curve(x - 6.3 * eyeScale, y, x, y - lift * eyeScale, x + 6.3 * eyeScale, y), .color(ClayColor.Pet.ink), width: 2.8)
                case .sad, .embarrassed:
                    ellipse(x, y + 1, 3.5 * eyeScale, 4.5 * eyeScale, .color(ClayColor.Pet.ink))
                    let side: CGFloat = x < a.eyes.x ? 1 : -1
                    stroke(curve(x - 6, y - 10 + side * 3, x, y - 11, x + 6, y - 10 - side * 3), .color(ClayColor.Pet.ink), width: 2.2)
                case .think, .surprise:
                    let dx: CGFloat = mood == .think ? 2.8 : 0
                    let s: CGFloat = mood == .surprise ? eyeScale * 1.12 : eyeScale
                    ellipse(x + dx, y, 6.3 * s, 7.8 * s, .color(ClayColor.Pet.ink))
                    ellipse(x + dx + 2.1 * s, y - 3.1 * s, 2.7 * s, 2.7 * s, .color(ClayColor.white))
                    ellipse(x + dx - 1.7 * s, y + 2.8 * s, 1.2 * s, 1.2 * s, .color(ClayColor.white.opacity(0.9)))
                }
            }
        }
        let x = a.eyes.x
        switch mood {
        case .surprise:
            ellipse(x, mouthY + 3, 4.5, 6, .color(ClayColor.Pet.mouth))
        case .sad, .embarrassed:
            stroke(curve(x - 4, mouthY + 3, x, mouthY - (mood == .sad ? 3 : 0), x + 4, mouthY + 3), .color(ClayColor.Pet.ink), width: 2.3)
            if mood == .embarrassed {
                for side in [CGFloat(-1), 1] {
                    ellipse(x + side * (separation + 9), a.eyes.y + 11, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.35)))
                }
            }
        case .think:
            stroke(curve(x + 1, mouthY + 1, x + 4, mouthY - 1, x + 7, mouthY + 1), .color(ClayColor.Pet.ink), width: 2.3)
        case .proud:
            smile(x, mouthY, open: false)
        case .happy, .wave, .cheer:
            // 猫、狐狸等保留原有 W 形嘴，欢呼时张嘴。
            smile(x, mouthY, open: kind == .mituan || mood == .cheer)
        }
    }

    func curve(_ x1: CGFloat, _ y1: CGFloat, _ cx: CGFloat, _ cy: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> Path {
        Path { p in p.move(to: .init(x: x1, y: y1)); p.addQuadCurve(to: .init(x: x2, y: y2), control: .init(x: cx, y: cy)) }
    }

    func smile(_ x: CGFloat, _ y: CGFloat, open: Bool) {
        if open {
            fill(Path { p in
                p.move(to: .init(x: x - 7, y: y))
                p.addQuadCurve(to: .init(x: x + 7, y: y), control: .init(x: x, y: y + 11))
                p.addQuadCurve(to: .init(x: x - 7, y: y), control: .init(x: x, y: y + 2))
                p.closeSubpath()
            }, .color(ClayColor.Pet.mouth))
            fill(Path { p in
                p.move(to: .init(x: x - 4, y: y + 5))
                p.addQuadCurve(to: .init(x: x + 4, y: y + 5), control: .init(x: x, y: y + 9))
                p.addQuadCurve(to: .init(x: x - 4, y: y + 5), control: .init(x: x, y: y + 3))
                p.closeSubpath()
            }, .color(ClayColor.Pet.tongue))
        } else {
            var p = curve(x - 6, y, x - 3, y + 4, x, y)
            p.addQuadCurve(to: .init(x: x + 6, y: y), control: .init(x: x + 3, y: y + 4))
            stroke(p, .color(ClayColor.Pet.ink), width: 2.6)
        }
    }

    func wavingHand(_ kind: PetKind, angle: Double) {
        let paint: PetPaint
        switch kind {
        case .mituan: paint = .gradient(.mt)
        case .fox: paint = .gradient(.fox)
        case .cat, .sheep: paint = .gradient(.white)
        case .penguin: paint = .gradient(.navy)
        case .owl: paint = .gradient(.violet)
        case .dragon: paint = .gradient(.mint)
        case .egg: paint = .gradient(.egg)
        case .duck: paint = .gradient(.yellow)
        case .pig: paint = .gradient(.pink)
        }
        ellipse(kind == .duck ? 101 : 106, 70, 7, 14, paint, rotation: -45 + angle)
    }
}
