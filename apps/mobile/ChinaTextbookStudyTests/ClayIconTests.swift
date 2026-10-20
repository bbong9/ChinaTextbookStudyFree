import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class ClayIconTests: XCTestCase {
    func testChevronsKeepBothSegmentsFromSVG() {
        for icon in [ClayIcon.left, .right] {
            let path = ClayIconShape(icon: icon).path(in: CGRect(x: 0, y: 0, width: 26, height: 26))
            XCTAssertEqual(path.boundingRect.minY, 2.25, accuracy: 0.01)
            XCTAssertEqual(path.boundingRect.maxY, 23.75, accuracy: 0.01)
        }
        let back = ClayIconShape(icon: .back).path(in: CGRect(x: 0, y: 0, width: 32, height: 32))
        XCTAssertEqual(back.boundingRect.minY, 4.25, accuracy: 0.01)
    }

    func testPlayIsFilledTriangleAndSpeakerKeepsItsLeftFace() {
        let play = ClayIconShape(icon: .play).path(in: CGRect(x: 0, y: 0, width: 22, height: 22))
        XCTAssertTrue(play.contains(CGPoint(x: 10, y: 8)))
        XCTAssertTrue(play.contains(CGPoint(x: 10, y: 14)))
        XCTAssertTrue(play.contains(CGPoint(x: 10, y: 11)))
        let speaker = ClayIconShape(icon: .speaker).path(in: CGRect(x: 0, y: 0, width: 26, height: 26))
        XCTAssertTrue(speaker.contains(CGPoint(x: 4, y: 12)))
        XCTAssertTrue(speaker.contains(CGPoint(x: 10, y: 13)))
    }
}
