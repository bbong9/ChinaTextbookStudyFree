import SwiftUI

/// 使用 RD-03 的场景渲染器、渐变和 RD-04 狐狸，照 scrStory 的 844×390 坐标绘制。
struct StoryNightScene: View {
    var body: some View {
        GeometryReader { geometry in
            let origin = CGPoint(x: (geometry.size.width - 844) / 2, y: geometry.size.height - 390)
            ZStack(alignment: .topLeading) {
                ClayGradient.night.view
                ClayColor.storyGround.frame(height: max(0, geometry.size.height - 210)).frame(maxHeight: .infinity, alignment: .bottom)
                Canvas { context, _ in
                    var context = context
                    context.translateBy(x: origin.x, y: origin.y)
                    var nodes: [SceneNode] = []
                    for i in 0..<26 {
                        nodes.append(.shape(sceneEllipse(CGFloat(i * 97 % 844), CGFloat(i * 53 % 170 + 10),
                            i % 3 == 0 ? 2.6 : 1.6, i % 3 == 0 ? 2.6 : 1.6), fill: .color(ClayColor.white)))
                    }
                    nodes += [
                        .shape(sceneEllipse(640, 80, 40, 40), fill: .gradient(.gold)),
                        .shape(sceneEllipse(660, 68, 36, 36), fill: .color(ClayColor.storyMoonCutout)),
                        .shape(sceneEllipse(640, 80, 80, 80), fill: .gradient(.warmglow), opacity: 0.25),
                        .shape(scenePath {
                            $0.move(to: CGPoint(x: -1000, y: 200)); $0.addLine(to: CGPoint(x: 0, y: 200))
                            $0.addCurve(to: CGPoint(x: 300, y: 196), control1: CGPoint(x: 100, y: 170), control2: CGPoint(x: 220, y: 180))
                            $0.addCurve(to: CGPoint(x: 844, y: 190), control1: CGPoint(x: 400, y: 168), control2: CGPoint(x: 560, y: 172))
                            $0.addLines([CGPoint(x: 2000, y: 190), CGPoint(x: 2000, y: 1000), CGPoint(x: -1000, y: 1000)])
                            $0.closeSubpath()
                        }, fill: .color(ClayColor.storyGround)),
                        .shape(sceneEllipse(520, 300, 260, 62), fill: .color(ClayColor.storyLake),
                               stroke: .color(ClayColor.storyLakeEdge), width: 4),
                        .shape(sceneEllipse(560, 304, 26, 9), fill: .color(ClayColor.windowLight), opacity: 0.85)
                    ]
                    for (i, x) in [60, 140, 760, 820].enumerated() {
                        nodes.append(.shape(scenePath {
                            $0.addLines([CGPoint(x: x - 30, y: 210), CGPoint(x: x, y: 120 + i * 10), CGPoint(x: x + 30, y: 210)])
                            $0.closeSubpath()
                        }, fill: .color(ClayColor.storyPine)))
                    }
                    for i in 0..<7 {
                        nodes.append(.shape(sceneEllipse(CGFloat(180 + i * 90), CGFloat(150 + i % 3 * 30), 3.5, 3.5), fill: .color(ClayColor.storyFirefly)))
                    }
                    nodes.forEach { $0.draw(in: context, accent: ClayColor.white) }
                }
                PetView(kind: .fox, mood: .happy, size: 150)
                    .rotationEffect(.degrees(12))
                    .position(x: origin.x + 300, y: origin.y + 220)
                    .environment(\.petAnimationsPaused, true)
            }
        }
        .accessibilityHidden(true)
    }
}

struct StoryIllustration: View {
    let story: Story
    var bedtime = false
    var forceFallback = false

    var body: some View {
        GeometryReader { geometry in
            if !forceFallback,
               let url = AssetDownloader.storyImageURL(bookId: story.bookId, storyId: story.id, imagePath: story.image),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            } else {
                StoryNightScene()
            }
        }
        .overlay {
            LinearGradient(colors: [ClayColor.black.opacity(0.5), .clear, ClayColor.black.opacity(0.42)],
                           startPoint: .bottom, endPoint: .top)
        }
        .overlay { if bedtime { ClayColor.black.opacity(0.32) } }
    }
}
