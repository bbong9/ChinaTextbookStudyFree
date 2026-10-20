import XCTest
import Combine
import UIKit
@testable import ChinaTextbookStudy

@MainActor
final class ClayFontTests: XCTestCase {
    final class Download: KaiFontDownloading {
        var count = 0
        var completion: ((String?) -> Void)?
        func download(completion: @escaping (String?) -> Void) { count += 1; self.completion = completion }
    }

    func testDownloadCompletionPublishesReplacementWithoutRestart() async {
        let downloader = Download()
        let store = ClayKaiFontStore(downloader: downloader, installedFont: { nil })
        XCTAssertEqual(store.fontName, "PingFangSC-Semibold")
        store.startIfNeeded()
        XCTAssertEqual(store.state, .downloading)
        store.startIfNeeded()
        XCTAssertEqual(downloader.count, 1)
        let changed = expectation(description: "下载完成触发刷新")
        let observation = store.$state.dropFirst().sink { state in
            if state == .available("STKaitiSC-Regular") { changed.fulfill() }
        }
        downloader.completion?("STKaitiSC-Regular")
        await fulfillment(of: [changed], timeout: 2)
        XCTAssertEqual(store.fontName, "STKaitiSC-Regular")
        withExtendedLifetime(observation) {}
    }

    func testOfflineFailureKeepsFallbackAndDoesNotRepeatDownload() async {
        let downloader = Download()
        let store = ClayKaiFontStore(downloader: downloader, installedFont: { nil })
        store.startIfNeeded()
        let finished = expectation(description: "离线安静回退")
        let observation = store.$state.dropFirst().sink { if $0 == .unavailable { finished.fulfill() } }
        downloader.completion?(nil)
        await fulfillment(of: [finished], timeout: 2)
        XCTAssertEqual(store.fontName, "PingFangSC-Semibold")
        store.startIfNeeded()
        XCTAssertEqual(downloader.count, 1)
        withExtendedLifetime(observation) {}
    }

    func testAlreadyInstalledFontDoesNotStartDownload() {
        let downloader = Download()
        let store = ClayKaiFontStore(downloader: downloader, installedFont: { "STKaitiSC-Regular" })
        store.startIfNeeded()
        XCTAssertEqual(store.state, .available("STKaitiSC-Regular"))
        XCTAssertEqual(downloader.count, 0)
    }

    func testBundledFontsAreRegisteredLicensedAndUnderEightMegabytes() throws {
        let bundle = Bundle.main
        let registered = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "UIAppFonts") as? [String])
        XCTAssertEqual(Set(registered), Set(["Fonts/ZCOOLKuaiLe-Regular.ttf", "Fonts/Nunito-ExtraBold.ttf", "Fonts/Nunito-Black.ttf"]))
        var bytes = 0
        for path in registered {
            let url = try XCTUnwrap(bundle.resourceURL?.appendingPathComponent(path))
            bytes += try Data(contentsOf: url).count
            XCTAssertNotNil(UIFont(name: url.deletingPathExtension().lastPathComponent, size: 18))
        }
        XCTAssertLessThanOrEqual(bytes, 8 * 1024 * 1024)
        for name in ["OFL-Nunito", "OFL-ZCOOL-KuaiLe"] {
            let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "txt", subdirectory: "Fonts"))
            XCTAssertTrue(try String(contentsOf: url).contains("SIL OPEN FONT LICENSE"))
        }
    }
}
