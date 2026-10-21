import XCTest
import UIKit

/// RD-01：三个验收设备共用同一套外壳检查。
final class ShellUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchAndRotationStayLandscape() {
        let app = launchShellApp()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 15))
        let orientations: [UIDeviceOrientation] = [.landscapeLeft, .portrait, .portraitUpsideDown, .landscapeRight]
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            let landscape = NSPredicate { _, _ in
                app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
            }
            expectation(for: landscape, evaluatedWith: app)
            waitForExpectations(timeout: 5)
            XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tab-'")).firstMatch.exists)
            XCTAssertFalse(app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'sidebar-'")).firstMatch.exists)
            XCTAssertFalse(app.navigationBars.firstMatch.exists)
            XCTAssertEqual(app.tabBars.count, 0)
        }
        attachScreenshot("rd-01-home-landscape")
    }

    @MainActor
    func testMapEntrancesOpenAndReturn() {
        let app = launchShellApp()
        for id in ["pet-family", "pet-home", "pet-shop", "quests", "parent-center",
                   "math-train", "english-balloons", "animals", "idiom-picker", "reading-room"] {
            openShellRoute(app, id, isNew: true)
            switch id {
            case "pet-family", "pet-home", "pet-shop":
                XCTAssertTrue(app.descendants(matching: .any)["\(id)-screen"].firstMatch.waitForExistence(timeout: 5))
            case "quests": XCTAssertTrue(app.scrollViews["quests-screen"].waitForExistence(timeout: 5))
            case "parent-center": assertShellTitle(app, "设置")
            default: XCTAssertTrue(app.staticTexts["placeholder-\(id)"].waitForExistence(timeout: 5))
            }
            XCTAssertTrue(app.buttons["shell-back"].isHittable)
            XCTAssertFalse(app.navigationBars.firstMatch.exists)
            returnToShellHome(app)
        }
    }

    #if DEBUG
    @MainActor
    func testDebugGalleryOpensAndReturnsWithinShell() {
        let app = launchShellApp()
        let entry = app.buttons["hud-avatar"]
        XCTAssertTrue(entry.waitForExistence(timeout: 15))
        entry.press(forDuration: 1)
        let back = app.buttons["stage-top-leading"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars.firstMatch.exists)
        attachScreenshot("rd-01-clay-gallery")
        back.tap()

        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
        XCTAssertTrue(entry.isHittable)
        openShellRoute(app, "pet-family", isNew: true)
        XCTAssertTrue(app.scrollViews["pet-family-scroll"].waitForExistence(timeout: 5))
        returnToShellHome(app)
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
    }
    #endif

    @MainActor
    func testOnboardingAutomaticallyStartsFirstLessonOnce() {
        let app = launchShellApp(extraArgs: ["-uitest-onboarding"])
        XCTAssertTrue(app.buttons["onboarding-start"].waitForExistence(timeout: 15))
        revealAndTap(app, app.buttons["onboarding-start"])
        revealAndTap(app, app.buttons["onboarding-book-g1up"])
        revealAndTap(app, app.buttons["onboarding-next"])
        revealAndTap(app, app.buttons["onboarding-goal-50"])
        revealAndTap(app, app.buttons["onboarding-notify-later"])
        let toast = app.descendants(matching: .any)["first-lesson-toast"].firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 2))
        attachScreenshot("rd-01-onboarding-first-lesson-toast")
        XCTAssertTrue(app.buttons["intro-next"].waitForExistence(timeout: 8) || app.buttons["intro-start"].exists)
        skipLessonIntroIfPresent(app)
        XCTAssertTrue(app.buttons["检查答案"].waitForExistence(timeout: 8))
        app.buttons["关闭"].firstMatch.tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
        openShellRoute(app, "quests", isNew: true)
        app.buttons["shell-back"].tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["检查答案"].exists)
    }
}
