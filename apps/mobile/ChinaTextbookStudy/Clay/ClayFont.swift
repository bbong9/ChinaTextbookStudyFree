import SwiftUI
import UIKit
import CoreText

enum ClayFont {
    static let title = Font.custom("ZCOOLKuaiLe-Regular", fixedSize: 26)
    static let button = Font.custom("ZCOOLKuaiLe-Regular", fixedSize: 18)
    static let label = Font.custom("ZCOOLKuaiLe-Regular", fixedSize: 14)
    static let number = Font.custom("Nunito-Black", fixedSize: 16)
    static let pinyin = Font.custom("Nunito-Black", fixedSize: 26)
    static let pictureCharacterSize: CGFloat = 72
    static let picturePinyinSize: CGFloat = 24
    static let body = Font.custom("PingFangSC-Semibold", size: 16, relativeTo: .body)
    static let largeButton = happy(size: 20)
    static let step = happy(size: 27)
    static let ribbon = happy(size: 22)
    static let say = nunito(size: 18)
    static let level = nunito(size: 11)
    static let caption = Font.custom("PingFangSC-Semibold", size: 12, relativeTo: .caption)
    static let swatch = nunito(size: 9, weight: 800)
    static let storyRuby = nunito(size: 12, weight: 800)
    static func story(scale: CGFloat, english: Bool) -> Font {
        let size = max(30, 28 / max(scale, 0.001))
        return english ? nunito(size: size, weight: 800) : .custom("PingFangSC-Semibold", fixedSize: size)
    }

    static func happy(size: CGFloat) -> Font { .custom("ZCOOLKuaiLe-Regular", fixedSize: size) }
    static func nunito(size: CGFloat, weight: Int = 900) -> Font {
        .custom(weight == 800 ? "Nunito-ExtraBold" : "Nunito-Black", fixedSize: size)
    }

    /// 需要随下载刷新时使用 .clayKaiFont(size:)，所有字形选择统一经过这里。
    @MainActor static func kai(size: CGFloat) -> Font {
        .custom(ClayKaiFontStore.shared.fontName, fixedSize: size)
    }
}

protocol KaiFontDownloading {
    func download(completion: @escaping (String?) -> Void)
}

struct SystemKaiFontDownloader: KaiFontDownloading {
    static func installedFontName() -> String? {
        ["STKaitiSC-Regular", "KaitiSC-Regular"].first { UIFont(name: $0, size: 16) != nil }
    }

    func download(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let descriptor = CTFontDescriptorCreateWithAttributes([
                kCTFontFamilyNameAttribute: "Kaiti SC",
                kCTFontNameAttribute: "STKaitiSC-Regular"
            ] as CFDictionary)
            let started = CTFontDescriptorMatchFontDescriptorsWithProgressHandler([descriptor] as CFArray, nil) { state, _ in
                switch state {
                case .didFinish:
                    completion(Self.installedFontName())
                case .didFailWithError:
                    // 系统字体服务不可达/断网均安静回退，不暴露系统错误到界面。
                    completion(nil)
                default: break
                }
                return true
            }
            if !started { completion(nil) }
        }
    }
}

@MainActor
final class ClayKaiFontStore: ObservableObject {
    enum State: Equatable {
        case idle, downloading, available(String), unavailable
    }
    static let shared = ClayKaiFontStore()
    @Published private(set) var state: State = .idle
    private let downloader: KaiFontDownloading
    private let installedFont: () -> String?

    init(downloader: KaiFontDownloading = SystemKaiFontDownloader(),
         installedFont: @escaping () -> String? = SystemKaiFontDownloader.installedFontName) {
        self.downloader = downloader
        self.installedFont = installedFont
    }

    var fontName: String {
        if case .available(let name) = state { return name }
        return "PingFangSC-Semibold"
    }

    func startIfNeeded() {
        guard state == .idle else { return }
        if let name = installedFont() { state = .available(name); return }
        state = .downloading
        downloader.download { [weak self] name in
            Task { @MainActor in
                guard let self, self.state == .downloading else { return }
                self.state = name.map(State.available) ?? .unavailable
            }
        }
    }
}

private struct ClayKaiFontModifier: ViewModifier {
    @ObservedObject private var store = ClayKaiFontStore.shared
    let size: CGFloat

    func body(content: Content) -> some View {
        content.font(ClayFont.kai(size: size))
    }
}

extension View {
    /// 观察字体状态；下载完成后原地重绘，不重建路由或页面状态。
    func clayKaiFont(size: CGFloat) -> some View { modifier(ClayKaiFontModifier(size: size)) }
}
