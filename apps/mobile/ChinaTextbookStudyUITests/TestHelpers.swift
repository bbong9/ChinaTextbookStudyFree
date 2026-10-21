import XCTest
import UIKit

extension XCTestCase {
    @MainActor
    func launchShellApp(extraArgs: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"] + extraArgs
        app.launch()
        return app
    }

    @MainActor
    func assertShellTitle(_ app: XCUIApplication, _ title: String,
                          file: StaticString = #filePath, line: UInt = #line) {
        let heading = app.staticTexts["shell-page-title"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(heading.label, title, file: file, line: line)
        XCTAssertFalse(app.navigationBars.firstMatch.exists, file: file, line: line)
    }

    @MainActor
    func openShellRoute(_ app: XCUIApplication, _ id: String, isNew: Bool = false) {
        let home = app.buttons["hud-avatar"]
        if !home.exists { returnToShellHome(app) }
        XCTAssertTrue(home.waitForExistence(timeout: 30))
        switch id {
        case "profile", "achievements", "league", "review", "settings":
            home.tap(); app.buttons["home-menu-\(id)"].tap()
        case "pet-home", "pet-family":
            app.buttons["landmark-pet-home"].tap()
            if id == "pet-family" {
                XCTAssertTrue(app.buttons["pet-home-family"].waitForExistence(timeout: 5))
                app.buttons["pet-home-family"].tap()
            }
        case "pet-shop": app.buttons["hud-pet-shop"].tap()
        case "check-in": app.buttons["hud-checkin"].tap()
        case "quests": app.buttons["hud-quests"].tap()
        case "parent-center": app.buttons["hud-parent"].tap()
        case "math-train": app.buttons["dock-math"].tap()
        case "english-balloons": app.buttons["dock-eng"].tap()
        case "animals": app.buttons["dock-animal"].tap()
        case "idiom-picker": app.buttons["dock-idiom"].tap()
        case "reading-room": app.buttons["dock-books"].tap()
        case "grades": app.buttons["hud-book"].tap()
        case "shop", "hanzi-map", "hanzi-lesson", "idiom-player", "bedtime-stories":
            app.buttons["hud-quests"].tap()
            if id == "shop" { app.buttons["quests-shop"].tap() }
            else {
                let more = app.buttons["更多玩法"]
                revealAndTap(app, more)
                revealAndTap(app, app.buttons["quests-\(id)"])
            }
        default: XCTFail("没有对应的首页入口：\(id)")
        }
    }

    @MainActor
    func returnToShellHome(_ app: XCUIApplication) {
        let home = app.buttons["hud-avatar"]
        for _ in 0..<8 {
            if home.exists { break }
            let back = app.buttons["shell-back"]
            guard back.exists else { break }
            let title = app.staticTexts["shell-page-title"]
            let previousTitle = title.exists ? title.label : nil
            back.tap()
            if previousTitle == nil {
                _ = home.waitForExistence(timeout: 0.5)
                continue
            }
            let returned = NSPredicate { _, _ in
                let heading = app.staticTexts["shell-page-title"]
                return home.exists || (heading.exists && heading.label != previousTitle)
            }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: returned, object: app)], timeout: 5), .completed)
        }
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
    }

    @MainActor
    func revealAndTap(_ app: XCUIApplication, _ element: XCUIElement, scrollView: XCUIElement? = nil, tries: Int = 10) {
        guard element.waitForExistence(timeout: 5) else {
            XCTFail("待点击的元素未出现：\(element)")
            return
        }
        let identifier = element.identifier.isEmpty ? element.label : element.identifier
        let parents = app.scrollViews.containing(element.elementType, identifier: identifier).allElementsBoundByIndex
        let surface = scrollView ?? parents.first
        func visibleViewport() -> CGRect {
            var viewport = app.windows.firstMatch.frame
            for parent in parents { viewport = viewport.intersection(parent.frame) }
            if app.keyboards.firstMatch.exists {
                let keyboardTop = app.keyboards.firstMatch.frame.minY
                viewport = viewport.intersection(CGRect(x: 0, y: 0, width: app.windows.firstMatch.frame.width, height: keyboardTop))
            }
            return viewport
        }
        func fullyVisible() -> Bool {
            let viewport = visibleViewport()
            return !viewport.isNull && viewport.insetBy(dx: -1, dy: -1).contains(element.frame) && element.isHittable
        }
        // 部分露出的按钮也可能被 XCTest 判成可点；先滚入实际视口，避免点到页脚或遮挡层。
        for _ in 0..<tries {
            if fullyVisible() { break }
            let scroll = surface ?? app
            var viewport = scroll.frame.intersection(app.windows.firstMatch.frame)
            if app.keyboards.firstMatch.exists {
                viewport.size.height = max(0, min(viewport.maxY, app.keyboards.firstMatch.frame.minY) - viewport.minY)
            }
            let frame = element.frame
            let horizontal = frame.minY >= viewport.minY && frame.maxY <= viewport.maxY
                && (frame.minX < visibleViewport().minX || frame.maxX > visibleViewport().maxX)
            if horizontal, let row = parents.last {
                viewport = viewport.intersection(row.frame)
            }
            let distance: CGFloat
            if horizontal {
                distance = frame.minX < viewport.minX ? frame.minX - viewport.minX - 12 : frame.maxX - viewport.maxX + 12
            } else {
                distance = frame.minY < viewport.minY ? frame.minY - viewport.minY - 12 : frame.maxY - viewport.maxY + 12
            }
            let limit = (horizontal ? viewport.width : viewport.height) * 0.6
            // 小于系统拖动阈值的手势不会滚动，至少移动 44pt。
            let delta = distance < 0 ? -min(max(-distance, 44), limit) : min(max(distance, 44), limit)
            // 起点避开系统边缘手势，尤其是横屏 iPhone 的 Home 指示条。
            let startX = horizontal ? (delta > 0 ? viewport.maxX - 44 : viewport.minX + 44) : viewport.midX
            let startY = horizontal ? viewport.midY : (delta > 0 ? viewport.maxY - 44 : viewport.minY + 44)
            let start = app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: startX, dy: startY))
            let end = start.withOffset(CGVector(dx: horizontal ? -delta : 0, dy: horizontal ? 0 : -delta))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        let visible = fullyVisible()
        if !visible {
            print(app.debugDescription)
            attachScreenshot("rd-01-unreachable-control")
        }
        XCTAssertTrue(visible, "滚动后仍无法完整显示并点击：\(element)")
        if visible { element.tap() }
    }

    @MainActor
    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Wave E2 (content-2)：首次进入带 knowledge 的课会先弹分步讲解。
    /// 需要直达题目的老流程用这个助手翻完讲解（最多 6 页）再继续；
    /// 没弹讲解（已看过 / 无 knowledge）时直接返回。
    @MainActor
    func skipLessonIntroIfPresent(_ app: XCUIApplication) {
        let start = app.buttons["intro-start"]
        let next = app.buttons["intro-next"]
        // 等讲解（任一按钮）出现；3 秒没出现就当没有讲解。
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline && !start.exists && !next.exists {
            usleep(200_000)
        }
        for _ in 0..<6 {
            if start.exists { start.tap(); return }
            guard next.exists else { return }
            next.tap()
        }
        if start.exists { start.tap() }
    }
}
