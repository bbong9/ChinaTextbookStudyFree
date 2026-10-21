import XCTest
import UIKit

final class PictureWordsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launch() -> XCUIApplication {
        let app = launchShellApp()
        openShellRoute(app, "animals", isNew: true)
        XCTAssertTrue(app.buttons["picture-item-sheep"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testCaptureCategoriesThreeHabitatsAndAlbum() {
        let app = launch()
        attachScreenshot("rd16-farm-overview")
        app.buttons["picture-item-sheep"].tap()
        XCTAssertEqual(app.staticTexts["picture-card-character"].label, "羊")
        XCTAssertEqual(app.staticTexts["picture-card-pinyin"].label, "yáng")
        XCTAssertGreaterThanOrEqual(app.staticTexts["picture-card-character"].frame.height, 72)
        XCTAssertGreaterThanOrEqual(app.staticTexts["picture-card-pinyin"].frame.height, 24)
        XCTAssertEqual(app.staticTexts["picture-card-english"].label, "sheep")
        attachScreenshot("rd16-farm")
        XCTAssertEqual(app.buttons["picture-album"].value as? String, "1 / 50")
        app.buttons["picture-item-sheep"].tap()
        XCTAssertEqual(app.buttons["picture-album"].value as? String, "1 / 50")
        for habitat in ["forest", "water"] {
            app.buttons["picture-scene-button-\(habitat)"].tap()
            attachScreenshot("rd16-\(habitat)")
        }
        for category in ["fruit", "transport", "body"] {
            app.buttons["picture-category-\(category)"].tap()
            attachScreenshot("rd16-\(category)")
        }
        app.buttons["picture-item-eye"].tap()
        XCTAssertEqual(app.staticTexts["picture-card-character"].label, "眼睛")
        attachScreenshot("rd16-body-card")
        revealAndTap(app, app.buttons["picture-speak-english"])
        app.buttons["picture-album"].tap()
        XCTAssertTrue(app.scrollViews["picture-album-grid"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["picture-album-sheep"].label, "羊，已发现")
        XCTAssertFalse(app.buttons["picture-album-duck"].isEnabled)
        attachScreenshot("rd16-album")
        app.buttons["picture-album-sheep"].tap()
        XCTAssertTrue(app.buttons["picture-item-sheep"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["picture-card-character"].label, "羊")
        app.buttons["shell-back"].tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 3))
    }

    /// 逐一检查真实无障碍树中的中文名字、物理点击尺寸和可达性。
    @MainActor func testEveryWordHasNamedAccessibleSixtyFourPointTargetAndCanBeCollected() {
        let app = launch()
        let groups: [(String, String?, [(String, String)])] = [
            ("animals", "farm", [("duck", "鸭"), ("pig", "猪"), ("sheep", "羊"), ("cow", "牛"),
                                 ("horse", "马"), ("chicken", "鸡"), ("dog", "狗"), ("cat", "猫")]),
            ("animals", "forest", [("fox", "狐狸"), ("owl", "猫头鹰"), ("rabbit", "兔"), ("deer", "鹿"),
                                   ("tiger", "老虎"), ("monkey", "猴"), ("squirrel", "松鼠"), ("panda", "熊猫")]),
            ("animals", "water", [("penguin", "企鹅"), ("fish", "鱼"), ("frog", "青蛙"), ("turtle", "龟")]),
            ("fruit", nil, [("apple", "苹果"), ("banana", "香蕉"), ("watermelon", "西瓜"), ("grape", "葡萄"),
                            ("orange", "橙子"), ("pear", "梨"), ("peach", "桃子"), ("strawberry", "草莓"),
                            ("cherry", "樱桃"), ("lemon", "柠檬")]),
            ("transport", nil, [("car", "汽车"), ("train", "火车"), ("plane", "飞机"), ("ship", "轮船"),
                                ("bus", "巴士"), ("truck", "卡车"), ("bicycle", "单车"), ("subway", "地铁"),
                                ("motorcycle", "摩托"), ("tram", "电车")]),
            ("body", nil, [("eye", "眼睛"), ("ear", "耳朵"), ("nose", "鼻子"), ("mouth", "嘴"), ("hand", "手"),
                           ("foot", "脚"), ("tooth", "牙齿"), ("tongue", "舌头"), ("arm", "手臂"), ("leg", "腿")]),
        ]
        var count = 0
        for (category, scene, words) in groups {
            app.buttons["picture-category-\(category)"].tap()
            if let scene { app.buttons["picture-scene-button-\(scene)"].tap() }
            for (id, name) in words {
                let button = app.buttons["picture-item-\(id)"]
                XCTAssertEqual(button.label, name)
                XCTAssertGreaterThanOrEqual(button.frame.width, 63.5, id)
                XCTAssertGreaterThanOrEqual(button.frame.height, 63.5, id)
                XCTAssertTrue(button.isHittable, id)
                button.tap()
                XCTAssertEqual(app.staticTexts["picture-card-character"].label, name)
                if ["owl", "strawberry"].contains(id) {
                    attachScreenshot("rd16-\(id)-card")
                }
                count += 1
                XCTAssertEqual(app.buttons["picture-album"].value as? String, "\(count) / 50")
            }
        }
        XCTAssertEqual(count, 50)
        XCTAssertFalse(app.staticTexts["答错"].exists)
        XCTAssertFalse(app.staticTexts["错误"].exists)
        attachScreenshot("rd16-all-fifty-seen")
    }

    @MainActor func testSwipeSwitchesHabitatsAndBackReturnsToHome() {
        let app = launch()
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.56))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.56))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.buttons["picture-item-fox"].waitForExistence(timeout: 3))
        app.buttons["picture-scene-button-water"].tap()
        app.buttons["picture-item-penguin"].tap()
        XCTAssertEqual(app.staticTexts["picture-card-character"].label, "企鹅")
        app.buttons["shell-back"].tap()
        XCTAssertTrue(app.buttons["hud-avatar"].waitForExistence(timeout: 3))
    }

    /// 首次以测试种子完成真实引导并落盘偏好；重启时去掉 -uitest，走正常生产读档。
    @MainActor func testAlbumSurvivesActualProcessRelaunch() {
        let app = launchShellApp(extraArgs: ["-uitest-onboarding"])
        XCTAssertTrue(app.buttons["onboarding-start"].waitForExistence(timeout: 15))
        revealAndTap(app, app.buttons["onboarding-start"])
        revealAndTap(app, app.buttons["onboarding-book-g1up"])
        revealAndTap(app, app.buttons["onboarding-next"])
        revealAndTap(app, app.buttons["onboarding-goal-50"])
        revealAndTap(app, app.buttons["onboarding-notify-later"])
        XCTAssertTrue(app.buttons["intro-next"].waitForExistence(timeout: 8) || app.buttons["intro-start"].exists)
        skipLessonIntroIfPresent(app)
        app.buttons["关闭"].firstMatch.tap()
        openShellRoute(app, "animals", isNew: true)
        app.buttons["picture-item-sheep"].tap()
        app.buttons["picture-category-fruit"].tap()
        app.buttons["picture-item-apple"].tap()
        XCTAssertEqual(app.buttons["picture-album"].value as? String, "2 / 50")
        app.terminate()
        app.launchArguments = []
        app.launch()
        openShellRoute(app, "animals", isNew: true)
        XCTAssertEqual(app.buttons["picture-album"].value as? String, "2 / 50")
        app.buttons["picture-album"].tap()
        XCTAssertTrue(app.buttons["picture-album-sheep"].isEnabled)
        for _ in 0..<6 {
            if app.buttons["picture-album-apple"].exists { break }
            app.scrollViews["picture-album-grid"].swipeUp()
        }
        XCTAssertTrue(app.buttons["picture-album-apple"].isEnabled)
        attachScreenshot("rd16-relaunched-album")
    }
}
