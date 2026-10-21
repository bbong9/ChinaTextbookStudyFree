import SwiftUI

struct TrainCar {
    var gradient: ClayGradient = .blue
    var label: String? = nil
    var ink: Color = ClayColor.trainNumber
}

/// engineSign 对应 S.train 的最后一个参数；内容使用车头局部坐标。
struct TrainView<EngineSign: View>: View {
    var x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1
    var cars: [TrainCar] = []
    @ViewBuilder var engineSign: () -> EngineSign

    private func wheel(_ x: CGFloat) -> [SceneNode] {
        [.shape(sceneEllipse(x, 0, 13, 13), fill: .color(ClayColor.trainIron)),
         .shape(sceneEllipse(x, 0, 6, 6), fill: .gradient(.gold))]
    }

    private var nodes: [SceneNode] {
        var nodes: [SceneNode] = []
        for (index, car) in cars.enumerated() {
            let cx = -150 - CGFloat(index) * 132
            var body: [SceneNode] = [
                .shape(sceneRect(cx - 58, -62, 118, 56, 12), fill: .gradient(car.gradient)),
                .shape(sceneRect(cx - 50, -70, 102, 12, 6), fill: .color(ClayColor.white), opacity: 0.9)
            ]
            if let label = car.label {
                body += [.shape(sceneRect(cx - 32, -56, 66, 44, 12), fill: .color(ClayColor.creamTop)),
                         .text(label, at: CGPoint(x: cx + 1, y: -23), font: ClayFont.nunito(size: 32), color: car.ink)]
            }
            body += wheel(cx - 30) + wheel(cx + 32)
            body.append(.shape(sceneRect(cx + 58, -24, 20, 6, 3), fill: .color(ClayColor.trainIron)))
            nodes.append(.group(body, shadow: true))
        }
        return nodes + SceneArtwork.trainEngine
    }

    var body: some View {
        let left = cars.isEmpty ? -110 : -230 - CGFloat(cars.count - 1) * 132
        ZStack(alignment: .topLeading) {
            SceneSprite(nodes: nodes, bounds: CGRect(x: left, y: -158, width: 92 - left, height: 192),
                        x: x, y: y, scale: scale)
            engineSign().frame(width: 1, height: 1, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading).position(x: x, y: y)
        }.accessibilityHidden(true)
    }
}

extension TrainView where EngineSign == EmptyView {
    init(x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1, cars: [TrainCar] = []) {
        self.x = x; self.y = y; self.scale = scale; self.cars = cars; engineSign = { EmptyView() }
    }
}
