import XCTest

final class LessonShellFlowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func enterFirstLesson(_ app: XCUIApplication, book: String = "g1up") {
        let node = app.buttons["lesson-row-\(book)-u1-kp1"].firstMatch
        XCTAssertTrue(node.waitForExistence(timeout: 15))
        revealAndTap(app, node)
        let start = app.buttons["lesson-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        skipLessonIntroIfPresent(app)
    }

    @MainActor private func checkAndContinue(_ app: XCUIApplication) {
        let check = app.buttons["检查答案"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        XCTAssertTrue(check.isHittable)
        check.tap()
        let next = app.buttons["继续"].firstMatch
        let wrong = app.buttons["知道了"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 2) || wrong.exists)
        (next.exists ? next : wrong).tap()
    }

    /// 使用与 LessonReplayTests 相同的 14 次固定答案，实际走完改版后的原关卡状态机。
    @MainActor func testFixedAnswersCompleteLessonAndAccessibleNumberPad() {
        let app = launchShellApp()
        enterFirstLesson(app)
        let selectors = ["tf-对", "tf-对", "lesson-choice-2", "lesson-choice-0", "lesson-choice-3",
                         "lesson-choice-2", "lesson-choice-2", "lesson-choice-2",
                         "lesson-fill_blank-key-3", "lesson-fill_blank-key-6", "lesson-fill_blank-key-7",
                         "lesson-fill_blank-key-8", "tf-错", "lesson-choice-1"]
        for (index, id) in selectors.enumerated() {
            let answer = app.buttons[id]
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "固定回放第 \(index + 1) 次作答")
            if index == 8 {
                let keys = (0...9).map(String.init) + ["decimal", "fraction", "delete"]
                for key in keys {
                    let button = app.buttons["lesson-fill_blank-key-\(key)"]
                    XCTAssertTrue(button.isHittable, key)
                    XCTAssertGreaterThanOrEqual(button.frame.width, 51.5, key)
                    XCTAssertGreaterThanOrEqual(button.frame.height, 51.5, key)
                    XCTAssertFalse(button.label.isEmpty)
                }
                // 数字、小数点、分数线与退格都经过真实无障碍按钮输入。
                for key in keys.dropLast() { app.buttons["lesson-fill_blank-key-\(key)"].tap() }
                for _ in 0..<12 { app.buttons["lesson-fill_blank-key-delete"].tap() }
                XCTAssertTrue(app.keyboards.count == 0, "数字填空不应弹系统键盘")
                attachScreenshot("rd-10-numeric-keypad")
            }
            answer.tap()
            checkAndContinue(app)
        }
        XCTAssertTrue(app.buttons["result-continue"].waitForExistence(timeout: 8), "固定答案必须走到原结算页")
    }

    @MainActor func testOutOfHeartsReviewCompletesAndLessonResumes() {
        let app = launchShellApp()
        enterFirstLesson(app)
        for id in ["tf-对", "tf-错", "lesson-choice-0", "lesson-choice-0", "lesson-choice-0"] {
            XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5))
            app.buttons[id].tap()
            checkAndContinue(app)
        }
        let review = app.buttons["hearts-review-earnback"]
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        attachScreenshot("rd-10-out-of-hearts")
        review.tap()
        for _ in 0..<5 {
            XCTAssertTrue(app.buttons["检查答案"].waitForExistence(timeout: 5))
            let prompt = app.scrollViews["lesson-prompt-scroll"].staticTexts.allElementsBoundByIndex.map(\.label).joined()
            if app.buttons["tf-对"].exists {
                app.buttons[prompt.contains("一排有5") ? "tf-错" : "tf-对"].tap()
            } else {
                let option = prompt.contains("6前面") ? 1 : prompt.contains("比8大") ? 3 : 2
                app.buttons["lesson-choice-\(option)"].tap()
            }
            app.buttons["检查答案"].tap()
            XCTAssertTrue(app.buttons["review-continue"].waitForExistence(timeout: 5))
            app.buttons["review-continue"].tap()
        }
        let back = app.buttons["review-summary-back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), "五道错题必须完整走到复习结算")
        revealAndTap(app, back, scrollView: app.scrollViews["review-summary-scroll"])
        enterFirstLesson(app)
        let resume = app.buttons["lesson-resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        attachScreenshot("rd-10-resume")
        resume.tap()
        XCTAssertTrue(app.buttons["lesson-choice-2"].waitForExistence(timeout: 5))
        app.buttons["lesson-choice-2"].tap()
        app.buttons["检查答案"].tap()
        XCTAssertTrue(app.buttons["继续"].waitForExistence(timeout: 5))
    }

    @MainActor func testTextKeyboardKeepsFieldAndCheckVisible() {
        let app = launchShellApp()
        let picker = app.buttons["home-book-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 15))
        picker.tap()
        revealAndTap(app, app.buttons["book-picker-grade-3"])
        let english = app.buttons["book-picker-book-english-g3up"]
        XCTAssertTrue(english.waitForExistence(timeout: 5))
        english.tap()
        enterFirstLesson(app, book: "english-g3up")
        for option in [1, 2, 1, 1] {
            let button = app.buttons["lesson-choice-\(option)"]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            button.tap()
            checkAndContinue(app)
        }
        let field = app.textFields["lesson-fill_blank_text-0"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        field.typeText("I'm Tom.")
        let keyboardTop = app.keyboards.firstMatch.frame.minY
        let check = app.buttons["检查答案"]
        XCTAssertTrue(field.isHittable)
        XCTAssertTrue(check.isHittable)
        XCTAssertLessThanOrEqual(field.frame.maxY, keyboardTop + 1)
        XCTAssertLessThanOrEqual(check.frame.maxY, keyboardTop + 1)
        XCTAssertTrue(app.staticTexts["lesson-prompt-summary"].exists)
        attachScreenshot("rd-10-text-keyboard")
        check.tap()
        XCTAssertTrue(app.buttons["继续"].waitForExistence(timeout: 5))
    }

    @MainActor func testJumpTestCompletesAllFifteenQuestions() {
        let app = launchShellApp()
        let jump = app.buttons["jump-here-u2"]
        XCTAssertTrue(app.buttons["lesson-row-g1up-u1-kp1"].waitForExistence(timeout: 15))
        let map = app.scrollViews.firstMatch
        XCTAssertTrue(map.exists)
        for _ in 0..<30 {
            if jump.exists && jump.isHittable { break }
            map.swipeUp()
        }
        revealAndTap(app, jump, scrollView: map)
        XCTAssertTrue(app.buttons["jump-start"].waitForExistence(timeout: 5))
        app.buttons["jump-start"].tap()
        for index in 0..<15 {
            XCTAssertTrue(app.buttons["检查答案"].waitForExistence(timeout: 5))
            if app.buttons["tf-对"].exists { app.buttons["tf-对"].tap() }
            else if app.buttons["lesson-choice-0"].exists { app.buttons["lesson-choice-0"].tap() }
            else if app.textFields["lesson-fill_blank_text-0"].exists {
                let field = app.textFields["lesson-fill_blank_text-0"]
                field.tap()
                field.typeText("0")
            } else {
                let zero = app.buttons.matching(NSPredicate(format: "identifier ENDSWITH %@", "-key-0")).firstMatch
                XCTAssertTrue(zero.waitForExistence(timeout: 5))
                zero.tap()
            }
            if index == 0 { attachScreenshot("rd-10-jump") }
            app.buttons["检查答案"].tap()
            XCTAssertTrue(app.buttons["jump-continue"].waitForExistence(timeout: 5))
            app.buttons["jump-continue"].tap()
        }
        XCTAssertTrue(app.buttons["jump-retry"].waitForExistence(timeout: 5) || app.buttons["jump-pass-continue"].exists,
                      "15 题必须完整到达跳级结果")
    }
}
