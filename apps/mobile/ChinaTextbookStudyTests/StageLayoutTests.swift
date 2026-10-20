import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class StageLayoutTests: XCTestCase {
    func testFourLandscapeViewportsAndSafeAreaAnchors() {
        let samples: [(CGSize, EdgeInsets, CGFloat, CGSize, CGPoint, CGPoint)] = [
            (CGSize(width: 667, height: 375), EdgeInsets(), 0.7902843602,
             CGSize(width: 844, height: 474.5127436282), CGPoint(x: 43.8380809595, y: 43.8380809595),
             CGPoint(x: 800.1619190405, y: 430.6746626687)),
            (CGSize(width: 852, height: 393), EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 59), 1.0076923077,
             CGSize(width: 845.4961832061, height: 390), CGPoint(x: 98.5496183206, y: 40),
             CGPoint(x: 746.9465648855, y: 329.1603053435)),
            (CGSize(width: 956, height: 440), EdgeInsets(top: 0, leading: 62, bottom: 21, trailing: 62), 1.1282051282,
             CGSize(width: 847.3636363636, height: 390), CGPoint(x: 94.9545454545, y: 40),
             CGPoint(x: 752.4090909091, y: 331.3863636364)),
            (CGSize(width: 1180, height: 820), EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0), 1.3981042654,
             CGSize(width: 844, height: 586.5084745763), CGPoint(x: 40, y: 57.1661016949),
             CGPoint(x: 804, y: 532.2033898305))
        ]
        for (viewport, safe, scale, size, leading, trailing) in samples {
            let ctx = StageLayout(viewport: viewport, safeArea: safe)
            XCTAssertEqual(ctx.scale, scale, accuracy: 0.000001)
            XCTAssertEqual(ctx.size.width, size.width, accuracy: 0.000001)
            XCTAssertEqual(ctx.size.height, size.height, accuracy: 0.000001)
            XCTAssertEqual(ctx.safeArea.leading * ctx.scale, safe.leading, accuracy: 0.000001)
            XCTAssertEqual(ctx.safeArea.trailing * ctx.scale, safe.trailing, accuracy: 0.000001)
            XCTAssertEqual(ctx.safeArea.top * ctx.scale, safe.top, accuracy: 0.000001)
            XCTAssertEqual(ctx.safeArea.bottom * ctx.scale, safe.bottom, accuracy: 0.000001)
            let side = max(48, ctx.minimumTapDimension)
            let itemSize = CGSize(width: side, height: side)
            let expectations: [(StageAnchor, CGPoint)] = [
                (.topLeading, leading), (.topTrailing, CGPoint(x: trailing.x, y: leading.y)),
                (.bottomLeading, CGPoint(x: leading.x, y: trailing.y)), (.bottomTrailing, trailing)
            ]
            for (anchor, expected) in expectations {
                let result = ctx.anchor(anchor, itemSize: itemSize)
                XCTAssertEqual(result.x, expected.x, accuracy: 0.000001)
                XCTAssertEqual(result.y, expected.y, accuracy: 0.000001)
            }
            XCTAssertGreaterThanOrEqual(ctx.minimumTapDimension * ctx.scale, 44 - 0.000001)
        }
    }

    func testSceneBottomAndSideExtension() {
        let tall = StageLayout(viewport: CGSize(width: 667, height: 375), safeArea: EdgeInsets())
        XCTAssertEqual(tall.place(x: 0, y: 0).y, 84.5127436282, accuracy: 0.000001)
        XCTAssertEqual(tall.place(x: 844, y: 390).y, tall.size.height, accuracy: 0.000001)
        let wide = StageLayout(viewport: CGSize(width: 1100, height: 390), safeArea: EdgeInsets())
        XCTAssertEqual(wide.place(x: 0, y: 0), CGPoint(x: 128, y: 0))
        XCTAssertEqual(wide.place(x: 844, y: 390), CGPoint(x: 972, y: 390))
    }

    func testCenterAnchorRespectsAsymmetricSafeArea() {
        let ctx = StageLayout(viewport: CGSize(width: 844, height: 390),
                              safeArea: EdgeInsets(top: 10, leading: 60, bottom: 20, trailing: 0))
        XCTAssertEqual(ctx.anchor(.center, itemSize: .zero), CGPoint(x: 452, y: 190))
    }
}
