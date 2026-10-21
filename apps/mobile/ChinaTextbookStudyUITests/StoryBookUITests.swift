import XCTest

final class StoryBookUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func shelf(_ extra: [String] = []) -> XCUIApplication {
        let app = launchShellApp(extraArgs: ["-uitest-map-book", "chinese-g1up"] + extra)
        XCTAssertTrue(app.buttons["dock-story"].waitForExistence(timeout: 20))
        app.buttons["dock-story"].tap()
        app.buttons["睡前绘本"].tap()
        XCTAssertTrue(app.buttons["story-card-chinese-g1up-s1-v2"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func openFirst(_ app: XCUIApplication) {
        app.buttons["story-card-chinese-g1up-s1-v2"].tap()
        XCTAssertTrue(app.buttons["story-next"].waitForExistence(timeout: 5))
    }

    @MainActor private func checkAndAdvance(_ app: XCUIApplication) {
        app.buttons["story-quiz-check"].tap()
        let next = app.buttons["story-quiz-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
    }

    @MainActor func testReaderLayoutPinyinPagingAndExistingQuiz() {
        let app = shelf()
        attachScreenshot("rd19-shelf")
        openFirst(app)
        XCTAssertEqual(app.staticTexts["story-page-progress"].label, "门口的小伞 · 1/8")
        XCTAssertEqual(app.buttons["story-pinyin"].value as? String, "开")
        for id in ["story-back", "story-next", "story-pinyin", "story-narrate", "story-auto-page"] {
            let button = app.buttons[id]
            XCTAssertTrue(button.isHittable, id)
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5, id)
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5, id)
        }
        attachScreenshot("rd19-reader-first")
        app.buttons["story-pinyin"].tap()
        XCTAssertEqual(app.buttons["story-pinyin"].value as? String, "关")
        app.buttons["story-pinyin"].tap()
        app.buttons["story-next"].tap()
        XCTAssertEqual(app.staticTexts["story-page-progress"].label, "门口的小伞 · 2/8")
        attachScreenshot("rd19-reader-long")
        app.buttons["story-previous"].tap()
        XCTAssertEqual(app.staticTexts["story-page-progress"].label, "门口的小伞 · 1/8")
        for _ in 0..<8 { app.buttons["story-next"].tap() }
        XCTAssertTrue(app.buttons["lesson-choice-0"].waitForExistence(timeout: 5))
        attachScreenshot("rd19-quiz")
        app.buttons["lesson-choice-0"].tap()
        checkAndAdvance(app)
        let field = app.textFields["lesson-fill_blank_text-0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("0")
        checkAndAdvance(app)
        for _ in 0..<2 {
            app.buttons["lesson-choice-0"].tap()
            checkAndAdvance(app)
        }
        let xp = app.staticTexts["story-result-xp"]
        XCTAssertTrue(xp.waitForExistence(timeout: 5)); XCTAssertEqual(xp.label, "+5 XP")
        attachScreenshot("rd19-quiz-result-five-xp")
        app.buttons["story-result-done"].tap()
        XCTAssertTrue(app.buttons["story-card-chinese-g1up-s1-v2"].label.contains("已读"))
    }

    @MainActor func testMissingPinyinImageAndAudioFallBackWithoutCrashing() {
        let app = shelf(["-uitest-story-no-pinyin", "-uitest-story-no-image", "-uitest-story-no-audio"])
        openFirst(app)
        XCTAssertFalse(app.buttons["story-pinyin"].exists)
        attachScreenshot("rd19-fallback-no-pinyin")
        if app.buttons["story-mute"].value as? String == "关" { app.buttons["story-mute"].tap() }
        app.buttons["story-narrate"].tap()
        let highlight = NSPredicate { _, _ in
            (app.descendants(matching: .any)["story-sentence"].firstMatch.value as? String)?.contains("正在朗读") == true
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: highlight, object: nil)], timeout: 15), .completed)
        attachScreenshot("rd19-system-tts")
        app.buttons["story-back"].tap()
        XCTAssertTrue(app.buttons["story-book-picker"].waitForExistence(timeout: 5))
    }

    @MainActor func testShelfSwitchesChineseBooksAndEnglishReaderHidesPinyin() {
        let app = shelf()
        app.buttons["story-book-picker"].tap()
        let book = app.buttons["story-book-chinese-g1down"]
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        book.tap()
        XCTAssertTrue(app.buttons["story-card-chinese-g1down-s1-v2"].waitForExistence(timeout: 5))
        app.terminate()

        let english = launchShellApp(extraArgs: ["-uitest-map-book", "english-g3up"])
        XCTAssertTrue(english.buttons["dock-story"].waitForExistence(timeout: 20))
        english.buttons["dock-story"].tap()
        english.buttons["课外故事"].tap()
        let story = english.buttons["story-card-english-g3up-s1"]
        XCTAssertTrue(story.waitForExistence(timeout: 5)); story.tap()
        XCTAssertTrue(english.buttons["story-next"].waitForExistence(timeout: 5))
        XCTAssertFalse(english.buttons["story-pinyin"].exists)
        attachScreenshot("rd19-english")
        for attempt in 0..<2 {
            if attempt > 0 { story.tap() }
            for _ in 0..<8 { english.buttons["story-next"].tap() }
            XCTAssertTrue(english.buttons["tf-对"].waitForExistence(timeout: 5))
            english.buttons["tf-对"].tap()
            checkAndAdvance(english)
            english.buttons["lesson-choice-1"].tap()
            checkAndAdvance(english)
            let field = english.textFields["lesson-fill_blank_text-0"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.tap(); field.typeText("ruler")
            checkAndAdvance(english)
            let xp = english.staticTexts["story-result-xp"]
            XCTAssertTrue(xp.waitForExistence(timeout: 5))
            XCTAssertEqual(xp.label, attempt == 0 ? "+15 XP" : "已领过奖励")
            attachScreenshot(attempt == 0 ? "rd19-quiz-result-fifteen-xp" : "rd19-quiz-repeat-no-xp")
            english.buttons["story-result-done"].tap()
            XCTAssertTrue(story.waitForExistence(timeout: 5)); XCTAssertTrue(story.label.contains("已读"))
        }
    }

    @MainActor func testBedtimeReadsEntireBookAndStopsAtGoodnight() {
        let app = shelf(["-uitest-story-evidence"])
        app.buttons["story-bedtime-toggle"].tap()
        XCTAssertEqual(app.buttons["story-bedtime-toggle"].value as? String, "开")
        openFirst(app)
        if app.buttons["story-mute"].value as? String == "关" { app.buttons["story-mute"].tap() }
        XCTAssertFalse(app.buttons["story-auto-page"].exists)
        attachScreenshot("rd19-bedtime-start")
        XCTAssertTrue(app.staticTexts["story-goodnight"].waitForExistence(timeout: 150))
        XCTAssertFalse(app.buttons["lesson-choice-0"].exists)
        XCTAssertFalse(app.buttons["story-narrate"].exists)
        let staysAtGoodnight = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                        object: app.staticTexts["story-goodnight"])
        staysAtGoodnight.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [staysAtGoodnight], timeout: 2), .completed)
        attachScreenshot("rd19-goodnight")
        app.buttons["story-goodnight-back"].tap()
        let story = app.buttons["story-card-chinese-g1up-s1-v2"]
        XCTAssertTrue(story.waitForExistence(timeout: 5))
        XCTAssertTrue(story.label.contains("未读"), "睡前模式不能写完成记录或发放 XP")
    }
}
