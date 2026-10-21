import XCTest

/// 旧页面仍可从横屏首页进入；保留原有功能回归，并采集 AC4 证据。
/// RD-00 的完整可见性检查由 TestHelpers 统一提供，适配自绘页头和祖先滚动视口。
final class LayoutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTemporaryEntrancesReachLegacyPages() {
        let app = launchShellApp()
        for (id, title) in [("league", "排行"), ("review", "错题本"), ("shop", "商店"),
                            ("profile", "我的"), ("achievements", "成就墙")] {
            openShellRoute(app, id)
            assertShellTitle(app, title)
            XCTAssertTrue(app.buttons["shell-back"].isHittable)
            switch id {
            case "league":
                XCTAssertTrue(app.staticTexts["排行榜还没解锁"].exists)
            case "review":
                XCTAssertTrue(app.staticTexts["还没有错题"].exists)
            case "shop":
                revealAndTap(app, app.buttons["shop-open-home"])
                revealAndTap(app, app.buttons["pet-home-dress"])
                revealAndTap(app, app.buttons["cosmetic-skin_graduate"])
                let confirm = app.buttons["cosmetic-confirm-buy"]
                XCTAssertTrue(confirm.waitForExistence(timeout: 3))
                XCTAssertTrue(confirm.isEnabled)
                revealAndTap(app, confirm)
                let cap = app.buttons["cosmetic-skin_graduate"]
                let equipped = NSPredicate { _, _ in cap.label.contains("使用中") }
                XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: equipped, object: cap)], timeout: 5), .completed)
                app.buttons["pet-dress-close"].tap()
            case "profile":
                revealAndTap(app, app.buttons["修改昵称"])
                XCTAssertTrue(app.textFields["rename-field"].waitForExistence(timeout: 4))
                app.textFields["rename-field"].typeText("\n")
                revealAndTap(app, app.buttons["rename-cancel"], scrollView: app.scrollViews["rename-scroll"])
            default:
                XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH '已解锁'")).firstMatch.exists)
            }
            attachScreenshot("rd-01-legacy-\(id)")
            returnToShellHome(app)
        }
    }

    /// 通过实际答错生成错题，验证“开始复习”在横屏下仍能点击。
    @MainActor
    func testReviewEntryOpensRunnerWithMistake() {
        let app = launchShellApp()
        let firstLesson = app.buttons["lesson-row-g1up-u1-kp1"].firstMatch
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 15))
        firstLesson.tap()
        app.buttons["lesson-start"].tap()
        skipLessonIntroIfPresent(app)
        XCTAssertTrue(app.buttons["检查答案"].waitForExistence(timeout: 8))
        app.buttons["tf-对"].firstMatch.tap() // seed 第一题答案为“错”。
        app.buttons["检查答案"].tap()
        XCTAssertTrue(app.buttons["知道了"].waitForExistence(timeout: 5))
        app.buttons["关闭"].firstMatch.tap()
        XCTAssertTrue(app.buttons["lesson-quit"].waitForExistence(timeout: 3))
        app.buttons["lesson-quit"].tap()
        openShellRoute(app, "review")
        revealAndTap(app, app.buttons["review-start"])
        assertShellTitle(app, "错题复习")
        revealAndTap(app, app.buttons["tf-错"].firstMatch)
        XCTAssertTrue(app.buttons["shell-back"].isHittable)
        attachScreenshot("rd-01-legacy-review-runner")
        revealAndTap(app, app.buttons["检查"])
        XCTAssertTrue(app.staticTexts["答对了！"].waitForExistence(timeout: 5))
        revealAndTap(app, app.buttons["完成复习"])
        XCTAssertTrue(app.staticTexts["复习完成！"].waitForExistence(timeout: 5))
        revealAndTap(app, app.buttons["review-summary-back"], scrollView: app.scrollViews["review-summary-scroll"])
        assertShellTitle(app, "错题本")
        XCTAssertTrue(app.buttons["shell-back"].isHittable)
    }

    @MainActor
    func testProfileReachesAchievementsAndSettings() {
        let app = launchShellApp()
        openShellRoute(app, "profile")
        let achievements = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "成就墙")).firstMatch
        revealAndTap(app, achievements)
        assertShellTitle(app, "成就墙")
        app.buttons["shell-back"].tap()
        assertShellTitle(app, "我的")
        let settings = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "设置")).firstMatch
        revealAndTap(app, settings)
        assertShellTitle(app, "设置")
    }

    @MainActor
    func testProfileShowsQuestsAndWeeklyReport() {
        let app = launchShellApp()
        openShellRoute(app, "profile")
        assertShellTitle(app, "我的")
        XCTAssertTrue(app.staticTexts["每日任务"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["本周报告"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["profile-joined-date"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'quest-claim-'")).count, 0)
        attachScreenshot("profile-quests-report")
    }

    @MainActor
    func testGradeBrowsingAndBookSwitching() {
        let app = launchShellApp()
        openShellRoute(app, "grades")
        XCTAssertTrue(app.buttons["shell-grade-2"].waitForExistence(timeout: 4))
        app.buttons["shell-grade-2"].tap()
        assertShellTitle(app, "2 年级")
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS '二年级'")).firstMatch.exists)
        attachScreenshot("rd-01-legacy-grades")
        returnToShellHome(app)

        let picker = app.buttons["home-book-picker"]
        revealAndTap(app, picker)
        XCTAssertTrue(app.buttons["book-picker-grade-2"].waitForExistence(timeout: 4))
        app.buttons["book-picker-grade-2"].tap()
        attachScreenshot("rd-01-legacy-book-picker")
        let book = app.buttons["book-picker-book-g2up"]
        revealAndTap(app, book)
        XCTAssertTrue(app.buttons["home-book-picker"].waitForExistence(timeout: 5))
        picker.tap()
        XCTAssertTrue(app.buttons["book-picker-book-g2up"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["book-picker-book-g2up"].label.contains("二年级"))
        app.buttons["book-picker-close"].tap()
    }

    @MainActor
    func testDarkAppearancePreferenceRenders() {
        let app = launchShellApp(extraArgs: ["-cstf.appearance", "dark"])
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].waitForExistence(timeout: 15))
        attachScreenshot("dark-mode-home")
    }
}
