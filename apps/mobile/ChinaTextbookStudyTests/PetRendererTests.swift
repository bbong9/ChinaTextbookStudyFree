import XCTest
import SwiftUI
@testable import ChinaTextbookStudy

final class PetRendererTests: XCTestCase {
    func testKindsUseTheCrossPlatformCatalogIDsAndNames() {
        XCTAssertEqual(Set(PetKind.allCases.map(\.rawValue)), Set(Pets.pets.map(\.id)))
        XCTAssertEqual(PetKind.allCases.count, 10)
        for kind in PetKind.allCases {
            XCTAssertEqual(kind.name, Pets.petById(kind.rawValue)?.name)
            XCTAssertEqual(kind.rawValue, "pet_" + kind.artKey)
        }
    }

    func testAllLegacyAccessoryIDsRemainRenderableWithoutChangingTheCatalog() {
        XCTAssertEqual(Set(PetAccessory.allCases.map(\.rawValue)), Set(Cosmetics.mascotSkins.map(\.id)))
        XCTAssertEqual(PetAccessory.decorations.count, 11)
        XCTAssertFalse(PetAccessory.decorations.contains(.noAccessory))
        XCTAssertNil(PetAccessory(rawValue: "unknown_skin"))
        XCTAssertEqual(PetEnvironment(), PetEnvironment(kind: .mituan, accessory: .noAccessory))
    }

    func testEverySpeciesHasOrderedAnchorsInsideTheArtboard() {
        for kind in PetKind.allCases {
            let a = kind.anchors
            XCTAssertGreaterThan(a.eyes.y, a.head.y, kind.name)
            XCTAssertGreaterThan(a.neck.y, a.eyes.y, kind.name)
            for point in [a.head, a.eyes, a.neck] {
                XCTAssertTrue((0...120).contains(point.x), kind.name)
                XCTAssertTrue((0...130).contains(point.y), kind.name)
            }
            XCTAssertTrue((0.5...1).contains(a.scale), kind.name)
        }
        // 鸭子的头偏左，不能误用圆身宠物的中心锚点。
        XCTAssertLessThan(PetKind.duck.anchors.head.x, 60)
    }

    @MainActor func testExportExpressionVariantsAndAccessoryEvidence() throws {
        try attach(PetMoodGrid(), name: "rd04-moods-10x8")
        try attach(PetVariantStrip(), name: "rd04-bloom-crack-0-3")
        try attach(PetAccessoryGrid(), name: "rd04-accessories-3x11")
        for kind in PetAccessoryGrid.kinds {
            for accessory in PetAccessory.decorations {
                let sample = VStack(spacing: 8) {
                    PetView(kind: kind, size: 180, accessory: accessory)
                    Text("\(kind.name) · \(accessory.name)").font(ClayFont.body)
                }
                .padding(24)
                .foregroundStyle(ClayColor.ink)
                .background(ClayGradient.buttonCream.view)
                .environment(\.petAnimationsPaused, true)
                try attach(sample, name: "rd04-\(kind.artKey)-\(accessory.rawValue)")
            }
        }
    }

    @MainActor func testCracksClampAtBothEndsAndBloomChangesTheArtwork() throws {
        func pixels(_ kind: PetKind, crack: Int = 0, bloom: Bool = false) throws -> Data {
            let image = try render(PetView(kind: kind, size: 180, accessory: PetAccessory.noAccessory, bloom: bloom, crack: crack)
                .environment(\.petAnimationsPaused, true))
            return try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
        }
        XCTAssertEqual(try pixels(.egg, crack: -4), try pixels(.egg, crack: 0))
        XCTAssertEqual(try pixels(.egg, crack: 30), try pixels(.egg, crack: 3))
        for crack in 0..<3 {
            XCTAssertNotEqual(try pixels(.egg, crack: crack), try pixels(.egg, crack: crack + 1))
        }
        XCTAssertNotEqual(try pixels(.mituan), try pixels(.mituan, bloom: true))
    }

    @MainActor func testEnvironmentSelectsTheActivePetAndAccessory() throws {
        let injected = PetEnvironment(kind: .fox, accessory: .graduate)
        let inherited = try render(PetView(size: 180)
            .environment(\.petEnvironment, injected).environment(\.petAnimationsPaused, true))
        let explicit = try render(PetView(kind: .fox, size: 180, accessory: .graduate)
            .environment(\.petAnimationsPaused, true))
        XCTAssertEqual(inherited.pngData(), explicit.pngData())
        let bare = try render(PetView(kind: .fox, size: 180, accessory: .noAccessory)
            .environment(\.petEnvironment, injected).environment(\.petAnimationsPaused, true))
        XCTAssertNotEqual(bare.pngData(), inherited.pngData())
        // ImageRenderer 有独立环境，分享导出入口必须显式传递当前伙伴。
        let data = ShareCard.BadgeData(icon: "star.fill", tint: ClayColor.orange,
            headline: "合成验收", title: "宠物分享卡", subtitle: "环境传递")
        let fox = try XCTUnwrap(ShareCard.renderBadge(data, pet: injected))
        let mituan = try XCTUnwrap(ShareCard.renderBadge(data, pet: PetEnvironment()))
        XCTAssertNotEqual(fox.pngData(), mituan.pngData())
    }

    @MainActor private func render<V: View>(_ view: V) throws -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return try XCTUnwrap(renderer.uiImage)
    }

    @MainActor private func attach<V: View>(_ view: V, name: String) throws {
        let image = try render(view)
        XCTAssertGreaterThan(image.size.width, 100)
        XCTAssertGreaterThan(image.size.height, 100)
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
