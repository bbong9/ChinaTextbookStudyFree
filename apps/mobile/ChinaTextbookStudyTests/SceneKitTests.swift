import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class SceneKitTests: XCTestCase {
    func testMotionMatchesCSSPeaksAndPeriods() {
        let cases: [(ClayMotion, Double, ClayMotion.Sample)] = [
            (.bob, 2.4, .init(y: -6)), (.drift, 9, .init(x: 18)), (.drift2, 12, .init(x: 18)),
            (.pulse, 1.8, .init(scaleX: 1.06, scaleY: 1.06, opacity: 1)),
            (.twinkle, 2, .init(opacity: 1)), (.flutter, 0.5, .init(scaleX: 0.4))
        ]
        for (motion, duration, peak) in cases {
            XCTAssertEqual(motion.duration, duration)
            assertSample(motion.sample(at: duration / 2), peak)
            assertSample(motion.sample(at: duration), motion.sample(at: 0))
            assertSample(motion.sample(at: duration * 0.25), motion.sample(at: duration * 0.75))
        }
    }

    func testReducedMotionKeepsUntransformedArtworkAcrossEveryLoop() {
        for motion in ClayMotion.allCases {
            for elapsed in [0.0, 0.25, 1, 9, 28.6, 120] {
                assertSample(motion.sample(at: elapsed, paused: true), .init())
            }
        }
    }

    func testRoadRetainsControlPointsFromScrMap() {
        // smoothPath([[20,300],[112,286],[172,280]]) 的原 JS 输出，独立于 Swift 算法。
        let path = PathRoad.path(points: [CGPoint(x: 20, y: 300), CGPoint(x: 112, y: 286), CGPoint(x: 172, y: 280)])
        var elements: [Path.Element] = []; path.forEach { elements.append($0) }
        XCTAssertEqual(elements.count, 3)
        guard elements.count == 3,
              case let .curve(end1, c11, c12) = elements[1],
              case let .curve(end2, c21, c22) = elements[2] else {
            return XCTFail("路线应包含 M + 两段 C")
        }
        assertPoint(end1, CGPoint(x: 112, y: 286))
        assertPoint(c11, CGPoint(x: 35.3, y: 297.7))
        assertPoint(c12, CGPoint(x: 86.7, y: 289.3))
        assertPoint(end2, CGPoint(x: 172, y: 280))
        assertPoint(c21, CGPoint(x: 137.3, y: 282.7))
        assertPoint(c22, CGPoint(x: 162, y: 281))
        XCTAssertTrue(PathRoad.path(points: []).isEmpty)
    }

    func testStarCoordinatesRetainSVGRounding() {
        // S.starPath(0,0,6.5,...) 的前两个顶点，防止星星被替换成系统图标或不同内半径。
        var elements: [Path.Element] = []
        StarView.path(radius: 6.5).forEach { elements.append($0) }
        XCTAssertEqual(elements.count, 11)
        guard elements.count == 11,
              case let .move(first) = elements[0], case let .line(second) = elements[1] else {
            return XCTFail("星星应包含十个顶点和闭合命令")
        }
        assertPoint(first, CGPoint(x: 0, y: -6.5))
        assertPoint(second, CGPoint(x: 1.8, y: -2.5))
    }

    private func assertPoint(_ actual: CGPoint, _ expected: CGPoint,
                             file: StaticString = #filePath, line: UInt = #line) {
        // SwiftUI Path 内部可能采用 Float；验证 SVG 的 0.1pt 精度，容忍存储舍入。
        XCTAssertEqual(actual.x, expected.x, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(actual.y, expected.y, accuracy: 0.0001, file: file, line: line)
    }

    private func assertSample(_ actual: ClayMotion.Sample, _ expected: ClayMotion.Sample,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.x, expected.x, accuracy: 0.00001, file: file, line: line)
        XCTAssertEqual(actual.y, expected.y, accuracy: 0.00001, file: file, line: line)
        XCTAssertEqual(actual.scaleX, expected.scaleX, accuracy: 0.00001, file: file, line: line)
        XCTAssertEqual(actual.scaleY, expected.scaleY, accuracy: 0.00001, file: file, line: line)
        XCTAssertEqual(actual.opacity, expected.opacity, accuracy: 0.00001, file: file, line: line)
    }
}
