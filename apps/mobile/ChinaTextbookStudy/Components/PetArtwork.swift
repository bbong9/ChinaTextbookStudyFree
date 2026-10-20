import SwiftUI

/// 逐项移植 design/art.js PET_ART；路径已展开为原生 Path，无 SVG 解析或位图依赖。
struct PetArtwork {
    var context: GraphicsContext

    func draw(_ kind: PetKind, mood: MascotMood, bloom: Bool, crack: Int, blink: Bool, wave: Double, accessory: PetAccessory) {
        switch kind {
        case .mituan: mituan(bloom: bloom, waving: mood == .wave, headwear: accessory.isHeadwear)
        case .fox: fox()
        case .cat: cat()
        case .penguin: penguin(waving: mood == .wave)
        case .owl: owl(waving: mood == .wave, headwear: accessory.isHeadwear)
        case .dragon: dragon()
        case .egg: egg()
        case .duck: duck()
        case .pig: pig()
        case .sheep: sheep()
        }
        if kind == .mituan && bloom && !accessory.isHeadwear { flower() }
        if kind == .egg { cracks(crack) }
        face(kind, mood: mood, blink: blink)
        if mood == .wave { wavingHand(kind, angle: wave) }
        drawAccessory(accessory, anchors: kind.anchors)
    }

    private func mituan(bloom: Bool, waving: Bool, headwear: Bool) {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        ellipse(13, 86, 8, 13, .gradient(.mt), rotation: 32)
        if !waving { ellipse(107, 86, 8, 13, .gradient(.mt), rotation: -32) }
        ellipse(44, 115, 12, 7.5, .gradient(.mt))
        ellipse(76, 115, 12, 7.5, .gradient(.mt))
        if !headwear {
            stroke(Path { p in
                p.move(to: .init(x: 60, y: 36))
                p.addLine(to: .init(x: 60, y: 20))
            }, .color(ClayColor.Pet.sprout), width: 4.5)
            if !bloom {
                fill(Path { p in
                    p.move(to: .init(x: 60, y: 22))
                    p.addCurve(to: .init(x: 31, y: 20), control1: .init(x: 50, y: 9), control2: .init(x: 35, y: 11))
                    p.addCurve(to: .init(x: 60, y: 22), control1: .init(x: 41, y: 29), control2: .init(x: 54, y: 28))
                    p.closeSubpath()
                }, .gradient(.leaf))
                fill(Path { p in
                    p.move(to: .init(x: 60, y: 20))
                    p.addCurve(to: .init(x: 91, y: 16), control1: .init(x: 70, y: 5), control2: .init(x: 87, y: 7))
                    p.addCurve(to: .init(x: 60, y: 20), control1: .init(x: 81, y: 27), control2: .init(x: 66, y: 26))
                    p.closeSubpath()
                }, .gradient(.leaf))
            }
        }
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.mt))
        ellipse(40, 50, 13, 6, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        ellipse(32, 90, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(88, 90, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func fox() {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path { p in
            p.move(to: .init(x: 94, y: 104))
            p.addCurve(to: .init(x: 108, y: 54), control1: .init(x: 120, y: 98), control2: .init(x: 122, y: 68))
            p.addCurve(to: .init(x: 84, y: 92), control1: .init(x: 104, y: 74), control2: .init(x: 96, y: 84))
            p.closeSubpath()
        }, .gradient(.fox))
        fill(Path { p in
            p.move(to: .init(x: 108, y: 54))
            p.addCurve(to: .init(x: 117, y: 86), control1: .init(x: 117, y: 63), control2: .init(x: 120, y: 76))
            p.addCurve(to: .init(x: 108, y: 54), control1: .init(x: 110, y: 80), control2: .init(x: 105, y: 68))
            p.closeSubpath()
        }, .color(ClayColor.Pet.foxTail))
        fill(Path { p in
            p.move(to: .init(x: 28, y: 60))
            p.addCurve(to: .init(x: 33, y: 13), control1: .init(x: 20, y: 38), control2: .init(x: 24, y: 20))
            p.addCurve(to: .init(x: 56, y: 46), control1: .init(x: 45, y: 22), control2: .init(x: 53, y: 34))
            p.closeSubpath()
        }, .gradient(.fox))
        fill(Path { p in
            p.move(to: .init(x: 92, y: 60))
            p.addCurve(to: .init(x: 87, y: 13), control1: .init(x: 100, y: 38), control2: .init(x: 96, y: 20))
            p.addCurve(to: .init(x: 64, y: 46), control1: .init(x: 75, y: 22), control2: .init(x: 67, y: 34))
            p.closeSubpath()
        }, .gradient(.fox))
        fill(Path { p in
            p.move(to: .init(x: 34, y: 48))
            p.addCurve(to: .init(x: 36, y: 22), control1: .init(x: 31, y: 36), control2: .init(x: 33, y: 27))
            p.addCurve(to: .init(x: 49, y: 43), control1: .init(x: 43, y: 28), control2: .init(x: 47, y: 36))
            p.closeSubpath()
        }, .color(ClayColor.Pet.foxEar))
        fill(Path { p in
            p.move(to: .init(x: 86, y: 48))
            p.addCurve(to: .init(x: 84, y: 22), control1: .init(x: 89, y: 36), control2: .init(x: 87, y: 27))
            p.addCurve(to: .init(x: 71, y: 43), control1: .init(x: 77, y: 28), control2: .init(x: 73, y: 36))
            p.closeSubpath()
        }, .color(ClayColor.Pet.foxEar))
        ellipse(44, 115, 12, 7.5, .color(ClayColor.Pet.foxFoot))
        ellipse(76, 115, 12, 7.5, .color(ClayColor.Pet.foxFoot))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.fox))
        fill(Path { p in
            p.move(to: .init(x: 18, y: 84))
            p.addCurve(to: .init(x: 60, y: 93), control1: .init(x: 32, y: 78), control2: .init(x: 48, y: 82))
            p.addCurve(to: .init(x: 102, y: 84), control1: .init(x: 72, y: 82), control2: .init(x: 88, y: 78))
            p.addCurve(to: .init(x: 60, y: 117), control1: .init(x: 100, y: 106), control2: .init(x: 82, y: 117))
            p.addCurve(to: .init(x: 18, y: 84), control1: .init(x: 38, y: 117), control2: .init(x: 20, y: 106))
            p.closeSubpath()
        }, .gradient(.petCream))
        ellipse(40, 50, 13, 6, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        ellipse(60, 88, 5.5, 4, .color(ClayColor.Pet.ink))
        ellipse(32, 86, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(88, 86, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func cat() {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        stroke(Path { p in
            p.move(to: .init(x: 100, y: 104))
            p.addCurve(to: .init(x: 110, y: 74), control1: .init(x: 118, y: 102), control2: .init(x: 118, y: 80))
        }, .gradient(.caramel), width: 9)
        fill(Path { p in
            p.move(to: .init(x: 24, y: 62))
            p.addCurve(to: .init(x: 28, y: 18), control1: .init(x: 20, y: 44), control2: .init(x: 22, y: 26))
            p.addCurve(to: .init(x: 54, y: 44), control1: .init(x: 40, y: 24), control2: .init(x: 50, y: 34))
            p.closeSubpath()
        }, .gradient(.white))
        fill(Path { p in
            p.move(to: .init(x: 96, y: 62))
            p.addCurve(to: .init(x: 92, y: 18), control1: .init(x: 100, y: 44), control2: .init(x: 98, y: 26))
            p.addCurve(to: .init(x: 66, y: 44), control1: .init(x: 80, y: 24), control2: .init(x: 70, y: 34))
            p.closeSubpath()
        }, .gradient(.caramel))
        fill(Path { p in
            p.move(to: .init(x: 30, y: 50))
            p.addCurve(to: .init(x: 32, y: 26), control1: .init(x: 28, y: 38), control2: .init(x: 30, y: 30))
            p.addCurve(to: .init(x: 47, y: 43), control1: .init(x: 39, y: 31), control2: .init(x: 44, y: 37))
            p.closeSubpath()
        }, .color(ClayColor.Pet.catEar))
        ellipse(44, 115, 12, 7.5, .gradient(.white))
        ellipse(76, 115, 12, 7.5, .gradient(.white))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.white))
        fill(Path { p in
            p.move(to: .init(x: 70, y: 36))
            p.addCurve(to: .init(x: 104, y: 70), control1: .init(x: 88, y: 38), control2: .init(x: 102, y: 52))
            p.addCurve(to: .init(x: 74, y: 58), control1: .init(x: 94, y: 74), control2: .init(x: 80, y: 70))
            p.addCurve(to: .init(x: 70, y: 36), control1: .init(x: 70, y: 50), control2: .init(x: 68, y: 42))
            p.closeSubpath()
        }, .gradient(.caramel))
        ellipse(40, 50, 13, 6, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        fill(Path { p in
            p.move(to: .init(x: 56, y: 84))
            p.addLine(to: .init(x: 64, y: 84))
            p.addLine(to: .init(x: 60, y: 89))
            p.closeSubpath()
        }, .color(ClayColor.Pet.catNose))
        stroke(Path { p in
            p.move(to: .init(x: 14, y: 80))
            p.addLine(to: .init(x: 30, y: 83))
            p.move(to: .init(x: 14, y: 89))
            p.addLine(to: .init(x: 30, y: 88))
            p.move(to: .init(x: 106, y: 80))
            p.addLine(to: .init(x: 90, y: 83))
            p.move(to: .init(x: 106, y: 89))
            p.addLine(to: .init(x: 90, y: 88))
        }, .color(ClayColor.Pet.whisker), width: 2)
        ellipse(31, 92, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(89, 92, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func penguin(waving: Bool) {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        ellipse(46, 117, 12, 6, .gradient(.orange))
        ellipse(74, 117, 12, 6, .gradient(.orange))
        fill(Path { p in
            p.move(to: .init(x: 24, y: 66))
            p.addCurve(to: .init(x: 16, y: 98), control1: .init(x: 10, y: 74), control2: .init(x: 8, y: 92))
            p.addCurve(to: .init(x: 28, y: 72), control1: .init(x: 22, y: 88), control2: .init(x: 26, y: 80))
            p.closeSubpath()
        }, .gradient(.navy))
        if !waving {
            fill(Path { p in
                p.move(to: .init(x: 96, y: 66))
                p.addCurve(to: .init(x: 104, y: 98), control1: .init(x: 110, y: 74), control2: .init(x: 112, y: 92))
                p.addCurve(to: .init(x: 92, y: 72), control1: .init(x: 98, y: 88), control2: .init(x: 94, y: 80))
                p.closeSubpath()
            }, .gradient(.navy))
        }
        fill(Path { p in
            p.move(to: .init(x: 60, y: 16))
            p.addCurve(to: .init(x: 102, y: 74), control1: .init(x: 88, y: 16), control2: .init(x: 102, y: 42))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 102, y: 104), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 18, y: 74), control1: .init(x: 34, y: 118), control2: .init(x: 18, y: 104))
            p.addCurve(to: .init(x: 60, y: 16), control1: .init(x: 18, y: 42), control2: .init(x: 32, y: 16))
            p.closeSubpath()
        }, .gradient(.navy))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 40))
            p.addCurve(to: .init(x: 90, y: 52), control1: .init(x: 70, y: 30), control2: .init(x: 88, y: 34))
            p.addCurve(to: .init(x: 60, y: 110), control1: .init(x: 92, y: 72), control2: .init(x: 86, y: 100))
            p.addCurve(to: .init(x: 30, y: 52), control1: .init(x: 34, y: 100), control2: .init(x: 28, y: 72))
            p.addCurve(to: .init(x: 60, y: 40), control1: .init(x: 32, y: 34), control2: .init(x: 50, y: 30))
            p.closeSubpath()
        }, .gradient(.petCream))
        ellipse(38, 32, 11, 5, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        fill(Path { p in
            p.move(to: .init(x: 53, y: 72))
            p.addQuadCurve(to: .init(x: 67, y: 72), control: .init(x: 60, y: 68))
            p.addQuadCurve(to: .init(x: 53, y: 72), control: .init(x: 60, y: 82))
            p.closeSubpath()
        }, .gradient(.orange))
        ellipse(40, 76, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(80, 76, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        fill(Path { p in
            p.move(to: .init(x: 28, y: 88))
            p.addQuadCurve(to: .init(x: 92, y: 88), control: .init(x: 60, y: 102))
            p.addLine(to: .init(x: 92, y: 96))
            p.addQuadCurve(to: .init(x: 28, y: 96), control: .init(x: 60, y: 110))
            p.closeSubpath()
        }, .gradient(.coral))
        fill(Path { p in
            p.move(to: .init(x: 78, y: 98))
            p.addLine(to: .init(x: 86, y: 116))
            p.addLine(to: .init(x: 76, y: 116))
            p.addLine(to: .init(x: 72, y: 100))
            p.closeSubpath()
        }, .gradient(.coral))
    }

    private func owl(waving: Bool, headwear: Bool) {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path { p in
            p.move(to: .init(x: 28, y: 46))
            p.addLine(to: .init(x: 22, y: 18))
            p.addLine(to: .init(x: 48, y: 36))
            p.closeSubpath()
        }, .gradient(.violet))
        fill(Path { p in
            p.move(to: .init(x: 92, y: 46))
            p.addLine(to: .init(x: 98, y: 18))
            p.addLine(to: .init(x: 72, y: 36))
            p.closeSubpath()
        }, .gradient(.violet))
        fill(Path { p in
            p.move(to: .init(x: 18, y: 70))
            p.addCurve(to: .init(x: 18, y: 104), control1: .init(x: 6, y: 82), control2: .init(x: 8, y: 100))
            p.addCurve(to: .init(x: 26, y: 76), control1: .init(x: 22, y: 92), control2: .init(x: 24, y: 82))
            p.closeSubpath()
        }, .color(ClayColor.Pet.owlWing))
        if !waving {
            fill(Path { p in
                p.move(to: .init(x: 102, y: 70))
                p.addCurve(to: .init(x: 102, y: 104), control1: .init(x: 114, y: 82), control2: .init(x: 112, y: 100))
                p.addCurve(to: .init(x: 94, y: 76), control1: .init(x: 98, y: 92), control2: .init(x: 96, y: 82))
                p.closeSubpath()
            }, .color(ClayColor.Pet.owlWing))
        }
        ellipse(44, 115, 12, 7.5, .gradient(.orange))
        ellipse(76, 115, 12, 7.5, .gradient(.orange))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.violet))
        ellipse(60, 94, 24, 20, .gradient(.petCream))
        stroke(Path { p in
            p.move(to: .init(x: 50, y: 90))
            p.addLine(to: .init(x: 54, y: 93))
            p.addLine(to: .init(x: 58, y: 90))
            p.move(to: .init(x: 62, y: 90))
            p.addLine(to: .init(x: 66, y: 93))
            p.addLine(to: .init(x: 70, y: 90))
            p.move(to: .init(x: 56, y: 99))
            p.addLine(to: .init(x: 60, y: 102))
            p.addLine(to: .init(x: 64, y: 99))
        }, .color(ClayColor.Pet.owlFeather), width: 2)
        ellipse(44, 64, 15, 15, .color(ClayColor.white))
        ellipse(76, 64, 15, 15, .color(ClayColor.white))
        fill(Path { p in
            p.move(to: .init(x: 55, y: 74))
            p.addLine(to: .init(x: 65, y: 74))
            p.addLine(to: .init(x: 60, y: 82))
            p.closeSubpath()
        }, .gradient(.orange))
        ellipse(28, 80, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(92, 80, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        if !headwear {
            fill(Path { p in
                p.move(to: .init(x: 60, y: 18))
                p.addLine(to: .init(x: 86, y: 28))
                p.addLine(to: .init(x: 60, y: 38))
                p.addLine(to: .init(x: 34, y: 28))
                p.closeSubpath()
            }, .color(ClayColor.Pet.owlHat))
            fill(Path(roundedRect: .init(x: 48, y: 30, width: 24, height: 9), cornerRadius: 3), .color(ClayColor.Pet.owlHat))
            stroke(Path { p in
                p.move(to: .init(x: 84, y: 29))
                p.addLine(to: .init(x: 86, y: 44))
            }, .color(ClayColor.Pet.tassel), width: 2.5)
            ellipse(86, 46, 3.5, 3.5, .color(ClayColor.Pet.tassel))
        }
    }

    private func dragon() {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path { p in
            p.move(to: .init(x: 22, y: 66))
            p.addCurve(to: .init(x: 10, y: 32), control1: .init(x: 4, y: 54), control2: .init(x: 2, y: 36))
            p.addCurve(to: .init(x: 32, y: 54), control1: .init(x: 16, y: 44), control2: .init(x: 24, y: 50))
            p.closeSubpath()
        }, .gradient(.lav))
        fill(Path { p in
            p.move(to: .init(x: 98, y: 66))
            p.addCurve(to: .init(x: 110, y: 32), control1: .init(x: 116, y: 54), control2: .init(x: 118, y: 36))
            p.addCurve(to: .init(x: 88, y: 54), control1: .init(x: 104, y: 44), control2: .init(x: 96, y: 50))
            p.closeSubpath()
        }, .gradient(.lav))
        fill(Path { p in
            p.move(to: .init(x: 40, y: 40))
            p.addCurve(to: .init(x: 38, y: 12), control1: .init(x: 34, y: 28), control2: .init(x: 34, y: 18))
            p.addCurve(to: .init(x: 50, y: 36), control1: .init(x: 44, y: 20), control2: .init(x: 48, y: 28))
            p.closeSubpath()
        }, .gradient(.gold))
        fill(Path { p in
            p.move(to: .init(x: 80, y: 40))
            p.addCurve(to: .init(x: 82, y: 12), control1: .init(x: 86, y: 28), control2: .init(x: 86, y: 18))
            p.addCurve(to: .init(x: 70, y: 36), control1: .init(x: 76, y: 20), control2: .init(x: 72, y: 28))
            p.closeSubpath()
        }, .gradient(.gold))
        ellipse(44, 115, 12, 7.5, .gradient(.mint))
        ellipse(76, 115, 12, 7.5, .gradient(.mint))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.mint))
        ellipse(60, 98, 24, 15, .gradient(.petCream))
        ellipse(52, 34, 7, 7, .color(ClayColor.white))
        ellipse(62, 30, 8, 8, .color(ClayColor.white))
        ellipse(71, 35, 6, 6, .color(ClayColor.white))
        ellipse(38, 52, 13, 6, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        ellipse(56, 81, 1.8, 1.8, .color(ClayColor.Pet.ink))
        ellipse(64, 81, 1.8, 1.8, .color(ClayColor.Pet.ink))
        ellipse(32, 84, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(88, 84, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func egg() {
        ellipse(60, 123, 28, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 14))
            p.addCurve(to: .init(x: 98, y: 78), control1: .init(x: 84, y: 14), control2: .init(x: 98, y: 52))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 98, y: 102), control2: .init(x: 82, y: 118))
            p.addCurve(to: .init(x: 22, y: 78), control1: .init(x: 38, y: 118), control2: .init(x: 22, y: 102))
            p.addCurve(to: .init(x: 60, y: 14), control1: .init(x: 22, y: 52), control2: .init(x: 36, y: 14))
            p.closeSubpath()
        }, .gradient(.egg))
        ellipse(46, 48, 8, 7, .color(ClayColor.Pet.eggBlue))
        ellipse(74, 38, 5, 5, .color(ClayColor.Pet.tassel))
        ellipse(76, 90, 9, 8, .color(ClayColor.Pet.eggPink))
        ellipse(42, 96, 5, 5, .color(ClayColor.Pet.eggGreen))
        ellipse(42, 30, 10, 5, .color(ClayColor.white.opacity(0.65)), rotation: -35)
        fill(Path { p in
            p.move(to: .init(x: 104, y: 26))
            p.addLine(to: .init(x: 106.5, y: 32))
            p.addLine(to: .init(x: 112.5, y: 34.5))
            p.addLine(to: .init(x: 106.5, y: 37))
            p.addLine(to: .init(x: 104, y: 43))
            p.addLine(to: .init(x: 101.5, y: 37))
            p.addLine(to: .init(x: 95.5, y: 34.5))
            p.addLine(to: .init(x: 101.5, y: 32))
            p.closeSubpath()
        }, .color(ClayColor.flameCore))
        fill(Path { p in
            p.move(to: .init(x: 14, y: 44))
            p.addLine(to: .init(x: 16, y: 48.5))
            p.addLine(to: .init(x: 20.5, y: 50.5))
            p.addLine(to: .init(x: 16, y: 52.5))
            p.addLine(to: .init(x: 14, y: 57))
            p.addLine(to: .init(x: 12, y: 52.5))
            p.addLine(to: .init(x: 7.5, y: 50.5))
            p.addLine(to: .init(x: 12, y: 48.5))
            p.closeSubpath()
        }, .color(ClayColor.flameCore))
    }

    private func duck() {
        ellipse(62, 123, 34, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        ellipse(50, 118, 10, 5, .gradient(.orange))
        ellipse(74, 118, 10, 5, .gradient(.orange))
        fill(Path { p in
            p.move(to: .init(x: 104, y: 78))
            p.addLine(to: .init(x: 118, y: 64))
            p.addLine(to: .init(x: 112, y: 86))
            p.closeSubpath()
        }, .gradient(.yellow))
        ellipse(66, 90, 42, 28, .gradient(.yellow))
        ellipse(78, 88, 18, 12, .color(ClayColor.Pet.duckWing), rotation: -15)
        ellipse(46, 52, 27, 27, .gradient(.yellow))
        ellipse(36, 36, 9, 5, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        ellipse(22, 60, 14, 7, .gradient(.orange))
        ellipse(30, 60, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(62, 60, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func pig() {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path { p in
            p.move(to: .init(x: 26, y: 50))
            p.addCurve(to: .init(x: 30, y: 22), control1: .init(x: 20, y: 34), control2: .init(x: 24, y: 24))
            p.addCurve(to: .init(x: 46, y: 44), control1: .init(x: 38, y: 28), control2: .init(x: 44, y: 36))
            p.closeSubpath()
        }, .gradient(.pink))
        fill(Path { p in
            p.move(to: .init(x: 94, y: 50))
            p.addCurve(to: .init(x: 90, y: 22), control1: .init(x: 100, y: 34), control2: .init(x: 96, y: 24))
            p.addCurve(to: .init(x: 74, y: 44), control1: .init(x: 82, y: 28), control2: .init(x: 76, y: 36))
            p.closeSubpath()
        }, .gradient(.pink))
        ellipse(44, 115, 12, 7.5, .color(ClayColor.Pet.pigFoot))
        ellipse(76, 115, 12, 7.5, .color(ClayColor.Pet.pigFoot))
        fill(Path { p in
            p.move(to: .init(x: 60, y: 32))
            p.addCurve(to: .init(x: 106, y: 80), control1: .init(x: 90, y: 32), control2: .init(x: 106, y: 54))
            p.addCurve(to: .init(x: 60, y: 118), control1: .init(x: 106, y: 106), control2: .init(x: 86, y: 118))
            p.addCurve(to: .init(x: 14, y: 80), control1: .init(x: 34, y: 118), control2: .init(x: 14, y: 106))
            p.addCurve(to: .init(x: 60, y: 32), control1: .init(x: 14, y: 54), control2: .init(x: 30, y: 32))
            p.closeSubpath()
        }, .gradient(.pink))
        ellipse(40, 50, 13, 6, .color(ClayColor.white.opacity(0.65)), rotation: -28)
        ellipse(60, 88, 15, 11, .color(ClayColor.Pet.snout))
        ellipse(55, 88, 2.6, 3.6, .color(ClayColor.Pet.nostril))
        ellipse(65, 88, 2.6, 3.6, .color(ClayColor.Pet.nostril))
        ellipse(28, 88, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(92, 88, 7.5, 4.5, .color(ClayColor.Pet.blush.opacity(0.5)))
    }

    private func sheep() {
        ellipse(60, 123, 32, 5.5, .color(ClayColor.Pet.ground.opacity(0.2)))
        fill(Path(roundedRect: .init(x: 38, y: 100, width: 12, height: 20), cornerRadius: 6), .color(ClayColor.Pet.sheepLeg))
        fill(Path(roundedRect: .init(x: 70, y: 100, width: 12, height: 20), cornerRadius: 6), .color(ClayColor.Pet.sheepLeg))
        ellipse(30, 56, 20, 20, .gradient(.white))
        ellipse(52, 42, 20, 20, .gradient(.white))
        ellipse(76, 44, 20, 20, .gradient(.white))
        ellipse(94, 60, 20, 20, .gradient(.white))
        ellipse(100, 82, 20, 20, .gradient(.white))
        ellipse(88, 102, 20, 20, .gradient(.white))
        ellipse(62, 108, 20, 20, .gradient(.white))
        ellipse(36, 102, 20, 20, .gradient(.white))
        ellipse(20, 82, 20, 20, .gradient(.white))
        ellipse(60, 76, 20, 20, .gradient(.white))
        ellipse(30, 66, 12, 6, .color(ClayColor.Pet.sheepEar), rotation: -25)
        ellipse(90, 66, 12, 6, .color(ClayColor.Pet.sheepEar), rotation: 25)
        ellipse(60, 76, 22, 25, .color(ClayColor.Pet.sheepFace))
        ellipse(46, 86, 5, 3, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(74, 86, 5, 3, .color(ClayColor.Pet.blush.opacity(0.5)))
        ellipse(50, 52, 10, 10, .color(ClayColor.white))
        ellipse(62, 48, 11, 11, .color(ClayColor.white))
        ellipse(72, 54, 9, 9, .color(ClayColor.white))
    }
}
