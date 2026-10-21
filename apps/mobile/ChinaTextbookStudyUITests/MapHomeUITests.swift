import XCTest
import UIKit

final class MapHomeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testCurrentLessonReviewAndBookSwitch() {
        let app = launchShellApp()
        let current = app.buttons["lesson-row-g1up-u1-kp1"]
        XCTAssertTrue(current.waitForExistence(timeout: 20))
        XCTAssertTrue(current.isHittable)
        XCTAssertEqual(current.frame.midX / app.windows.firstMatch.frame.width, 0.4, accuracy: 0.08)
        app.buttons["hud-go"].tap()
        XCTAssertTrue(app.buttons["intro-start"].waitForExistence(timeout: 5) || app.buttons["intro-next"].exists)
        skipLessonIntroIfPresent(app)
        app.buttons["关闭"].firstMatch.tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
        app.buttons["hud-avatar"].tap()
        app.buttons["home-menu-review"].tap()
        assertShellTitle(app, "错题本")
        app.buttons["shell-back"].tap()
        app.buttons["hud-book"].tap()
        XCTAssertTrue(app.buttons["book-picker-grade-2"].waitForExistence(timeout: 5))
        app.buttons["book-picker-grade-2"].tap()
        let secondBook = app.buttons["book-picker-book-g2up"]
        revealAndTap(app, secondBook)
        XCTAssertTrue(app.buttons["lesson-row-g2up-u1-kp1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["hud-book"].label.contains("二年级"))
        attachScreenshot("rd09-book-switched")
    }

    /// SE/iPad 只运行这一条截图及命中区用例。
    @MainActor func testCaptureHomeAndTapTargets() {
        let app = launchShellApp()
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].isHittable)
        let ids = ["hud-avatar", "hud-coins", "hud-streak", "hud-hearts", "hud-checkin", "hud-pet-shop", "hud-quests", "hud-parent", "hud-book", "hud-go",
                   "dock-hanzi", "dock-math", "dock-eng", "dock-animal", "dock-story", "dock-idiom", "dock-books"]
        let buttons = ids.map { app.buttons[$0] }
        for button in buttons {
            XCTAssertTrue(button.isHittable, button.identifier)
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5, button.identifier)
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5, button.identifier)
            XCTAssertTrue(app.windows.firstMatch.frame.insetBy(dx: -1, dy: -1).contains(button.frame), button.identifier)
        }
        for pair in zip(buttons[10..<16], buttons[11..<17]) {
            XCTAssertLessThanOrEqual(pair.0.frame.maxX, pair.1.frame.minX + 1)
        }
        attachScreenshot("rd09-home")
        app.buttons["hud-book"].tap()
        XCTAssertTrue(app.buttons["book-picker-grade-2"].waitForExistence(timeout: 5))
        attachScreenshot("rd09-book-picker")
    }

    @MainActor func testLockedNodeUnitGuideAndJump() {
        let app = launchShellApp()
        let locked = app.buttons["lesson-row-g1up-u1-kp2"]
        XCTAssertTrue(locked.waitForExistence(timeout: 20)); locked.tap()
        XCTAssertTrue(app.descendants(matching: .any)["map-locked-hint"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["unit-sign-1"].tap()
        app.buttons["unit-guide-1"].tap()
        assertShellTitle(app, "单元知识手册")
        app.buttons["shell-back"].tap()
        let scroll = app.scrollViews["home-map-scroll"]
        scroll.swipeLeft()
        let sign = app.buttons["unit-sign-2"]
        XCTAssertTrue(sign.waitForExistence(timeout: 5))
        revealAndTap(app, sign, scrollView: scroll)
        app.buttons["unit-jump-2"].tap()
        XCTAssertTrue(app.buttons["检查答案"].waitForExistence(timeout: 5) || app.staticTexts.containing(NSPredicate(format: "label CONTAINS '跳级'")).firstMatch.exists)
    }

    @MainActor func testQuestsAndOriginalDetailSheets() {
        let app = launchShellApp()
        XCTAssertTrue(app.buttons["hud-quests"].waitForExistence(timeout: 20))
        app.buttons["hud-quests"].tap()
        XCTAssertTrue(app.staticTexts["每日任务"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["本周报告"].exists)
        XCTAssertTrue(app.buttons["quests-review"].exists)
        attachScreenshot("rd09-quests")
        app.buttons["shell-back"].tap()
        for (id, text) in [("hud-coins", "我的金币"), ("hud-streak", "连胜护盾"), ("hud-hearts", "红心")] {
            app.buttons[id].tap()
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: 5))
            attachScreenshot("rd09-\(id)")
            revealAndTap(app, app.buttons[id == "hud-coins" ? "关闭" : "知道了"].firstMatch)
        }
    }

    @MainActor func testLongBookScrollReturnsToCurrent() {
        let app = launchShellApp()
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].waitForExistence(timeout: 20))
        let scroll = app.scrollViews["home-map-scroll"]
        for _ in 0..<4 { scroll.swipeLeft(velocity: .fast) }
        let back = app.buttons["back-to-current"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        attachScreenshot("rd09-long-book")
        back.tap()
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].isHittable)
    }

    @MainActor func testDistantCurrentLessonInitiallyVisible() {
        let app = launchShellApp(extraArgs: ["-uitest-map-late-current"])
        let current = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'lesson-row-' AND label CONTAINS '当前'")).firstMatch
        XCTAssertTrue(current.waitForExistence(timeout: 20))
        XCTAssertTrue(current.isHittable)
        XCTAssertEqual(current.frame.midX / app.windows.firstMatch.frame.width, 0.4, accuracy: 0.08)
        attachScreenshot("rd09-distant-current")
    }
    @MainActor func testReducedMotionStaysStillAndLocatesCurrentAfterScroll() {
        let app = launchShellApp(extraArgs: ["-uitest-map-reduce-motion"])
        let current = app.buttons["lesson-row-g1up-u1-kp1"]
        XCTAssertTrue(current.waitForExistence(timeout: 20))
        let scroll = app.scrollViews["home-map-scroll"]
        XCTAssertEqual(scroll.value as? String, "静态场景")
        XCTAssertEqual(app.buttons["hud-go"].value as? String, "动态效果已减少")
        let pet = app.descendants(matching: .any)["map-current-pet"].firstMatch
        XCTAssertTrue((pet.value as? String)?.contains("动态效果已减少") == true)
        let before = pixels(pet.screenshot().image)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(before, pixels(pet.screenshot().image))
        scroll.swipeLeft(velocity: .fast)
        app.buttons["back-to-current"].tap()
        XCTAssertTrue(current.isHittable)
        attachScreenshot("rd09-reduce-motion")
    }

    @MainActor func testLongBookScrollFPS() {
        let app = launchShellApp(extraArgs: ["-uitest-map-fps"])
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].waitForExistence(timeout: 20))
        let scroll = app.scrollViews["home-map-scroll"]
        for _ in 0..<5 { scroll.swipeLeft(velocity: .fast) }
        for _ in 0..<5 { scroll.swipeRight(velocity: .fast) }
        let probe = app.staticTexts["map-performance"]
        XCTAssertTrue(probe.exists)
        let value = probe.value as? String ?? ""
        XCTAssertTrue(value.contains("frames="))
        print("RD09_SCROLL_FPS \(value)")
        attachScreenshot("rd09-scroll-fps")
    }

    @MainActor func testEmptyAndDownloadStates() {
        let empty = launchShellApp(extraArgs: ["-uitest-map-empty"])
        XCTAssertTrue(empty.buttons["map-empty-book-picker"].waitForExistence(timeout: 20))
        attachScreenshot("rd09-empty")
        empty.buttons["map-empty-book-picker"].tap()
        XCTAssertTrue(empty.buttons["book-picker-grade-1"].waitForExistence(timeout: 5))
        empty.terminate()
        let missing = launchShellApp(extraArgs: ["-uitest-map-missing-book"])
        XCTAssertTrue(missing.buttons["book-download-g1up"].waitForExistence(timeout: 20))
        XCTAssertTrue(missing.buttons["book-download-g1up"].isEnabled)
        attachScreenshot("rd09-download")
    }

    @MainActor func testDailyRewardCloudRestoreAndLeagueOverlays() {
        let daily = launchShellApp(extraArgs: ["-uitest-map-daily"])
        XCTAssertTrue(daily.buttons["收下啦"].waitForExistence(timeout: 20))
        attachScreenshot("rd09-daily-reward")
        daily.buttons["收下啦"].tap()
        XCTAssertTrue(daily.buttons["hud-avatar"].exists)
        daily.terminate()
        let cloud = launchShellApp(extraArgs: ["-uitest-map-cloud"])
        XCTAssertTrue(cloud.buttons["cloud-restore-accept"].waitForExistence(timeout: 20))
        attachScreenshot("rd09-cloud-restore")
        cloud.buttons["cloud-restore-decline"].tap()
        XCTAssertTrue(cloud.buttons["hud-avatar"].exists)
        cloud.terminate()
        let league = launchShellApp(extraArgs: ["-uitest-map-league"])
        XCTAssertTrue(league.buttons["league-result-continue"].waitForExistence(timeout: 20))
        attachScreenshot("rd09-league-result")
        revealAndTap(league, league.buttons["league-result-continue"])
        XCTAssertTrue(league.buttons["hud-avatar"].waitForExistence(timeout: 5))
    }

    @MainActor func testStoryDockPreservesStoriesAndReadingRoutes() {
        let app = launchShellApp(extraArgs: ["-uitest-map-book", "chinese-g1up"])
        XCTAssertTrue(app.buttons["dock-story"].waitForExistence(timeout: 20))
        app.buttons["dock-story"].tap()
        app.buttons["课外故事"].tap()
        assertShellTitle(app, "故事")
        attachScreenshot("rd09-stories")
        app.buttons["shell-back"].tap()
        app.buttons["dock-story"].tap()
        app.buttons["课文听读"].tap()
        assertShellTitle(app, "课文阅读")
        attachScreenshot("rd09-reading")
    }

    @MainActor func testChestClaimAndZeroHeartGate() {
        let chestApp = launchShellApp(extraArgs: ["-uitest-map-chest"])
        let chest = chestApp.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'chest-node-' AND label CONTAINS '可领取'")).firstMatch
        XCTAssertTrue(chest.waitForExistence(timeout: 20))
        revealAndTap(chestApp, chest, scrollView: chestApp.scrollViews["home-map-scroll"])
        XCTAssertTrue(chestApp.buttons["chest-open"].waitForExistence(timeout: 5))
        chestApp.buttons["chest-open"].tap()
        XCTAssertTrue(chestApp.buttons["chest-claim"].waitForExistence(timeout: 5))
        attachScreenshot("rd09-chest")
        chestApp.buttons["chest-claim"].tap()
        XCTAssertTrue(chestApp.buttons["hud-avatar"].waitForExistence(timeout: 5))
        chestApp.terminate()
        let zero = launchShellApp(extraArgs: ["-uitest-map-zero-hearts"])
        XCTAssertTrue(zero.buttons["hud-go"].waitForExistence(timeout: 20))
        zero.buttons["hud-go"].tap()
        XCTAssertTrue(zero.staticTexts["下一颗红心还需"].waitForExistence(timeout: 5))
        XCTAssertFalse(zero.buttons["intro-start"].exists)
        attachScreenshot("rd09-zero-hearts")
    }

    private func pixels(_ image: UIImage) -> Data {
        guard let cg = image.cgImage else { XCTFail("截图无法解码"); return Data() }
        var bytes = Data(count: cg.width * cg.height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(cg, in: .init(x: 0, y: 0, width: cg.width, height: cg.height))
        }
        return bytes
    }
}
