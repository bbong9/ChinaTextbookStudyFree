import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class ClayGradientTests: XCTestCase {
    func testAllSVGGradientNamesAndSpecialGeometry() {
        let svg = ClayGradient.allCases.filter { $0.rawValue.hasPrefix("g-") || $0.rawValue.hasPrefix("p-") }
        XCTAssertEqual(svg.count, 43)
        if case .radial(let center, let radius) = ClayGradient.mush.geometry {
            XCTAssertEqual(center, UnitPoint(x: 0.4, y: 0.25)); XCTAssertEqual(radius, 0.85)
        } else { XCTFail("蘑菇必须是径向渐变") }
        if case .radial(let center, let radius) = ClayGradient.mt.geometry {
            XCTAssertEqual(center, UnitPoint(x: 0.4, y: 0.32)); XCTAssertEqual(radius, 0.78)
        } else { XCTFail("米团必须是径向渐变") }
        if case .linear(let end) = ClayGradient.trunk.geometry {
            XCTAssertEqual(end, UnitPoint(x: 1, y: 0))
        } else { XCTFail("树干必须是水平线性渐变") }
        XCTAssertEqual(ClayGradient.sky.stops.map(\.location), [0, 0.55, 1])
        XCTAssertEqual(ClayGradient.mt.stops.map(\.location), [0, 0.5, 0.85, 1])
        XCTAssertEqual(ClayGradient.glow.stops.last?.color, ClayColor.hex(0xC4F7FF).opacity(0))
    }
}
