import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class HomeMapLayoutTests: XCTestCase {
    private func node(_ id: Int, unit: Int = 1, status: LessonStatus = .locked, kind: PathMapNode.Kind = .lesson) -> PathMapNode {
        PathMapNode(id: "n\(id)", title: "课程\(id)", unitNumber: unit, unitTitle: "单元\(unit)",
                    status: status, stars: status == .completed ? 3 : 0, kind: kind)
    }

    func testLongUnitsKeepEveryNodeAndGlobalLessonNumbers() {
        let nodes = (0..<90).map { node($0, unit: $0 / 30 + 1, status: $0 == 65 ? .current : .locked) }
        let map = HomeMapLayout(nodes: nodes)
        XCTAssertEqual(map.units.count, 3)
        XCTAssertEqual(map.units.flatMap(\.entries).map(\.node), nodes)
        XCTAssertEqual(map.units.flatMap(\.entries).map(\.number), Array(1...90))
        XCTAssertEqual(map.current?.id, "n65")
        XCTAssertGreaterThan(map.units[0].width, 844)
        XCTAssertEqual(map.currentX!, map.units[2].origin + map.units[2].entries[5].point.x)
        for unit in map.units {
            XCTAssertTrue(unit.entries.allSatisfy { $0.point.x >= 44 && $0.point.x < unit.width - 44 })
            for pair in zip(unit.entries, unit.entries.dropFirst()) {
                XCTAssertEqual(pair.1.point.x - pair.0.point.x, 62)
            }
        }
    }

    func testChestAndExamNeverChangeLessonNumberOrStealMainlineLocation() {
        let map = HomeMapLayout(nodes: [node(1, status: .completed), node(2, status: .completed, kind: .chest),
                                       node(3, status: .current, kind: .exam), node(4, unit: 2, status: .current)])
        XCTAssertEqual(map.units.flatMap(\.entries).map(\.number), [1, 1, 1, 2])
        XCTAssertEqual(map.current?.id, "n4")
        XCTAssertFalse(map.units[0].locked)
        XCTAssertEqual(map.units[1].entries[0].label(character: "山"), "山")
        XCTAssertEqual(map.units[1].entries[0].label(), "2")
    }

    func testReducedMotionRemovesEveryParallaxCorrectionButKeepsPositioning() {
        for rate: CGFloat in [0.3, 0.6, 1, 1.1] {
            XCTAssertEqual(HomeMapLayout.parallaxCorrection(offset: 1200, rate: rate, reduceMotion: true), 0)
        }
        XCTAssertEqual(HomeMapLayout.parallaxCorrection(offset: 100, rate: 0.6, reduceMotion: false), 40, accuracy: 0.001)
        XCTAssertTrue(HomeMapLayout.currentVisible(x: 2000, offset: -1662.4, viewport: 844))
        XCTAssertFalse(HomeMapLayout.currentVisible(x: 2000, offset: 0, viewport: 844))
    }

    func testWidePhoneStageRetainsRoomForSevenDockTargets() {
        for viewport in [CGSize(width: 956, height: 440), CGSize(width: 1024, height: 768), CGSize(width: 667, height: 375)] {
            let stage = StageLayout(viewport: viewport, safeArea: EdgeInsets(top: 0, leading: 62, bottom: 21, trailing: 62))
            let available = stage.size.width - stage.safeArea.leading - stage.safeArea.trailing - 24 - 124 - 82 - 24
            XCTAssertGreaterThanOrEqual(available / 7, stage.minimumTapDimension)
        }
    }
}
