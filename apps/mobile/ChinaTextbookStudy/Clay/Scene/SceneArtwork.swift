import SwiftUI

/// 路径与嵌套变换逐项来自 design/art.js 的 S / cube / DOCK。
/// map* 来自 screens.js: scrMap；仅拆层，不更改坐标。所有 Path 只初始化一次。
enum SceneArtwork {
    static let cloud: [SceneNode] = [
        .group([
            .group([
                .shape(sceneEllipse(6, 24, 62, 10), fill: .color(ClayColor.cloudShade), opacity: 0.7),
                .shape(sceneEllipse(-32, 8, 20, 20), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(-4, -6, 28, 28), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(28, 4, 22, 22), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(50, 14, 13, 13), fill: .color(ClayColor.white)),
                .shape(sceneRect(-52, 6, 114, 20, 10), fill: .color(ClayColor.white)),
            ]),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let tree: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 2, 40, 8), fill: .color(ClayColor.treeShadow), opacity: 0.25),
            .shape(scenePath { $0.move(to: CGPoint(x: -12, y: 2)); $0.addCurve(to: CGPoint(x: -6, y: -92), control1: CGPoint(x: -9, y: -30), control2: CGPoint(x: -8, y: -60)); $0.addLine(to: CGPoint(x: 6, y: -92)); $0.addCurve(to: CGPoint(x: 12, y: 2), control1: CGPoint(x: 8, y: -60), control2: CGPoint(x: 9, y: -30)); $0.closeSubpath() }, fill: .gradient(.trunk)),
            .shape(sceneEllipse(-36, -98, 32, 32), fill: .gradient(.canopy2)),
            .shape(sceneEllipse(36, -100, 30, 30), fill: .gradient(.canopy2)),
            .shape(sceneEllipse(0, -132, 42, 42), fill: .gradient(.canopy)),
            .shape(sceneEllipse(-24, -108, 30, 30), fill: .gradient(.canopy)),
            .shape(sceneEllipse(26, -110, 30, 30), fill: .gradient(.canopy)),
            .shape(sceneEllipse(-14, -152, 15, 8), fill: .color(ClayColor.white), opacity: 0.35),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let bush: [SceneNode] = [
        .group([
            .shape(sceneEllipse(-22, -14, 18, 18), fill: .gradient(.canopy2)),
            .shape(sceneEllipse(22, -14, 18, 18), fill: .gradient(.canopy2)),
            .shape(sceneEllipse(0, -24, 24, 24), fill: .gradient(.canopy)),
            .shape(sceneRect(-38, -16, 76, 16, 8), fill: .gradient(.canopy2)),
            .shape(sceneEllipse(-8, -34, 5, 5), fill: .color(ClayColor.white), opacity: 0.35),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let tuft: [SceneNode] = [
        .group([.shape(scenePath { $0.move(to: CGPoint(x: 0, y: 0)); $0.addCurve(to: CGPoint(x: -12, y: -18), control1: CGPoint(x: -2, y: -10), control2: CGPoint(x: -8, y: -16)); $0.addCurve(to: CGPoint(x: -3, y: 0), control1: CGPoint(x: -6, y: -12), control2: CGPoint(x: -4, y: -6)); $0.closeSubpath(); $0.move(to: CGPoint(x: 2, y: 0)); $0.addCurve(to: CGPoint(x: 8, y: -24), control1: CGPoint(x: 2, y: -12), control2: CGPoint(x: 4, y: -20)); $0.addCurve(to: CGPoint(x: 6, y: 0), control1: CGPoint(x: 6, y: -14), control2: CGPoint(x: 6, y: -6)); $0.closeSubpath(); $0.move(to: CGPoint(x: 7, y: 0)); $0.addCurve(to: CGPoint(x: 18, y: -13), control1: CGPoint(x: 10, y: -8), control2: CGPoint(x: 14, y: -12)); $0.addCurve(to: CGPoint(x: 11, y: 0), control1: CGPoint(x: 14, y: -8), control2: CGPoint(x: 12, y: -4)); $0.closeSubpath() }, fill: .color(ClayColor.tuft))], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let stone: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 0, 24, 11), fill: .gradient(.stone)),
            .shape(sceneEllipse(-6, -4, 10, 3), fill: .color(ClayColor.white), opacity: 0.7),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let shroom: [SceneNode] = [
        .group([
            .shape(sceneRect(-6, -18, 12, 18, 5), fill: .gradient(.stem)),
            .shape(scenePath { $0.move(to: CGPoint(x: -20, y: -16)); $0.addCurve(to: CGPoint(x: 0, y: -40), control1: CGPoint(x: -20, y: -34), control2: CGPoint(x: -8, y: -40)); $0.addCurve(to: CGPoint(x: 20, y: -16), control1: CGPoint(x: 8, y: -40), control2: CGPoint(x: 20, y: -34)); $0.addCurve(to: CGPoint(x: -20, y: -16), control1: CGPoint(x: 10, y: -20), control2: CGPoint(x: -10, y: -20)); $0.closeSubpath() }, fill: .gradient(.mush)),
            .shape(sceneEllipse(-8, -28, 3.5, 3.5), fill: .color(ClayColor.white)),
            .shape(sceneEllipse(6, -32, 3, 3), fill: .color(ClayColor.white)),
            .shape(sceneEllipse(11, -22, 2.4, 2.4), fill: .color(ClayColor.white)),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let mushHouse: [SceneNode] = [
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: -50, y: 0)); $0.addCurve(to: CGPoint(x: -40, y: -82), control1: CGPoint(x: -48, y: -40), control2: CGPoint(x: -44, y: -70)); $0.addLine(to: CGPoint(x: 40, y: -82)); $0.addCurve(to: CGPoint(x: 50, y: 0), control1: CGPoint(x: 44, y: -70), control2: CGPoint(x: 48, y: -40)); $0.closeSubpath() }, fill: .gradient(.stem)),
            .shape(scenePath { $0.move(to: CGPoint(x: -16, y: 0)); $0.addLine(to: CGPoint(x: -16, y: -30)); $0.addCurve(to: CGPoint(x: 16, y: -30), control1: CGPoint(x: -16, y: -44), control2: CGPoint(x: 16, y: -44)); $0.addLine(to: CGPoint(x: 16, y: 0)); $0.closeSubpath() }, fill: .gradient(.woodD)),
            .shape(sceneEllipse(9, -18, 2.5, 2.5), fill: .color(ClayColor.flameCore)),
            .shape(sceneEllipse(29, -50, 11, 11), fill: .color(ClayColor.windowFrame)),
            .shape(sceneEllipse(29, -50, 8, 8), fill: .color(ClayColor.windowLight)),
            .shape(scenePath { $0.move(to: CGPoint(x: -94, y: -70)); $0.addCurve(to: CGPoint(x: 0, y: -182), control1: CGPoint(x: -94, y: -150), control2: CGPoint(x: -40, y: -182)); $0.addCurve(to: CGPoint(x: 94, y: -70), control1: CGPoint(x: 40, y: -182), control2: CGPoint(x: 94, y: -150)); $0.addCurve(to: CGPoint(x: -94, y: -70), control1: CGPoint(x: 60, y: -82), control2: CGPoint(x: -60, y: -82)); $0.closeSubpath() }, fill: .gradient(.mush)),
            .shape(sceneEllipse(0, -74, 86, 10), fill: .color(ClayColor.mushroomRim)),
            .group([
                .shape(sceneEllipse(-46, -122, 16, 12), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(8, -150, 20, 14), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(52, -112, 15, 11), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(-12, -100, 10, 8), fill: .color(ClayColor.white)),
                .shape(sceneEllipse(-72, -90, 8, 6), fill: .color(ClayColor.white)),
            ]),
            .group([.shape(sceneEllipse(-30, -158, 22, 8), fill: .color(ClayColor.white), opacity: 0.35)], transform: CGAffineTransform(translationX: 30, y: 158).concatenating(CGAffineTransform(rotationAngle: -0.349066)).concatenating(CGAffineTransform(translationX: -30, y: -158))),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
    ]

    static let cottage: [SceneNode] = [
        .group([
            .shape(sceneRect(-58, -90, 116, 90, 10), fill: .gradient(.stem)),
            .shape(scenePath { $0.move(to: CGPoint(x: -74, y: -84)); $0.addCurve(to: CGPoint(x: 0, y: -154), control1: CGPoint(x: -60, y: -100), control2: CGPoint(x: -20, y: -150)); $0.addCurve(to: CGPoint(x: 74, y: -84), control1: CGPoint(x: 20, y: -150), control2: CGPoint(x: 60, y: -100)); $0.addCurve(to: CGPoint(x: -74, y: -84), control1: CGPoint(x: 50, y: -92), control2: CGPoint(x: -50, y: -92)); $0.closeSubpath() }, fill: .gradient(.fox)),
            .shape(sceneRect(34, -160, 16, 40, 4), fill: .color(ClayColor.chimney)),
            .shape(scenePath { $0.move(to: CGPoint(x: -14, y: 0)); $0.addLine(to: CGPoint(x: -14, y: -40)); $0.addCurve(to: CGPoint(x: 14, y: -40), control1: CGPoint(x: -14, y: -56), control2: CGPoint(x: 14, y: -56)); $0.addLine(to: CGPoint(x: 14, y: 0)); $0.closeSubpath() }, fill: .gradient(.woodD)),
            .shape(sceneEllipse(-36, -54, 13, 13), fill: .color(ClayColor.windowFrame)),
            .shape(sceneEllipse(-36, -54, 10, 10), fill: .color(ClayColor.windowGlass)),
            .shape(scenePath { $0.move(to: CGPoint(x: -36, y: -64)); $0.addLine(to: CGPoint(x: -36, y: -44)); $0.move(to: CGPoint(x: -46, y: -54)); $0.addLine(to: CGPoint(x: -26, y: -54)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.windowFrame), width: 2.5),
            .shape(sceneEllipse(36, -54, 13, 13), fill: .color(ClayColor.windowFrame)),
            .shape(sceneEllipse(36, -54, 10, 10), fill: .color(ClayColor.windowGlass)),
            .shape(scenePath { $0.move(to: CGPoint(x: 36, y: -64)); $0.addLine(to: CGPoint(x: 36, y: -44)); $0.move(to: CGPoint(x: 26, y: -54)); $0.addLine(to: CGPoint(x: 46, y: -54)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.windowFrame), width: 2.5),
            .shape(sceneEllipse(0, -118, 10, 10), fill: .color(ClayColor.windowGlass), stroke: .color(ClayColor.chimney), width: 4),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
    ]

    static let gift: [SceneNode] = [
        .group([
            .shape(sceneRect(-26, -40, 52, 40, 8), fill: .gradient(.coral)),
            .shape(sceneRect(-30, -50, 60, 16, 7), fill: .color(ClayColor.giftLid)),
            .shape(sceneRect(-6, -50, 12, 50, 0), fill: .gradient(.gold)),
            .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -50)); $0.addCurve(to: CGPoint(x: -22, y: -52), control1: CGPoint(x: -14, y: -70), control2: CGPoint(x: -30, y: -62)); $0.closeSubpath(); $0.move(to: CGPoint(x: 0, y: -50)); $0.addCurve(to: CGPoint(x: 22, y: -52), control1: CGPoint(x: 14, y: -70), control2: CGPoint(x: 30, y: -62)); $0.closeSubpath() }, fill: .gradient(.gold)),
            .shape(sceneEllipse(-16, -28, 5, 9), fill: .color(ClayColor.white), opacity: 0.35),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
    ]

    static let flower: [SceneNode] = [
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 0)); $0.addCurve(to: CGPoint(x: 0, y: -20), control1: CGPoint(x: 1, y: -8), control2: CGPoint(x: -1, y: -14)) }, stroke: .color(ClayColor.flowerStem), width: 2.5),
            .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -8)); $0.addCurve(to: CGPoint(x: 11, y: -7), control1: CGPoint(x: 6, y: -12), control2: CGPoint(x: 10, y: -10)); $0.addCurve(to: CGPoint(x: 0, y: -8), control1: CGPoint(x: 6, y: -5), control2: CGPoint(x: 3, y: -6)); $0.closeSubpath() }, fill: .color(ClayColor.flowerLeaf)),
            .group([
                .shape(sceneEllipse(0, -5.5, 4.8, 4.8), fill: .accent),
                .shape(sceneEllipse(5.2, -1.7, 4.8, 4.8), fill: .accent),
                .shape(sceneEllipse(3.2, 4.4, 4.8, 4.8), fill: .accent),
                .shape(sceneEllipse(-3.2, 4.4, 4.8, 4.8), fill: .accent),
                .shape(sceneEllipse(-5.2, -1.7, 4.8, 4.8), fill: .accent),
                .shape(sceneEllipse(0, 0, 3.6, 3.6), fill: .color(ClayColor.flameCore)),
            ], transform: CGAffineTransform(translationX: 0, y: -24)),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let butterfly: [SceneNode] = [
        .group([
            .group([
                .shape(sceneEllipse(-6, -3, 6, 8), fill: .accent),
                .shape(sceneEllipse(6, -3, 6, 8), fill: .accent),
                .shape(sceneEllipse(-5, 6, 4, 5), fill: .accent, opacity: 0.8),
                .shape(sceneEllipse(5, 6, 4, 5), fill: .accent, opacity: 0.8),
                .shape(sceneRect(-1.2, -6, 2.4, 14, 1.2), fill: .color(ClayColor.butterflyBody)),
            ]),
        ], transform: CGAffineTransform(translationX: 0, y: 0)),
    ]

    static let chestClosed: [SceneNode] = [
        .group([
            .shape(sceneRect(-40, -44, 80, 44, 8), fill: .gradient(.wood)),
            .shape(sceneRect(-40, -44, 80, 8, 0), fill: .color(ClayColor.chestRim)),
            .shape(sceneRect(-44, -46, 10, 46, 3), fill: .gradient(.gold)),
            .shape(sceneRect(34, -46, 10, 46, 3), fill: .gradient(.gold)),
            .shape(scenePath { $0.move(to: CGPoint(x: -42, y: -44)); $0.addCurve(to: CGPoint(x: 42, y: -44), control1: CGPoint(x: -42, y: -74), control2: CGPoint(x: 42, y: -74)); $0.closeSubpath() }, fill: .gradient(.wood)),
            .shape(sceneRect(-44, -62, 10, 18, 3), fill: .gradient(.gold)),
            .shape(sceneRect(34, -62, 10, 18, 3), fill: .gradient(.gold)),
            .shape(sceneRect(-9, -52, 18, 18, 4), fill: .gradient(.gold)),
            .shape(sceneEllipse(0, -44, 3, 3), fill: .color(ClayColor.woodDark)),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
    ]

    static let chestOpen: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, -46, 70, 50), fill: .gradient(.warmglow)),
            .shape(sceneRect(-40, -44, 80, 44, 8), fill: .gradient(.wood)),
            .shape(sceneRect(-40, -44, 80, 8, 0), fill: .color(ClayColor.chestRim)),
            .shape(sceneRect(-44, -46, 10, 46, 3), fill: .gradient(.gold)),
            .shape(sceneRect(34, -46, 10, 46, 3), fill: .gradient(.gold)),
            .shape(scenePath { $0.move(to: CGPoint(x: -40, y: -46)); $0.addLine(to: CGPoint(x: -36, y: -86)); $0.addCurve(to: CGPoint(x: 36, y: -86), control1: CGPoint(x: -20, y: -96), control2: CGPoint(x: 20, y: -96)); $0.addLine(to: CGPoint(x: 40, y: -46)); $0.closeSubpath() }, fill: .color(ClayColor.chestInside)),
            .group([
                .group([
                    .shape(sceneEllipse(0, 0, 10, 10), fill: .color(ClayColor.coinEdge)),
                    .shape(sceneEllipse(0, -0.8, 8.6, 8.6), fill: .gradient(.gold)),
                    .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -5.6)); $0.addLine(to: CGPoint(x: 1.4, y: -2.5)); $0.addLine(to: CGPoint(x: 4.8, y: -2.1)); $0.addLine(to: CGPoint(x: 2.3, y: 0.1)); $0.addLine(to: CGPoint(x: 2.9, y: 3.4)); $0.addLine(to: CGPoint(x: 0, y: 1.8)); $0.addLine(to: CGPoint(x: -2.9, y: 3.4)); $0.addLine(to: CGPoint(x: -2.3, y: 0.1)); $0.addLine(to: CGPoint(x: -4.8, y: -2.1)); $0.addLine(to: CGPoint(x: -1.4, y: -2.5)); $0.closeSubpath() }, fill: .color(ClayColor.coinEmblem), stroke: .color(ClayColor.coinEmblem), width: 1.1, join: .round),
                ], transform: CGAffineTransform(translationX: -14, y: -52)),
                .group([
                    .shape(sceneEllipse(0, 0, 11, 11), fill: .color(ClayColor.coinEdge)),
                    .shape(sceneEllipse(0, -0.88, 9.46, 9.46), fill: .gradient(.gold)),
                    .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -6.2)); $0.addLine(to: CGPoint(x: 1.6, y: -2.8)); $0.addLine(to: CGPoint(x: 5.2, y: -2.4)); $0.addLine(to: CGPoint(x: 2.5, y: 0.2)); $0.addLine(to: CGPoint(x: 3.2, y: 3.8)); $0.addLine(to: CGPoint(x: 0, y: 2)); $0.addLine(to: CGPoint(x: -3.2, y: 3.8)); $0.addLine(to: CGPoint(x: -2.5, y: 0.2)); $0.addLine(to: CGPoint(x: -5.2, y: -2.4)); $0.addLine(to: CGPoint(x: -1.6, y: -2.8)); $0.closeSubpath() }, fill: .color(ClayColor.coinEmblem), stroke: .color(ClayColor.coinEmblem), width: 1.21, join: .round),
                ], transform: CGAffineTransform(translationX: 8, y: -56)),
                .group([
                    .shape(sceneEllipse(0, 0, 9, 9), fill: .color(ClayColor.coinEdge)),
                    .shape(sceneEllipse(0, -0.72, 7.74, 7.74), fill: .gradient(.gold)),
                    .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -5)); $0.addLine(to: CGPoint(x: 1.3, y: -2.3)); $0.addLine(to: CGPoint(x: 4.3, y: -1.9)); $0.addLine(to: CGPoint(x: 2.1, y: 0.1)); $0.addLine(to: CGPoint(x: 2.6, y: 3.1)); $0.addLine(to: CGPoint(x: 0, y: 1.6)); $0.addLine(to: CGPoint(x: -2.6, y: 3.1)); $0.addLine(to: CGPoint(x: -2.1, y: 0.1)); $0.addLine(to: CGPoint(x: -4.3, y: -1.9)); $0.addLine(to: CGPoint(x: -1.3, y: -2.3)); $0.closeSubpath() }, fill: .color(ClayColor.coinEmblem), stroke: .color(ClayColor.coinEmblem), width: 0.99, join: .round),
                ], transform: CGAffineTransform(translationX: -2, y: -66)),
                .group([
                    .shape(sceneEllipse(0, 0, 8, 8), fill: .color(ClayColor.coinEdge)),
                    .shape(sceneEllipse(0, -0.64, 6.88, 6.88), fill: .gradient(.gold)),
                    .shape(scenePath { $0.move(to: CGPoint(x: 0, y: -4.5)); $0.addLine(to: CGPoint(x: 1.1, y: -2)); $0.addLine(to: CGPoint(x: 3.8, y: -1.7)); $0.addLine(to: CGPoint(x: 1.8, y: 0.1)); $0.addLine(to: CGPoint(x: 2.4, y: 2.8)); $0.addLine(to: CGPoint(x: 0, y: 1.4)); $0.addLine(to: CGPoint(x: -2.4, y: 2.8)); $0.addLine(to: CGPoint(x: -1.8, y: 0.1)); $0.addLine(to: CGPoint(x: -3.8, y: -1.7)); $0.addLine(to: CGPoint(x: -1.1, y: -2)); $0.closeSubpath() }, fill: .color(ClayColor.coinEmblem), stroke: .color(ClayColor.coinEmblem), width: 0.88, join: .round),
                ], transform: CGAffineTransform(translationX: 22, y: -48)),
            ]),
            .shape(scenePath { $0.move(to: CGPoint(x: -42, y: -86)); $0.addCurve(to: CGPoint(x: 42, y: -86), control1: CGPoint(x: -24, y: -110), control2: CGPoint(x: 24, y: -110)); $0.addLine(to: CGPoint(x: 38, y: -98)); $0.addCurve(to: CGPoint(x: -38, y: -98), control1: CGPoint(x: 20, y: -118), control2: CGPoint(x: -20, y: -118)); $0.closeSubpath() }, fill: .gradient(.wood)),
            .shape(sceneRect(-9, -52, 18, 18, 4), fill: .gradient(.gold)),
            .shape(sceneEllipse(0, -44, 3, 3), fill: .color(ClayColor.woodDark)),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
    ]

    static let trainEngine: [SceneNode] = [
        .group([
            .group([
                .shape(sceneRect(-80, -74, 120, 68, 14), fill: .gradient(.coral)),
                .shape(sceneRect(-84, -128, 64, 66, 12), fill: .gradient(.coral)),
                .shape(sceneRect(-90, -138, 76, 16, 8), fill: .color(ClayColor.trainRoof)),
                .shape(sceneRect(-74, -118, 44, 32, 8), fill: .color(ClayColor.trainGlass)),
                .shape(sceneRect(-6, -112, 22, 40, 6), fill: .color(ClayColor.trainIron)),
                .shape(sceneRect(-12, -120, 34, 12, 6), fill: .color(ClayColor.trainIron)),
                .shape(scenePath { $0.move(to: CGPoint(x: 40, y: -60)); $0.addLine(to: CGPoint(x: 70, y: -40)); $0.addLine(to: CGPoint(x: 70, y: -10)); $0.addLine(to: CGPoint(x: 40, y: -10)); $0.closeSubpath() }, fill: .gradient(.gold)),
                .shape(sceneEllipse(20, -46, 12, 12), fill: .color(ClayColor.coinEmblem)),
                .shape(sceneEllipse(20, -46, 7, 7), fill: .color(ClayColor.flameCore)),
                .shape(sceneEllipse(-52, 0, 13, 13), fill: .color(ClayColor.trainIron)),
                .shape(sceneEllipse(-52, 0, 6, 6), fill: .gradient(.gold)),
                .shape(sceneEllipse(10, 0, 13, 13), fill: .color(ClayColor.trainIron)),
                .shape(sceneEllipse(10, 0, 6, 6), fill: .gradient(.gold)),
            ], shadow: true),
        ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
    ]

    static let cubeDone: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 9, 29, 6), fill: .color(ClayColor.cubeShadow), opacity: 0.22),
            .shape(sceneRect(-25, -35, 50, 42, 12), fill: .color(ClayColor.cubeDoneSide)),
            .shape(sceneRect(-25, -42, 50, 42, 12), fill: .gradient(.cubeF)),
            .shape(sceneRect(-18, -38, 36, 7, 3.5), fill: .color(ClayColor.white), opacity: 0.45),
        ], transform: CGAffineTransform(translationX: 0, y: 0)),
    ]

    static let cubeCurrent: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 9, 29, 6), fill: .color(ClayColor.cubeShadow), opacity: 0.22),
            .shape(sceneRect(-25, -35, 50, 42, 12), fill: .color(ClayColor.cubeCurrentSide)),
            .shape(sceneRect(-25, -42, 50, 42, 12), fill: .gradient(.cubeC)),
            .shape(sceneRect(-18, -38, 36, 7, 3.5), fill: .color(ClayColor.white), opacity: 0.45),
        ], transform: CGAffineTransform(translationX: 0, y: 0)),
    ]

    static let cubeLocked: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 9, 29, 6), fill: .color(ClayColor.cubeShadow), opacity: 0.22),
            .shape(sceneRect(-25, -35, 50, 42, 12), fill: .color(ClayColor.cubeLockedSide)),
            .shape(sceneRect(-25, -42, 50, 42, 12), fill: .gradient(.cubeL)),
            .shape(sceneRect(-18, -38, 36, 7, 3.5), fill: .color(ClayColor.white), opacity: 0.45),
            .group([
                .shape(sceneEllipse(0, 0, 8, 8), fill: .color(ClayColor.white), opacity: 0.9),
                .shape(sceneRect(-4, -2, 8, 6, 1.5), fill: .color(ClayColor.cubeLock)),
                .shape(scenePath { $0.move(to: CGPoint(x: -2.5, y: -2)); $0.addLine(to: CGPoint(x: -2.5, y: -4)); $0.addCurve(to: CGPoint(x: 0, y: -6.5), control1: CGPoint(x: -2.5, y: -5.380712), control2: CGPoint(x: -1.380712, y: -6.5)); $0.addCurve(to: CGPoint(x: 2.5, y: -4), control1: CGPoint(x: 1.380712, y: -6.5), control2: CGPoint(x: 2.5, y: -5.380712)); $0.addLine(to: CGPoint(x: 2.5, y: -2)) }, stroke: .color(ClayColor.cubeLock), width: 1.6),
            ], transform: CGAffineTransform(translationX: 16, y: -36)),
        ], transform: CGAffineTransform(translationX: 0, y: 0)),
    ]

    static let cubeGame: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 9, 29, 6), fill: .color(ClayColor.cubeShadow), opacity: 0.22),
            .shape(sceneRect(-25, -35, 50, 42, 12), fill: .color(ClayColor.cubeGameSide)),
            .shape(sceneRect(-25, -42, 50, 42, 12), fill: .gradient(.cubeG)),
            .shape(sceneRect(-18, -38, 36, 7, 3.5), fill: .color(ClayColor.white), opacity: 0.45),
            .group([
                .shape(sceneRect(-13, -13, 11, 11, 3), fill: .color(ClayColor.white)),
                .shape(sceneRect(2, -13, 11, 11, 3), fill: .color(ClayColor.white), opacity: 0.7),
                .shape(sceneRect(-13, 2, 11, 11, 3), fill: .color(ClayColor.white), opacity: 0.7),
                .shape(sceneRect(2, 2, 11, 11, 3), fill: .color(ClayColor.white)),
            ], transform: CGAffineTransform(translationX: 0, y: -20)),
        ], transform: CGAffineTransform(translationX: 0, y: 0)),
    ]

    static let dockHanzi: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 9, 29, 6), fill: .color(ClayColor.cubeShadow), opacity: 0.22),
            .shape(sceneRect(-25, -35, 50, 42, 12), fill: .color(ClayColor.cubeDoneSide)),
            .shape(sceneRect(-25, -42, 50, 42, 12), fill: .gradient(.cubeF)),
            .shape(sceneRect(-18, -38, 36, 7, 3.5), fill: .color(ClayColor.white), opacity: 0.45),
        ], transform: CGAffineTransform(translationX: 30, y: 46)),
    ]

    static let dockMath: [SceneNode] = [
        .group([
            .group([
                .group([
                    .shape(sceneRect(-80, -74, 120, 68, 14), fill: .gradient(.coral)),
                    .shape(sceneRect(-84, -128, 64, 66, 12), fill: .gradient(.coral)),
                    .shape(sceneRect(-90, -138, 76, 16, 8), fill: .color(ClayColor.trainRoof)),
                    .shape(sceneRect(-74, -118, 44, 32, 8), fill: .color(ClayColor.trainGlass)),
                    .shape(sceneRect(-6, -112, 22, 40, 6), fill: .color(ClayColor.trainIron)),
                    .shape(sceneRect(-12, -120, 34, 12, 6), fill: .color(ClayColor.trainIron)),
                    .shape(scenePath { $0.move(to: CGPoint(x: 40, y: -60)); $0.addLine(to: CGPoint(x: 70, y: -40)); $0.addLine(to: CGPoint(x: 70, y: -10)); $0.addLine(to: CGPoint(x: 40, y: -10)); $0.closeSubpath() }, fill: .gradient(.gold)),
                    .shape(sceneEllipse(20, -46, 12, 12), fill: .color(ClayColor.coinEmblem)),
                    .shape(sceneEllipse(20, -46, 7, 7), fill: .color(ClayColor.flameCore)),
                    .shape(sceneEllipse(-52, 0, 13, 13), fill: .color(ClayColor.trainIron)),
                    .shape(sceneEllipse(-52, 0, 6, 6), fill: .gradient(.gold)),
                    .shape(sceneEllipse(10, 0, 13, 13), fill: .color(ClayColor.trainIron)),
                    .shape(sceneEllipse(10, 0, 6, 6), fill: .gradient(.gold)),
                ], shadow: true),
            ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0))),
        ], transform: CGAffineTransform(scaleX: 0.36, y: 0.36).concatenating(CGAffineTransform(translationX: 34, y: 50))),
    ]

    static let dockEng: [SceneNode] = [
        .shape(scenePath { $0.move(to: CGPoint(x: 30, y: 46)); $0.addCurve(to: CGPoint(x: 30, y: 58), control1: CGPoint(x: 28, y: 50), control2: CGPoint(x: 32, y: 54)) }, stroke: .color(ClayColor.balloonString), width: 1.5),
        .shape(sceneEllipse(30, 25, 18, 21), fill: .gradient(.coral)),
        .shape(scenePath { $0.move(to: CGPoint(x: 27, y: 45)); $0.addLine(to: CGPoint(x: 33, y: 45)); $0.addLine(to: CGPoint(x: 30, y: 49)); $0.closeSubpath() }, fill: .color(ClayColor.balloonKnot)),
        .text("A", at: CGPoint(x: 30, y: 33), font: ClayFont.nunito(size: 22), color: ClayColor.white),
        .group([.shape(sceneEllipse(22, 15, 5, 3), fill: .color(ClayColor.white), opacity: 0.6)], transform: CGAffineTransform(translationX: -22, y: -15).concatenating(CGAffineTransform(rotationAngle: -0.523599)).concatenating(CGAffineTransform(translationX: 22, y: 15))),
    ]

    static let dockAnimal: [SceneNode] = [
        .group([
            .shape(sceneEllipse(62, 123, 34, 5.5), fill: .color(ClayColor.dockAnimalShadow), opacity: 0.2),
            .shape(sceneEllipse(50, 118, 10, 5), fill: .gradient(.orange)),
            .shape(sceneEllipse(74, 118, 10, 5), fill: .gradient(.orange)),
            .shape(scenePath { $0.move(to: CGPoint(x: 104, y: 78)); $0.addLine(to: CGPoint(x: 118, y: 64)); $0.addLine(to: CGPoint(x: 112, y: 86)); $0.closeSubpath() }, fill: .gradient(.yellow)),
            .shape(sceneEllipse(66, 90, 42, 28), fill: .gradient(.yellow)),
            .group([.shape(sceneEllipse(78, 88, 18, 12), fill: .color(ClayColor.dockAnimalWing))], transform: CGAffineTransform(translationX: -78, y: -88).concatenating(CGAffineTransform(rotationAngle: -0.261799)).concatenating(CGAffineTransform(translationX: 78, y: 88))),
            .shape(sceneEllipse(46, 52, 27, 27), fill: .gradient(.yellow)),
            .group([.shape(sceneEllipse(36, 36, 9, 5), fill: .color(ClayColor.white), opacity: 0.65)], transform: CGAffineTransform(translationX: -36, y: -36).concatenating(CGAffineTransform(rotationAngle: -0.488692)).concatenating(CGAffineTransform(translationX: 36, y: 36))),
            .shape(sceneEllipse(22, 60, 14, 7), fill: .gradient(.orange)),
            .shape(sceneEllipse(38, 48, 5.04, 6.24), fill: .color(ClayColor.dockAnimalEye)),
            .shape(sceneEllipse(39.68, 45.52, 2.16, 2.16), fill: .color(ClayColor.white)),
            .shape(sceneEllipse(36.64, 50.24, 0.96, 0.96), fill: .color(ClayColor.white), opacity: 0.9),
            .shape(sceneEllipse(56, 48, 5.04, 6.24), fill: .color(ClayColor.dockAnimalEye)),
            .shape(sceneEllipse(57.68, 45.52, 2.16, 2.16), fill: .color(ClayColor.white)),
            .shape(sceneEllipse(54.64, 50.24, 0.96, 0.96), fill: .color(ClayColor.white), opacity: 0.9),
            .shape(sceneEllipse(30, 60, 7.5, 4.5), fill: .color(ClayColor.dockAnimalBlush), opacity: 0.5),
            .shape(sceneEllipse(62, 60, 7.5, 4.5), fill: .color(ClayColor.dockAnimalBlush), opacity: 0.5),
        ], transform: CGAffineTransform(scaleX: 0.46, y: 0.46).concatenating(CGAffineTransform(translationX: 2, y: 4))),
    ]

    static let dockStory: [SceneNode] = [
        .shape(scenePath { $0.move(to: CGPoint(x: 6, y: 16)); $0.addCurve(to: CGPoint(x: 30, y: 18), control1: CGPoint(x: 16, y: 12), control2: CGPoint(x: 24, y: 13)); $0.addLine(to: CGPoint(x: 30, y: 52)); $0.addCurve(to: CGPoint(x: 6, y: 50), control1: CGPoint(x: 24, y: 47), control2: CGPoint(x: 16, y: 46)); $0.closeSubpath() }, fill: .gradient(.blue)),
        .shape(scenePath { $0.move(to: CGPoint(x: 54, y: 16)); $0.addCurve(to: CGPoint(x: 30, y: 18), control1: CGPoint(x: 44, y: 12), control2: CGPoint(x: 36, y: 13)); $0.addLine(to: CGPoint(x: 30, y: 52)); $0.addCurve(to: CGPoint(x: 54, y: 50), control1: CGPoint(x: 36, y: 47), control2: CGPoint(x: 44, y: 46)); $0.closeSubpath() }, fill: .gradient(.blue)),
        .shape(scenePath { $0.move(to: CGPoint(x: 10, y: 18)); $0.addCurve(to: CGPoint(x: 29, y: 20), control1: CGPoint(x: 18, y: 15), control2: CGPoint(x: 24, y: 16)); $0.addLine(to: CGPoint(x: 29, y: 48)); $0.addCurve(to: CGPoint(x: 10, y: 46), control1: CGPoint(x: 24, y: 44), control2: CGPoint(x: 18, y: 43)); $0.closeSubpath() }, fill: .color(ClayColor.creamTop)),
        .shape(scenePath { $0.move(to: CGPoint(x: 50, y: 18)); $0.addCurve(to: CGPoint(x: 31, y: 20), control1: CGPoint(x: 42, y: 15), control2: CGPoint(x: 36, y: 16)); $0.addLine(to: CGPoint(x: 31, y: 48)); $0.addCurve(to: CGPoint(x: 50, y: 46), control1: CGPoint(x: 36, y: 44), control2: CGPoint(x: 42, y: 43)); $0.closeSubpath() }, fill: .color(ClayColor.bookPage)),
        .shape(scenePath { $0.move(to: CGPoint(x: 20, y: 24)); $0.addLine(to: CGPoint(x: 21.7, y: 27.7)); $0.addLine(to: CGPoint(x: 25.7, y: 28.1)); $0.addLine(to: CGPoint(x: 22.7, y: 30.9)); $0.addLine(to: CGPoint(x: 23.5, y: 34.9)); $0.addLine(to: CGPoint(x: 20, y: 32.9)); $0.addLine(to: CGPoint(x: 16.5, y: 34.9)); $0.addLine(to: CGPoint(x: 17.3, y: 30.9)); $0.addLine(to: CGPoint(x: 14.3, y: 28.1)); $0.addLine(to: CGPoint(x: 18.3, y: 27.7)); $0.closeSubpath() }, fill: .color(ClayColor.bookStar), stroke: .color(ClayColor.bookStar), width: 1.32, join: .round),
        .shape(sceneEllipse(41, 30, 6, 6), fill: .color(ClayColor.bookPicture)),
    ]

    static let dockIdiom: [SceneNode] = [
        .shape(sceneRect(10, 10, 40, 42, 6), fill: .color(ClayColor.scrollPaper)),
        .shape(sceneRect(6, 6, 48, 9, 4.5), fill: .gradient(.woodD)),
        .shape(sceneRect(6, 48, 48, 9, 4.5), fill: .gradient(.woodD)),
    ]

    static let dockBooks: [SceneNode] = [
        .shape(sceneRect(10, 38, 42, 12, 3), fill: .gradient(.coral)),
        .shape(sceneRect(14, 26, 36, 12, 3), fill: .gradient(.green2)),
        .shape(sceneRect(8, 14, 40, 12, 3), fill: .gradient(.violet2)),
        .shape(scenePath { $0.move(to: CGPoint(x: 12, y: 18)); $0.addLine(to: CGPoint(x: 40, y: 18)); $0.move(to: CGPoint(x: 16, y: 30)); $0.addLine(to: CGPoint(x: 44, y: 30)); $0.move(to: CGPoint(x: 14, y: 42)); $0.addLine(to: CGPoint(x: 46, y: 42)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.white), width: 2, opacity: 0.6),
    ]

    static let dockCheckin: [SceneNode] = [
        .shape(sceneRect(8, 12, 44, 40, 9), fill: .color(ClayColor.creamTop)),
        .shape(scenePath { $0.move(to: CGPoint(x: 8, y: 21)); $0.addCurve(to: CGPoint(x: 17, y: 12), control1: CGPoint(x: 8, y: 16), control2: CGPoint(x: 12, y: 12)); $0.addLine(to: CGPoint(x: 43, y: 12)); $0.addCurve(to: CGPoint(x: 52, y: 21), control1: CGPoint(x: 48, y: 12), control2: CGPoint(x: 52, y: 16)); $0.addLine(to: CGPoint(x: 52, y: 24)); $0.addLine(to: CGPoint(x: 8, y: 24)); $0.closeSubpath() }, fill: .gradient(.coral)),
        .shape(sceneRect(18, 6, 5, 12, 2.5), fill: .color(ClayColor.woodDark)),
        .shape(sceneRect(37, 6, 5, 12, 2.5), fill: .color(ClayColor.woodDark)),
        .shape(scenePath { $0.move(to: CGPoint(x: 20, y: 38)); $0.addLine(to: CGPoint(x: 27, y: 44)); $0.addLine(to: CGPoint(x: 41, y: 30)) }, stroke: .color(ClayColor.completed), width: 5, cap: .round, join: .round),
    ]

    static let dockShop: [SceneNode] = [
        .shape(sceneRect(10, 26, 40, 28, 5), fill: .color(ClayColor.creamTop)),
        .shape(scenePath { $0.move(to: CGPoint(x: 6, y: 16)); $0.addLine(to: CGPoint(x: 54, y: 16)); $0.addLine(to: CGPoint(x: 52, y: 28)); $0.addCurve(to: CGPoint(x: 40, y: 28), control1: CGPoint(x: 48, y: 32), control2: CGPoint(x: 44, y: 32)); $0.addCurve(to: CGPoint(x: 30, y: 28), control1: CGPoint(x: 36, y: 32), control2: CGPoint(x: 32, y: 32)); $0.addCurve(to: CGPoint(x: 20, y: 28), control1: CGPoint(x: 28, y: 32), control2: CGPoint(x: 24, y: 32)); $0.addCurve(to: CGPoint(x: 8, y: 28), control1: CGPoint(x: 16, y: 32), control2: CGPoint(x: 12, y: 32)); $0.closeSubpath() }, fill: .gradient(.coral)),
        .shape(scenePath { $0.move(to: CGPoint(x: 18, y: 16)); $0.addLine(to: CGPoint(x: 16, y: 28)); $0.move(to: CGPoint(x: 30, y: 16)); $0.addLine(to: CGPoint(x: 30, y: 28)); $0.move(to: CGPoint(x: 42, y: 16)); $0.addLine(to: CGPoint(x: 44, y: 28)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.white), width: 5, opacity: 0.9),
        .shape(sceneRect(24, 36, 12, 18, 3), fill: .gradient(.wood)),
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: 10, y: 17)); $0.addCurve(to: CGPoint(x: 6, y: 4), control1: CGPoint(x: 2, y: 11), control2: CGPoint(x: 2, y: 5)); $0.addCurve(to: CGPoint(x: 10, y: 6), control1: CGPoint(x: 8, y: 3.5), control2: CGPoint(x: 9.5, y: 5)); $0.addCurve(to: CGPoint(x: 14, y: 4), control1: CGPoint(x: 10.5, y: 5), control2: CGPoint(x: 12, y: 3.5)); $0.addCurve(to: CGPoint(x: 10, y: 17), control1: CGPoint(x: 18, y: 5), control2: CGPoint(x: 18, y: 11)); $0.closeSubpath() }, fill: .gradient(.coral)),
        ], transform: CGAffineTransform(scaleX: 0.6, y: 0.6).concatenating(CGAffineTransform(translationX: 40, y: 34))),
    ]

    static let dockTask: [SceneNode] = [
        .shape(sceneRect(12, 8, 36, 46, 6), fill: .color(ClayColor.creamTop)),
        .shape(sceneRect(22, 4, 16, 9, 4), fill: .gradient(.gold)),
        .shape(scenePath { $0.move(to: CGPoint(x: 19, y: 22)); $0.addLine(to: CGPoint(x: 22, y: 25)); $0.addLine(to: CGPoint(x: 28, y: 19)); $0.move(to: CGPoint(x: 19, y: 34)); $0.addLine(to: CGPoint(x: 22, y: 37)); $0.addLine(to: CGPoint(x: 28, y: 31)) }, stroke: .color(ClayColor.completed), width: 3, cap: .round),
        .shape(scenePath { $0.move(to: CGPoint(x: 31, y: 23)); $0.addLine(to: CGPoint(x: 41, y: 23)); $0.move(to: CGPoint(x: 31, y: 35)); $0.addLine(to: CGPoint(x: 41, y: 35)); $0.move(to: CGPoint(x: 19, y: 46)); $0.addLine(to: CGPoint(x: 41, y: 46)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.taskRule), width: 3, cap: .round),
    ]

    static let dockParent: [SceneNode] = [
        .group([
            .shape(sceneEllipse(0, 0, 20, 20), fill: .gradient(.blue)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 0)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 0.785398)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 1.570796)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 2.356194)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 3.141593)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 3.926991)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 4.712389)),
            .group([.shape(sceneRect(-5, -26, 10, 10, 3), fill: .color(ClayColor.ribbonBlueBottom))], transform: CGAffineTransform(rotationAngle: 5.497787)),
            .shape(sceneEllipse(0, 0, 9, 9), fill: .color(ClayColor.creamTop)),
        ], transform: CGAffineTransform(translationX: 30, y: 30)),
    ]

    static let dockPethouse: [SceneNode] = [
        .group([
            .group([
                .shape(scenePath { $0.move(to: CGPoint(x: -50, y: 0)); $0.addCurve(to: CGPoint(x: -40, y: -82), control1: CGPoint(x: -48, y: -40), control2: CGPoint(x: -44, y: -70)); $0.addLine(to: CGPoint(x: 40, y: -82)); $0.addCurve(to: CGPoint(x: 50, y: 0), control1: CGPoint(x: 44, y: -70), control2: CGPoint(x: 48, y: -40)); $0.closeSubpath() }, fill: .gradient(.stem)),
                .shape(scenePath { $0.move(to: CGPoint(x: -16, y: 0)); $0.addLine(to: CGPoint(x: -16, y: -30)); $0.addCurve(to: CGPoint(x: 16, y: -30), control1: CGPoint(x: -16, y: -44), control2: CGPoint(x: 16, y: -44)); $0.addLine(to: CGPoint(x: 16, y: 0)); $0.closeSubpath() }, fill: .gradient(.woodD)),
                .shape(sceneEllipse(9, -18, 2.5, 2.5), fill: .color(ClayColor.flameCore)),
                .shape(sceneEllipse(29, -50, 11, 11), fill: .color(ClayColor.windowFrame)),
                .shape(sceneEllipse(29, -50, 8, 8), fill: .color(ClayColor.windowLight)),
                .shape(scenePath { $0.move(to: CGPoint(x: -94, y: -70)); $0.addCurve(to: CGPoint(x: 0, y: -182), control1: CGPoint(x: -94, y: -150), control2: CGPoint(x: -40, y: -182)); $0.addCurve(to: CGPoint(x: 94, y: -70), control1: CGPoint(x: 40, y: -182), control2: CGPoint(x: 94, y: -150)); $0.addCurve(to: CGPoint(x: -94, y: -70), control1: CGPoint(x: 60, y: -82), control2: CGPoint(x: -60, y: -82)); $0.closeSubpath() }, fill: .gradient(.mush)),
                .shape(sceneEllipse(0, -74, 86, 10), fill: .color(ClayColor.mushroomRim)),
                .group([
                    .shape(sceneEllipse(-46, -122, 16, 12), fill: .color(ClayColor.white)),
                    .shape(sceneEllipse(8, -150, 20, 14), fill: .color(ClayColor.white)),
                    .shape(sceneEllipse(52, -112, 15, 11), fill: .color(ClayColor.white)),
                    .shape(sceneEllipse(-12, -100, 10, 8), fill: .color(ClayColor.white)),
                    .shape(sceneEllipse(-72, -90, 8, 6), fill: .color(ClayColor.white)),
                ]),
                .group([.shape(sceneEllipse(-30, -158, 22, 8), fill: .color(ClayColor.white), opacity: 0.35)], transform: CGAffineTransform(translationX: 30, y: 158).concatenating(CGAffineTransform(rotationAngle: -0.349066)).concatenating(CGAffineTransform(translationX: -30, y: -158))),
            ], transform: CGAffineTransform(scaleX: 1, y: 1).concatenating(CGAffineTransform(translationX: 0, y: 0)), shadow: true),
        ], transform: CGAffineTransform(scaleX: 0.3, y: 0.3).concatenating(CGAffineTransform(translationX: 30, y: 56))),
    ]

    static let mapFar: [SceneNode] = [
        .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 196)); $0.addCurve(to: CGPoint(x: 250, y: 178), control1: CGPoint(x: 80, y: 150), control2: CGPoint(x: 170, y: 150)); $0.addCurve(to: CGPoint(x: 500, y: 170), control1: CGPoint(x: 330, y: 140), control2: CGPoint(x: 420, y: 138)); $0.addCurve(to: CGPoint(x: 760, y: 168), control1: CGPoint(x: 580, y: 146), control2: CGPoint(x: 680, y: 140)); $0.addCurve(to: CGPoint(x: 844, y: 164), control1: CGPoint(x: 800, y: 156), control2: CGPoint(x: 830, y: 160)); $0.addLine(to: CGPoint(x: 844, y: 390)); $0.addLine(to: CGPoint(x: 0, y: 390)); $0.closeSubpath() }, fill: .gradient(.far)),
    ]

    static let mapRail: [SceneNode] = [
        .shape(sceneRect(560, 176, 284, 4, 2), fill: .color(ClayColor.rail)),
        .group([
            .shape(sceneEllipse(777, 112, 7, 7), fill: .color(ClayColor.white), opacity: 0.9),
            .shape(sceneEllipse(768, 98, 9, 9), fill: .color(ClayColor.white), opacity: 0.7),
            .shape(sceneEllipse(756, 82, 11, 11), fill: .color(ClayColor.white), opacity: 0.5),
        ]),
    ]

    static let mapHills: [SceneNode] = [
        .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 222)); $0.addCurve(to: CGPoint(x: 430, y: 214), control1: CGPoint(x: 150, y: 196), control2: CGPoint(x: 300, y: 200)); $0.addCurve(to: CGPoint(x: 844, y: 200), control1: CGPoint(x: 560, y: 196), control2: CGPoint(x: 700, y: 190)); $0.addLine(to: CGPoint(x: 844, y: 390)); $0.addLine(to: CGPoint(x: 0, y: 390)); $0.closeSubpath() }, fill: .gradient(.hill1)),
        .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 222)); $0.addCurve(to: CGPoint(x: 430, y: 214), control1: CGPoint(x: 150, y: 196), control2: CGPoint(x: 300, y: 200)); $0.addCurve(to: CGPoint(x: 844, y: 200), control1: CGPoint(x: 560, y: 196), control2: CGPoint(x: 700, y: 190)) }, stroke: .color(ClayColor.hillHighlight), width: 3, opacity: 0.7),
        .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 330)); $0.addCurve(to: CGPoint(x: 844, y: 306), control1: CGPoint(x: 240, y: 312), control2: CGPoint(x: 540, y: 326)); $0.addLine(to: CGPoint(x: 844, y: 390)); $0.addLine(to: CGPoint(x: 0, y: 390)); $0.closeSubpath() }, fill: .gradient(.hill2)),
    ]

    static let mapTree: [SceneNode] = [
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: -40, y: 312)); $0.addCurve(to: CGPoint(x: 10, y: 130), control1: CGPoint(x: -6, y: 292), control2: CGPoint(x: 6, y: 230)); $0.addCurve(to: CGPoint(x: 6, y: -10), control1: CGPoint(x: 12, y: 70), control2: CGPoint(x: 8, y: 30)); $0.addLine(to: CGPoint(x: 94, y: -10)); $0.addCurve(to: CGPoint(x: 88, y: 130), control1: CGPoint(x: 90, y: 30), control2: CGPoint(x: 86, y: 80)); $0.addCurve(to: CGPoint(x: 128, y: 306), control1: CGPoint(x: 92, y: 220), control2: CGPoint(x: 104, y: 280)); $0.addCurve(to: CGPoint(x: -40, y: 312), control1: CGPoint(x: 90, y: 302), control2: CGPoint(x: 20, y: 314)); $0.closeSubpath() }, fill: .gradient(.trunk)),
            .shape(scenePath { $0.move(to: CGPoint(x: 30, y: 40)); $0.addCurve(to: CGPoint(x: 24, y: 190), control1: CGPoint(x: 26, y: 90), control2: CGPoint(x: 30, y: 140)); $0.move(to: CGPoint(x: 70, y: 60)); $0.addCurve(to: CGPoint(x: 78, y: 230), control1: CGPoint(x: 74, y: 120), control2: CGPoint(x: 70, y: 170)) }, stroke: .color(ClayColor.treeGrain), width: 4, cap: .round, opacity: 0.6),
            .shape(scenePath { $0.move(to: CGPoint(x: 32, y: 294)); $0.addLine(to: CGPoint(x: 32, y: 250)); $0.addCurve(to: CGPoint(x: 74, y: 250), control1: CGPoint(x: 32, y: 222), control2: CGPoint(x: 74, y: 222)); $0.addLine(to: CGPoint(x: 74, y: 294)); $0.closeSubpath() }, fill: .gradient(.woodD)),
            .shape(sceneEllipse(65, 268, 3, 3), fill: .color(ClayColor.flameCore)),
            .shape(sceneEllipse(54, 160, 17, 17), fill: .color(ClayColor.woodDark)),
            .shape(sceneEllipse(54, 160, 13, 13), fill: .color(ClayColor.windowLight)),
            .shape(scenePath { $0.move(to: CGPoint(x: 54, y: 147)); $0.addLine(to: CGPoint(x: 54, y: 173)); $0.move(to: CGPoint(x: 41, y: 160)); $0.addLine(to: CGPoint(x: 67, y: 160)) }, fill: .color(ClayColor.black), stroke: .color(ClayColor.woodDark), width: 3),
        ], shadow: true),
        .shape(sceneEllipse(-6, -6, 74, 74), fill: .gradient(.canopy2)),
        .shape(sceneEllipse(80, -30, 62, 62), fill: .gradient(.canopy)),
        .shape(sceneEllipse(146, -14, 40, 40), fill: .gradient(.canopy2)),
    ]

    static let mapLabels: [SceneNode] = [
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 22)); $0.addLine(to: CGPoint(x: -7, y: 12)); $0.addLine(to: CGPoint(x: 7, y: 12)); $0.closeSubpath() }, fill: .color(ClayColor.ribbonBlueBottom)),
            .shape(sceneRect(-22, -8, 44, 22, 11), fill: .gradient(.blue)),
            .text("宝箱", at: CGPoint(x: 0, y: 8), font: ClayFont.happy(size: 14), color: ClayColor.white),
        ], transform: CGAffineTransform(translationX: 668, y: 168)),
        .group([
            .shape(scenePath { $0.move(to: CGPoint(x: 0, y: 22)); $0.addLine(to: CGPoint(x: -7, y: 12)); $0.addLine(to: CGPoint(x: 7, y: 12)); $0.closeSubpath() }, fill: .color(ClayColor.gameBadge)),
            .shape(sceneRect(-26, -8, 52, 22, 11), fill: .gradient(.violet2)),
            .text("小游戏", at: CGPoint(x: 0, y: 8), font: ClayFont.happy(size: 14), color: ClayColor.white),
        ], transform: CGAffineTransform(translationX: 352, y: 186)),
    ]

}
