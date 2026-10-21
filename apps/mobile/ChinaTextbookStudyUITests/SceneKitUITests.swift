import XCTest
import UIKit

final class SceneKitUITests: XCTestCase {
    @MainActor private func launchScene() -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchArguments = ["-uitest"]; app.launch()
        let entry = app.buttons["clay-gallery-entry"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15)); entry.press(forDuration: 1)
        let next = app.buttons["stage-bottom-trailing"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0..<4 { next.tap() }
        XCTAssertTrue(app.buttons["clay-scene-map"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testSceneMapCubeStatesAndAllDockKinds() {
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launchScene()
        let pause = app.buttons["stage-top-trailing"]
        if pause.value as? String != "开启" { pause.tap() }
        attach("map")
        for state in ["done", "current", "locked", "game"] {
            let button = app.buttons["clay-scene-\(state)"]
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5)
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5)
            button.tap(); attach("cube-\(state)")
        }
        app.buttons["clay-scene-materials"].tap()
        for kind in ["hanzi", "math", "eng", "animal", "story", "idiom", "books", "checkin", "shop", "task", "parent", "pethouse"] {
            XCTAssertTrue(app.otherElements["dock-icon-\(kind)"].exists, "缺少入口：\(kind)")
        }
        attach("materials")
    }

    @MainActor func testReducedMotionFreezesMapAndEveryAnimationKind() {
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launchScene()
        let toggle = app.buttons["stage-top-trailing"]
        print("RD03_REDUCE_MOTION=system:\(UIAccessibility.isReduceMotionEnabled), initial:\(toggle.value ?? "未知")")
        if UIAccessibility.isReduceMotionEnabled { XCTAssertEqual(toggle.value as? String, "开启") }
        if toggle.value as? String != "开启" { toggle.tap() }
        for sample in ["map", "materials"] {
            app.buttons["clay-scene-\(sample)"].tap()
            // 截图包含控件；先等点击后的按压反馈复位，再比较循环动画。
            Thread.sleep(forTimeInterval: 0.6)
            let first = XCUIScreen.main.screenshot()
            Thread.sleep(forTimeInterval: 1.2)
            let second = XCUIScreen.main.screenshot()
            let before = pixels(first.image), after = pixels(second.image)
            XCTAssertEqual(before.count, after.count)
            // Canvas / drawingGroup 的 8 位合成可能产生单级舍入差；仍逐通道比较全屏。
            XCTAssertTrue(zip(before, after).allSatisfy { abs(Int($0.0) - Int($0.1)) <= 1 },
                          "\(sample) 的循环动画应全部停止（允许 1/255 色阶舍入）")
            for (suffix, shot) in [("before", first), ("after", second)] {
                let attachment = XCTAttachment(screenshot: shot)
                attachment.name = "rd03-reduced-\(sample)-\(suffix)"; attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }

    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "rd03-\(name)"; attachment.lifetime = .keepAlways; add(attachment)
    }

    private func pixels(_ image: UIImage) -> Data {
        guard let cg = image.cgImage else { XCTFail("截图无法解码"); return Data() }
        var bytes = Data(count: cg.width * cg.height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height,
                                    bitsPerComponent: 8, bytesPerRow: cg.width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        }
        return bytes
    }
}
