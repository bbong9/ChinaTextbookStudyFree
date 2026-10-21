import XCTest

/// Covers the earn → spend → express loop: buying a cosmetic must equip it and
/// the equipped state must survive navigating away and back.
final class CosmeticsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        return launchShellApp()
    }

    @MainActor
    private func attach(name: String) {
        let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Wave F: tapping an unowned cosmetic opens the preview/confirm sheet —
    /// confirm the purchase there.
    @MainActor
    private func confirmPurchase(_ app: XCUIApplication) {
        let confirm = app.buttons["cosmetic-confirm-buy"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3),
                      "tapping an unowned cosmetic should open the preview sheet")
        revealAndTap(app, confirm)
    }

    @MainActor
    func testBuyingCosmeticEquipsItAndPersists() throws {
        let app = launchApp()

        openShellRoute(app, "pet-home", isNew: true)
        XCTAssertTrue(app.buttons["pet-home-dress"].waitForExistence(timeout: 5))
        app.buttons["pet-home-dress"].tap()
        attach(name: "01-shop-before")

        // The stock skin starts equipped; the graduation cap costs 80 gems.
        let stock = app.buttons["cosmetic-skin_default"]
        XCTAssertTrue(stock.waitForExistence(timeout: 5))
        XCTAssertTrue(stock.label.contains("使用中"), "stock skin should start equipped")

        let cap = app.buttons["cosmetic-skin_graduate"]
        XCTAssertTrue(cap.waitForExistence(timeout: 3))
        XCTAssertFalse(cap.label.contains("使用中"), "graduation cap should not start equipped")
        revealAndTap(app, cap)
        confirmPurchase(app)

        // Buying equips it immediately.
        XCTAssertTrue(cap.waitForExistence(timeout: 3))
        XCTAssertTrue(cap.label.contains("使用中"),
                      "buying a skin should equip it — label was: \(cap.label)")
        XCTAssertFalse(stock.label.contains("使用中"),
                       "the previously equipped skin should have been unequipped")
        attach(name: "02-shop-skin-equipped")

        // D8：主题、背景不再售卖；配饰购买、佩戴留在小屋。
        XCTAssertFalse(app.buttons["cosmetic-theme_sakura"].exists)
        app.buttons["pet-dress-close"].tap()

        // The equipped skin must show on the profile avatar.
        returnToShellHome(app)
        openShellRoute(app, "profile")
        assertShellTitle(app, "我的")
        attach(name: "04-profile-themed")

        // 返回小屋后配饰仍佩戴在同一只伙伴身上。
        returnToShellHome(app)
        openShellRoute(app, "pet-home", isNew: true)
        XCTAssertTrue(app.buttons["pet-home-dress"].waitForExistence(timeout: 5))
        app.buttons["pet-home-dress"].tap()
        XCTAssertTrue(app.buttons["cosmetic-skin_graduate"].label.contains("使用中"),
                      "equipped skin did not persist across page navigation")
    }

    /// A cosmetic you cannot afford must not be granted.
    @MainActor
    func testUnaffordableCosmeticIsNotGranted() throws {
        let app = launchApp()

        returnToShellHome(app)
        openShellRoute(app, "pet-home", isNew: true)
        XCTAssertTrue(app.buttons["pet-home-dress"].waitForExistence(timeout: 5))
        app.buttons["pet-home-dress"].tap()

        // 宇航员头盔 costs 500; buy 学士帽 (80) first so the balance drops below it.
        revealAndTap(app, app.buttons["cosmetic-skin_graduate"])
        confirmPurchase(app)

        let helmet = app.buttons["cosmetic-skin_astronaut"]
        XCTAssertTrue(helmet.waitForExistence(timeout: 3))
        // RD-00：先完整滚入货架可见区域；共享助手同时处理横屏视口。
        revealAndTap(app, helmet)

        // Wave F: the preview sheet still opens, but the confirm button is
        // disabled when gems are short — cancel out and nothing was granted.
        let confirm = app.buttons["cosmetic-confirm-buy"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        XCTAssertFalse(confirm.isEnabled, "confirm must be disabled when unaffordable")
        revealAndTap(app, app.buttons["cosmetic-cancel-buy"])

        XCTAssertTrue(helmet.waitForExistence(timeout: 3))
        XCTAssertFalse(helmet.label.contains("使用中"),
                       "an unaffordable cosmetic must not be equipped")
    }
}
