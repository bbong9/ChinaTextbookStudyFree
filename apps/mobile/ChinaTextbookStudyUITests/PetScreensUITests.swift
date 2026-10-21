import XCTest
import UIKit

final class PetScreensUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launch(_ extra: [String] = []) -> XCUIApplication {
        launchShellApp(extraArgs: ["-uitest-pet-gems", "2000", "-uitest-pet-treats", "3",
                                  "-uitest-pet-care", "hungry"] + extra)
    }

    @MainActor private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    @MainActor private func capture(_ name: String) {
        attachScreenshot("rd07-\(name)")
    }

    /// 三机型只跑这一条截图用例；同时检查缩放后动作命中区。
    @MainActor func testCapturePetScreens() {
        let app = launch()
        openShellRoute(app, "pet-family", isNew: true)
        XCTAssertTrue(app.buttons["pet-family-pet_mituan"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pet-family-pet_'")).count, 10)
        capture("family")
        let family = app.scrollViews["pet-family-scroll"]
        family.swipeLeft()
        XCTAssertTrue(app.buttons["pet-family-pet_sheep"].exists)
        capture("family-eggs")
        app.buttons["shell-back"].tap()
        openShellRoute(app, "pet-shop", isNew: true)
        waitForShop(app)
        XCTAssertTrue(app.buttons["pet-shop-adopt"].isEnabled)
        capture("shop")
        app.buttons["shell-back"].tap()
        openShellRoute(app, "pet-home", isNew: true)
        XCTAssertTrue(app.buttons["pet-home-feed"].waitForExistence(timeout: 5))
        for id in ["feed", "bathe", "play", "dress"] {
            let button = app.buttons["pet-home-\(id)"]
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5)
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5)
            XCTAssertTrue(button.isHittable)
        }
        capture("home")
    }

    @MainActor func testAdoptionDebitsOnceAndAddsSwitchableCompanion() {
        let app = launch()
        openShellRoute(app, "pet-shop", isNew: true)
        XCTAssertEqual(element(app, "pet-balance").value as? String, "2000")
        app.buttons["pet-shop-adopt"].doubleTap()
        let confirm = app.buttons["pet-shop-confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.buttons["pet-shop-visit"].waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "pet-balance").value as? String, "1550")
        capture("adopted-celebration")
        app.buttons["pet-shop-visit"].tap()
        let fox = app.buttons["pet-home-switch-pet_fox"]
        XCTAssertTrue(fox.waitForExistence(timeout: 5))
        XCTAssertEqual(fox.value as? String, "出战中")
        XCTAssertEqual(element(app, "pet-home-pet").label, "阿橘")
        app.buttons["pet-home-switch-pet_mituan"].tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "米团")
        fox.tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "阿橘")
        capture("adopted-home")
    }

    @MainActor func testFamilySelectsUnownedPetAndOwnedPetSwitchesActive() {
        let app = launch(["-uitest-pet-owned", "pet_fox"])
        openShellRoute(app, "pet-family", isNew: true)
        app.buttons["pet-family-pet_cat"].tap()
        XCTAssertEqual(app.buttons["pet-shop-pet_cat"].value as? String, "已选中")
        XCTAssertTrue(app.buttons["pet-shop-adopt"].label.contains("600"))
        app.buttons["shell-back"].tap()
        app.buttons["pet-family-pet_fox"].tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "阿橘")
        app.buttons["pet-home-previous"].tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "米团")
        app.buttons["pet-home-next"].tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "阿橘")
    }

    @MainActor func testFeedConsumesTreatAndBathPlayShowLiveCooldowns() {
        let app = launch()
        openShellRoute(app, "pet-home", isNew: true)
        let feed = app.buttons["pet-home-feed"]
        XCTAssertEqual(feed.value as? String, "×3")
        XCTAssertEqual(element(app, "pet-home-fullness").value as? String, "30")
        capture("feed-before")
        feed.tap()
        XCTAssertEqual(feed.value as? String, "×2")
        XCTAssertEqual(element(app, "pet-home-fullness").value as? String, "55")
        capture("feed-after")
        let bath = app.buttons["pet-home-bathe"]
        waitEnabled(bath)
        bath.tap()
        XCTAssertFalse(bath.isEnabled)
        let countdown = bath.value as? String
        XCTAssertTrue(countdown?.contains(":") == true)
        let play = app.buttons["pet-home-play"]
        waitEnabled(play)
        play.tap()
        XCTAssertFalse(play.isEnabled)
        XCTAssertTrue((play.value as? String)?.contains(":") == true)
        let ticks = NSPredicate { _, _ in bath.value as? String != countdown }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ticks, object: bath)], timeout: 4), .completed)
        capture("care-cooldowns")
    }

    @MainActor func testCaptureShopFiveStates() {
        let app = launch(["-uitest-pet-owned", "pet_cat,pet_duck,pet_pig,pet_sheep"])
        openShellRoute(app, "pet-shop", isNew: true)
        waitForShop(app)
        capture("state-available")
        app.buttons["pet-shop-pet_dragon"].tap()
        XCTAssertFalse(app.buttons["pet-shop-adopt"].isEnabled)
        XCTAssertTrue(app.buttons["pet-shop-adopt"].label.contains("Lv10"))
        capture("state-locked")
        app.buttons["pet-shop-pet_cat"].tap()
        XCTAssertTrue(app.buttons["pet-shop-adopt"].label.contains("已领养"))
        capture("state-owned")
        app.buttons["pet-shop-pet_egg"].tap()
        XCTAssertFalse(app.buttons["pet-shop-adopt"].isEnabled)
        XCTAssertEqual(app.buttons["pet-shop-adopt"].label, "已孵完")
        capture("state-sold-out")
        app.terminate()
        let poor = launch(["-uitest-pet-gems", "0"])
        openShellRoute(poor, "pet-shop", isNew: true)
        XCTAssertFalse(poor.buttons["pet-shop-adopt"].isEnabled)
        XCTAssertTrue(poor.buttons["pet-shop-adopt"].label.contains("还差 450 金币"))
        capture("state-insufficient")
    }

    @MainActor func testEggHatchesInOrderWithCompleteFrameEvidence() {
        let app = launch(["-uitest-egg-steps"])
        openShellRoute(app, "pet-shop", isNew: true)
        app.buttons["pet-shop-pet_egg"].tap()
        for (index, pet) in ["小黄鸭", "噜噜", "咩咩"].enumerated() {
            app.buttons["pet-shop-adopt"].tap()
            XCTAssertTrue(app.buttons["pet-shop-confirm"].waitForExistence(timeout: 3))
            app.buttons["pet-shop-confirm"].tap()
            XCTAssertTrue(app.buttons["pet-egg-next"].waitForExistence(timeout: 5))
            for phase in 0...10 {
                XCTAssertEqual(element(app, "pet-egg-phase").value as? String, String(phase))
                if index == 0 { capture("egg-frame-\(phase)") }
                if phase < 10 { app.buttons["pet-egg-next"].tap() }
            }
            XCTAssertEqual(app.buttons["pet-egg-done"].label, "带\(pet)回小屋")
            if index > 0 { capture("egg-hatched-\(index)") }
            app.buttons["pet-egg-done"].tap()
            XCTAssertEqual(element(app, "pet-home-pet").label, pet)
            app.buttons["shell-back"].tap()
            XCTAssertEqual(element(app, "pet-balance").value as? String, String(2000 - (index + 1) * 300))
        }
        XCTAssertEqual(app.buttons["pet-shop-adopt"].label, "已孵完")
    }

    @MainActor func testSwitchFollowsHomeLessonAndResult() {
        let app = launch(["-uitest-pet-owned", "pet_fox"])
        openShellRoute(app, "pet-home", isNew: true)
        app.buttons["pet-home-next"].tap()
        XCTAssertEqual(element(app, "pet-home-pet").label, "阿橘")
        app.buttons["shell-back"].tap()
        XCTAssertTrue(app.scrollViews["shell-new-routes"].waitForExistence(timeout: 5))
        // 正常路径首页在 RD-09 才新增宠物展示位，本卡保留真实现状截图。
        capture("switched-home-pending-rd09")
        revealAndTap(app, app.buttons["lesson-row-g1up-u1-kp1"].firstMatch)
        app.buttons["lesson-start"].tap()
        XCTAssertTrue(element(app, "pet-fox").waitForExistence(timeout: 5))
        let namedBubble = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "阿橘：")).firstMatch
        XCTAssertTrue(namedBubble.waitForExistence(timeout: 3))
        capture("switched-course")
        skipLessonIntroIfPresent(app)
        let answers = ["tf-错", "tf-对", "lesson-choice-2", "lesson-choice-1", "lesson-choice-3",
                       "lesson-choice-2", "lesson-choice-2", "lesson-choice-2",
                       "lesson-fill_blank-key-3", "lesson-fill_blank-key-6",
                       "lesson-fill_blank-key-7", "lesson-fill_blank-key-8"]
        for id in answers {
            let check = app.buttons["检查答案"]
            XCTAssertTrue(check.waitForExistence(timeout: 5))
            let answer = app.buttons[id]
            XCTAssertTrue(answer.waitForExistence(timeout: 5))
            XCTAssertTrue(answer.isHittable)
            answer.tap()
            check.tap()
            XCTAssertTrue(app.buttons["继续"].firstMatch.waitForExistence(timeout: 5))
            XCTAssertTrue(namedBubble.waitForExistence(timeout: 3))
            app.buttons["继续"].firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["result-continue"].waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, "pet-fox").exists)
        capture("switched-result")
    }

    @MainActor func testOwnedThemeAndBackdropRemainSwitchableInSettings() {
        let app = launch(["-uitest-pet-legacy", "owned"])
        openShellRoute(app, "profile")
        let settings = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "设置")).firstMatch
        revealAndTap(app, settings)
        let theme = app.buttons["settings-owned-theme"]
        revealAndTap(app, theme)
        XCTAssertTrue(app.buttons["樱花粉"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["海洋蓝"].exists, "未购买主题不能出现在切换列表")
        app.buttons["Duolingo 绿"].tap()
        revealAndTap(app, theme)
        app.buttons["樱花粉"].tap()
        let backdrop = app.buttons["settings-owned-backdrop"]
        revealAndTap(app, backdrop)
        XCTAssertTrue(app.buttons["森林晨光"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["蓝天白云"].exists)
        app.buttons["干净简洁"].tap()
        revealAndTap(app, backdrop)
        app.buttons["森林晨光"].tap()
        capture("legacy-owned-settings")
    }

    @MainActor private func waitEnabled(_ button: XCUIElement) {
        let ready = NSPredicate { _, _ in button.isEnabled }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: button)], timeout: 5), .completed)
    }

    @MainActor private func waitForShop(_ app: XCUIApplication) {
        let lastShelf = app.buttons["pet-shop-pet_egg"]
        XCTAssertTrue(lastShelf.waitForExistence(timeout: 5))
        var previousFrame = CGRect.null
        let settled = NSPredicate { _, _ in
            let frame = lastShelf.frame
            defer { previousFrame = frame }
            return frame == previousFrame && app.windows.firstMatch.frame.contains(frame) && lastShelf.isHittable
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: settled, object: lastShelf)], timeout: 8), .completed)
    }

}
