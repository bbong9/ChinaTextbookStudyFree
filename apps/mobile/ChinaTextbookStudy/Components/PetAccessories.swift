import SwiftUI

extension PetArtwork {
    /// 配饰只认识锚点，不分宠物类型。帽子、脸饰、领结分别使用头顶、眼中线、脖子。
    func drawAccessory(_ accessory: PetAccessory, anchors a: PetAnchors) {
        func located(_ anchor: CGPoint, reference: CGPoint, scale: CGFloat) -> PetArtwork {
            var ctx = context
            ctx.translateBy(x: anchor.x, y: anchor.y)
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -reference.x, y: -reference.y)
            return PetArtwork(context: ctx)
        }
        let hat = located(a.head, reference: .init(x: 60, y: 32), scale: a.scale)
        let face = located(a.eyes, reference: .init(x: 60, y: 48), scale: a.scale)
        let neck = located(a.neck, reference: .init(x: 60, y: 89), scale: a.scale)
        let gold = PetPaint.color(ClayColor.Pet.gold)
        let dark = PetPaint.color(ClayColor.Pet.accessoryDark)

        func points(_ pairs: [(CGFloat, CGFloat)]) -> [CGPoint] { pairs.map { .init(x: $0.0, y: $0.1) } }
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
            Path(roundedRect: .init(x: x, y: y, width: w, height: h), cornerRadius: r)
        }
        switch accessory {
        case .noAccessory: break
        case .graduate:
            hat.polygon(points([(42,16),(78,16),(76,26),(44,26)]), dark)
            hat.polygon(points([(60,2),(100,17),(60,32),(20,17)]), .color(ClayColor.Pet.cap))
            hat.stroke(hat.curve(96, 18, 103, 25, 100, 34), gold, width: 2.4)
            hat.ellipse(100, 37, 4, 4, gold)
        case .glasses:
            for x in [CGFloat(45), 75] {
                face.stroke(Path(ellipseIn: .init(x: x - 12, y: 36, width: 24, height: 24)), .color(ClayColor.Pet.glasses), width: 2.6)
            }
            face.stroke(face.curve(57, 47, 60, 44, 63, 47), .color(ClayColor.Pet.glasses), width: 2.4)
        case .sunglasses:
            face.fill(rect(31, 39, 27, 19, 7), .color(ClayColor.Pet.sunglasses))
            face.fill(rect(62, 39, 27, 19, 7), .color(ClayColor.Pet.sunglasses))
            face.stroke(face.curve(58, 45, 60, 45, 62, 45), dark, width: 4)
            face.stroke(face.curve(36, 54, 41, 48, 46, 42), .color(ClayColor.white.opacity(0.5)), width: 2.2)
        case .crown:
            hat.polygon(points([(30,28),(40,10),(50,22),(60,6),(70,22),(80,10),(90,28)]), gold)
            hat.fill(rect(30, 25, 60, 8, 3), .color(ClayColor.Pet.goldDark))
            hat.ellipse(60, 8, 3.2, 3.2, .color(ClayColor.Pet.jewel))
        case .party:
            hat.polygon(points([(60,-4),(44,28),(76,28)]), .color(ClayColor.Pet.party))
            hat.polygon(points([(60,-4),(52,12),(68,12)]), .color(ClayColor.Pet.partyStripe))
            hat.polygon(points([(48,22),(72,22),(76,28),(44,28)]), .color(ClayColor.Pet.partyBand))
            hat.ellipse(60, -6, 5, 5, .color(ClayColor.white))
        case .wizard:
            hat.polygon(points([(62,-8),(38,30),(86,30)]), .color(ClayColor.Pet.wizard))
            hat.fill(rect(34, 26, 56, 9, 4), .color(ClayColor.Pet.wizardBrim))
            hat.polygon(points([(58,4),(60.6,10),(67,10),(62,14),(64,20),(58,16),(52,20),(54,14),(49,10),(55.4,10)]), gold)
        case .astronaut:
            let top = max(3, a.head.y - 27 * a.scale)
            let bottom = min(126, a.neck.y + 13)
            let center = CGPoint(x: a.eyes.x, y: (top + bottom) / 2)
            let rx = 53 * a.scale
            let ry = (bottom - top) / 2
            let shell = Path(ellipseIn: .init(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
            fill(shell, .color(ClayColor.Pet.helmetGlass.opacity(0.25)))
            stroke(shell, .color(ClayColor.Pet.helmetRim), width: 3.5)
            stroke(curve(center.x - rx + 9, center.y - 12, center.x - rx + 6, center.y - ry + 12, center.x - 12, center.y - ry + 7), .color(ClayColor.white.opacity(0.75)), width: 4)
        case .pirate:
            hat.polygon(points([(18,26),(60,4),(102,26),(96,32),(24,32)]), .color(ClayColor.Pet.pirate))
            hat.fill(rect(22, 24, 76, 9, 4), .color(ClayColor.Pet.pirateBand))
            hat.ellipse(60, 17, 5, 5, .color(ClayColor.white))
            face.ellipse(45, 48, 11, 11, .color(ClayColor.Pet.pirate))
            face.stroke(face.curve(24, 40, 58, 42, 92, 44), .color(ClayColor.Pet.pirate), width: 2.6)
        case .headphones:
            let band = Path { p in
                p.addArc(center: .init(x: 60, y: 46), radius: 44, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            }
            face.stroke(band, .color(ClayColor.Pet.headphones), width: 6)
            face.fill(rect(10, 40, 16, 26, 7), .color(ClayColor.Pet.earcup))
            face.fill(rect(94, 40, 16, 26, 7), .color(ClayColor.Pet.earcup))
        case .laurel:
            for side in [-1.0, 1.0] {
                let arc = Path { p in
                    p.addArc(center: .init(x: 60, y: 52), radius: 42,
                             startAngle: .degrees(side > 0 ? 300 : 240), endAngle: .degrees(side > 0 ? 20 : 160), clockwise: side < 0)
                }
                face.stroke(arc, .color(ClayColor.Pet.laurel), width: 3.4)
                for k in 0..<4 {
                    let angle = ((side > 0 ? 310.0 : 230.0) + Double(k) * (side > 0 ? 18 : -18)) * .pi / 180
                    face.ellipse(60 + cos(angle) * 42, 52 + sin(angle) * 42, 5, 3, .color(ClayColor.Pet.laurelLeaf), rotation: side * 35)
                }
            }
        case .bowtie:
            neck.polygon(points([(44,88),(56,82),(56,96),(44,94)]), .color(ClayColor.Pet.bow))
            neck.polygon(points([(76,88),(64,82),(64,96),(76,94)]), .color(ClayColor.Pet.bow))
            neck.ellipse(60, 89, 4.6, 4.6, .color(ClayColor.Pet.bowKnot))
        }
    }
}
