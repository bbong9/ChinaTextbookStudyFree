import XCTest
import UIKit

final class ClayGalleryUITests: XCTestCase {
    @MainActor private func launchGallery() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
        let entry = app.buttons["hud-avatar"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15))
        entry.press(forDuration: 1)
        XCTAssertTrue(app.buttons["stage-top-leading"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testAnchorsStepStatesCallbackAndGalleryPages() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launchGallery()
        let metrics = app.staticTexts["clay-stage-metrics"]
        let raw = try XCTUnwrap(metrics.value as? String)
        let values = raw.split(separator: ",").compactMap { Double($0) }
        XCTAssertEqual(values.count, 5)
        guard values.count == 5 else { return }
        let s = values[0], top = values[1] * s, left = values[2] * s
        let bottom = values[3] * s, right = values[4] * s
        let tl = app.buttons["stage-top-leading"].frame
        let tr = app.buttons["stage-top-trailing"].frame
        let bl = app.buttons["stage-bottom-leading"].frame
        let br = app.buttons["stage-bottom-trailing"].frame
        let screen = app.frame
        XCTAssertEqual(tl.minX, screen.minX + left + 16 * s, accuracy: 2)
        XCTAssertEqual(tl.minY, screen.minY + top + 16 * s, accuracy: 2)
        XCTAssertEqual(tr.maxX, screen.maxX - right - 16 * s, accuracy: 2)
        XCTAssertEqual(tr.minY, tl.minY, accuracy: 2)
        XCTAssertEqual(bl.minX, tl.minX, accuracy: 2)
        XCTAssertEqual(bl.maxY, screen.maxY - bottom - 16 * s, accuracy: 2)
        XCTAssertEqual(br.maxX, tr.maxX, accuracy: 2)
        XCTAssertEqual(br.maxY, bl.maxY, accuracy: 2)
        for frame in [tl, tr, bl, br] {
            XCTAssertGreaterThanOrEqual(frame.width, 43.5)
            XCTAssertGreaterThanOrEqual(frame.height, 43.5)
        }
        XCTAssertEqual(app.buttons["clay-steps-0"].value as? String, "已完成")
        XCTAssertEqual(app.buttons["clay-steps-1"].value as? String, "当前")
        XCTAssertEqual(app.buttons["clay-steps-2"].value as? String, "未到")
        attach("01-components")
        app.buttons["clay-steps-2"].tap()
        XCTAssertEqual(app.buttons["clay-steps-2"].value as? String, "当前")
        XCTAssertTrue(app.staticTexts["clay-step-result"].label.contains("索引：2"))
        attach("02-step-callback")
        app.buttons["stage-bottom-trailing"].tap()
        XCTAssertTrue(app.staticTexts["g-sky"].exists)
        XCTAssertTrue(app.staticTexts["p-red"].exists)
        attach("03-gradients")
        app.buttons["stage-bottom-trailing"].tap()
        for name in ["back", "pause", "help", "gu", "left", "right", "speaker", "mic", "redo", "play", "close", "heart", "flame", "lock"] {
            let icon = app.buttons["clay-icon-\(name)"]
            XCTAssertTrue(icon.exists)
            XCTAssertGreaterThanOrEqual(icon.frame.width, 43.5)
            XCTAssertGreaterThanOrEqual(icon.frame.height, 43.5)
        }
        attach("04-icons-fonts")
        print("RD02_FONT_STATUS=\(app.staticTexts["clay-kai-status"].label)")
        app.buttons["stage-top-leading"].tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
    }

    @MainActor func testReduceMotionStopsGoButton() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launchGallery()
        let toggle = app.buttons["stage-top-trailing"]
        let systemReduced = UIAccessibility.isReduceMotionEnabled
        print("RD02_REDUCE_MOTION=system:\(systemReduced), initial:\(toggle.value ?? "未知")")
        if systemReduced { XCTAssertEqual(toggle.value as? String, "开启") }
        if toggle.value as? String != "开启" { toggle.tap() }
        let go = app.buttons["clay-go"]
        XCTAssertEqual(go.value as? String, "动态效果已减少")
        let first = go.screenshot()
        Thread.sleep(forTimeInterval: 1.1)
        let second = go.screenshot()
        for (name, screenshot) in [("go-static-before", first), ("go-static-after", second)] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        // 比较解码后的像素，PNG 的压缩/元数据不参与判断。
        XCTAssertEqual(pixels(first.image), pixels(second.image), "减少动态效果后按钮像素应保持静止")
        attach("05-reduce-motion")
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

    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "rd02-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
