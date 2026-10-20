import XCTest
import UIKit

final class PetGalleryUITests: XCTestCase {
    @MainActor private func launchPets() -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()
        let entry = app.buttons["clay-gallery-entry"]
        XCTAssertTrue(entry.waitForExistence(timeout: 20))
        entry.press(forDuration: 1)
        XCTAssertTrue(app.buttons["stage-top-leading"].waitForExistence(timeout: 5))
        // 从首组向前翻一页即可到新增的宠物页。
        app.buttons["stage-bottom-leading"].tap()
        XCTAssertTrue(app.buttons["pet-section-0"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testPetsAccessoriesAndThreeRepeatableReactions() {
        let app = launchPets()
        attach("pets-landscape")
        XCTAssertTrue(app.descendants(matching: .any)["pet-sample-mituan-happy"].exists)
        app.buttons["pet-section-1"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pet-accessory-mituan-skin_graduate"].exists)
        attach("accessories-landscape")
        app.buttons["pet-section-2"].tap()
        XCTAssertGreaterThan(app.buttons["pet-section-0"].frame.minY,
                             app.staticTexts["clay-stage-metrics"].frame.maxY,
                             "反应预览不能挤占舞台顶部信息区")
        for (index, reaction) in ["correct", "wrong", "levelup", "levelup"].enumerated() {
            let button = app.buttons["pet-react-\(reaction)"]
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5)
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5)
            button.tap()
            XCTAssertEqual(app.staticTexts["pet-motion-status"].value as? String, "\(reaction),\(index + 1)")
        }
        attach("reactions-landscape")
    }

    @MainActor func testReduceMotionStopsBreathingBlinkWaveAndReactions() {
        let app = launchPets()
        app.buttons["pet-section-2"].tap()
        let toggle = app.buttons["stage-top-trailing"]
        print("RD04_REDUCE_MOTION=system:\(UIAccessibility.isReduceMotionEnabled), initial:\(toggle.value ?? "未知")")
        if toggle.value as? String != "开启" { toggle.tap() }
        let preview = app.descendants(matching: .any)["pet-reaction-preview"]
        XCTAssertTrue(preview.value as? String == "挥手，无配饰，动态效果已减少")
        let first = preview.screenshot()
        Thread.sleep(forTimeInterval: 1.1)
        XCTAssertEqual(pixels(first.image), pixels(preview.screenshot().image))
        app.buttons["pet-react-levelup"].tap()
        XCTAssertEqual(pixels(first.image), pixels(preview.screenshot().image), "减少动态效果时升级不应旋转或位移")
        attach("reduce-motion-landscape")
    }

    private func pixels(_ image: UIImage) -> Data {
        guard let cg = image.cgImage else { XCTFail("截图无法解码"); return Data() }
        var bytes = Data(count: cg.width * cg.height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let ctx = CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.draw(cg, in: .init(x: 0, y: 0, width: cg.width, height: cg.height))
        }
        return bytes
    }

    @MainActor private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "rd04-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
