import SwiftUI

/// 原 SVG 的 shape/group，路径在静态常量初始化时构造；运行时不解析 SVG。
enum ScenePaint {
    case color(Color), gradient(ClayGradient), accent
}

indirect enum SceneNode {
    case shape(Path, fill: ScenePaint? = nil, stroke: ScenePaint? = nil,
               width: CGFloat = 1, cap: CGLineCap = .butt, join: CGLineJoin = .miter, opacity: Double = 1)
    case group([SceneNode], transform: CGAffineTransform = .identity, opacity: Double = 1, shadow: Bool = false)
    case text(String, at: CGPoint, font: Font, color: Color)

    func draw(in context: GraphicsContext, accent: Color) {
        var context = context
        switch self {
        case let .shape(path, fill, stroke, width, cap, join, opacity):
            context.opacity *= opacity
            if let fill { Self.fill(path, paint: fill, in: context, accent: accent) }
            if let stroke {
                let outline = path.strokedPath(StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: join))
                Self.fill(outline, paint: stroke, in: context, accent: accent, bounds: path.boundingRect)
            }
        case let .group(children, transform, opacity, shadow):
            context.concatenate(transform)
            context.opacity *= opacity
            if shadow {
                let token = ClayShadow.scene
                context.addFilter(.shadow(color: token.color, radius: token.radius, x: 0, y: token.y))
                context.drawLayer { layer in children.forEach { $0.draw(in: layer, accent: accent) } }
            } else {
                children.forEach { $0.draw(in: context, accent: accent) }
            }
        case let .text(label, point, font, color):
            let text = context.resolve(Text(label).font(font).foregroundStyle(color))
            let size = text.measure(in: CGSize(width: 1000, height: 1000))
            context.draw(text, at: CGPoint(x: point.x - size.width / 2,
                                           y: point.y - text.firstBaseline(in: size)), anchor: .topLeading)
        }
    }

    private static func fill(_ path: Path, paint: ScenePaint, in context: GraphicsContext,
                             accent: Color, bounds: CGRect? = nil) {
        switch paint {
        case .color(let color): context.fill(path, with: .color(color))
        case .accent: context.fill(path, with: .color(accent))
        case .gradient(let token):
            let box = bounds ?? path.boundingRect
            guard box.width > 0, box.height > 0 else { return }
            // 与 ClayGradient.view 相同：SVG objectBoundingBox 径向渐变必须分别缩放两轴。
            var unit = context
            unit.translateBy(x: box.minX, y: box.minY)
            unit.scaleBy(x: box.width, y: box.height)
            let normalized = path.applying(CGAffineTransform(translationX: -box.minX, y: -box.minY)
                .concatenating(CGAffineTransform(scaleX: 1 / box.width, y: 1 / box.height)))
            let gradient = Gradient(stops: token.stops)
            switch token.geometry {
            case .linear(let end):
                unit.fill(normalized, with: .linearGradient(gradient, startPoint: .zero,
                                                            endPoint: CGPoint(x: end.x, y: end.y)))
            case .radial(let center, let radius):
                unit.fill(normalized, with: .radialGradient(gradient, center: CGPoint(x: center.x, y: center.y),
                                                            startRadius: 0, endRadius: radius))
            }
        }
    }
}

func scenePath(_ draw: (inout Path) -> Void) -> Path {
    var path = Path(); draw(&path); return path
}

func sceneRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat = 0) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: width, height: height),
         cornerRadius: radius)
}

func sceneEllipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
}

/// x/y 和 scale 对应 S.* 的 translate/scale；原点通常是脚底，而不是包围盒中心。
struct SceneSprite: View {
    let nodes: [SceneNode]
    let bounds: CGRect
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var color: Color = ClayColor.white
    var motion: ClayMotion? = nil

    var body: some View {
        Canvas { context, _ in
            var local = context
            local.translateBy(x: -bounds.minX, y: -bounds.minY)
            nodes.forEach { $0.draw(in: local, accent: color) }
        }
        .frame(width: bounds.width, height: bounds.height)
        .clayMotion(motion)
        .scaleEffect(scale)
        .position(x: x + bounds.midX * scale, y: y + bounds.midY * scale)
        .accessibilityHidden(true)
    }
}
