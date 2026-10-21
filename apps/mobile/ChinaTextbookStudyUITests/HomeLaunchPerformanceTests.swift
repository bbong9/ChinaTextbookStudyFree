import XCTest

/// 同一台 iPhone 16、同一内置 g1up（32 节课）、同一等待条件；旧/新首页各三次。
final class HomeLaunchPerformanceTests: XCTestCase {
    @MainActor
    func testLongBookLaunchThreeTimes() {
        XCUIDevice.shared.orientation = .landscapeLeft
        var samples: [Double] = []
        for index in 1...3 {
            let app = XCUIApplication()
            app.launchArguments = ["-uitest"]
            let start = ProcessInfo.processInfo.systemUptime
            app.launch()
            let current = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'lesson-row-' AND label CONTAINS '当前' ")).firstMatch
            XCTAssertTrue(current.waitForExistence(timeout: 30))
            XCTAssertTrue(current.isHittable)
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            samples.append(elapsed)
            print("RD09_LAUNCH sample=\(index) seconds=\(elapsed)")
            app.terminate()
        }
        print("RD09_LAUNCH median=\(samples.sorted()[1]) samples=\(samples)")
    }
}
