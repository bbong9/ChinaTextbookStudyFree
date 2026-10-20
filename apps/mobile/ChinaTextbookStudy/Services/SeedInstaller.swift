import Foundation
import ZIPFoundation

/// On first launch, unzip the bundled `seed-data.zip` into the sandbox so the
/// app can demo the full lesson loop *with audio* without hitting GitHub Releases.
///
/// The zip is built by `scripts/build-seed-zip.sh` and contains:
///
///     data/index.json          → `cstf/data/index.json`（全部教材的书单）
///     data/books/<id>/...      → unzipped under `cstf/data/books/<id>/`
///     audio/<xx>/<sha>.m4a     → unzipped under `cstf/audio/<xx>/<sha>.m4a`
///
/// Both subtrees are siblings of `cstf/`, matching what AssetDownloader writes
/// for downloaded books.
///
/// 自 v1.4.0 起 seed 内置**全部 44 册**的课程数据（JSON 压缩后约 7MB）：GitHub
/// Release 上从来没有 iOS 分包（`ios-manifest.json` 404），国内网络也常拉不下来，
/// 以前除了内置的「数学一年级上册」其余书都无法打开。录音不内置，缺录音时
/// `AudioPlayer` 用系统语音朗读原文（见 `SpeechTextIndex`）。
enum SeedInstaller {
    static func installIfNeeded() {
        guard let zipURL = Bundle.main.url(forResource: "seed-data", withExtension: "zip") else {
            return
        }
        // Parent of `data/` and `audio/` — i.e. `Application Support/cstf/`.
        let cstfRoot = DataLoader.shared.sandboxDataRoot.deletingLastPathComponent()
        let fm = FileManager.default
        try? fm.createDirectory(at: cstfRoot, withIntermediateDirectories: true)

        // Skip if the seed has already been installed at the current bundled
        // version. The version stamp lives in `cstf/seed-version.txt` so seed
        // upgrades (e.g. swapping the bundled book or re-encoding audio) take
        // effect on the next launch without needing the user to wipe the app.
        let stampURL = cstfRoot.appendingPathComponent("seed-version.txt")
        let bundledVersion = Self.currentBundledVersion(zipURL: zipURL)
        if let stamped = try? String(contentsOf: stampURL, encoding: .utf8),
           stamped.trimmingCharacters(in: .whitespacesAndNewlines) == bundledVersion {
            return
        }
        // Wipe the audio dir before re-extracting — it's fully reproducible
        // from the zip and the downloader, so no risk of data loss.
        let audioDir = cstfRoot.appendingPathComponent("audio", isDirectory: true)
        try? fm.removeItem(at: audioDir)
        // Seed 现在覆盖全部教材，data/ 整体可由 seed 重建；先清掉旧数据，
        // 否则 ZIPFoundation 遇到已存在的文件会直接抛错、整包装不上。
        try? fm.removeItem(at: DataLoader.shared.sandboxDataRoot)

        do {
            try fm.unzipItem(at: zipURL, to: cstfRoot)
            try? bundledVersion.write(to: stampURL, atomically: true, encoding: .utf8)
        } catch {
            // Non-fatal: the user can still download books normally.
            print("[SeedInstaller] unzip failed: \(error)")
        }
    }

    /// Version derived from the bundled zip's mtime. Re-runs trigger a refresh
    /// whenever the developer rebuilds the seed via `scripts/build-seed-zip.sh`.
    private static func currentBundledVersion(zipURL: URL) -> String {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: zipURL.path),
           let date = attrs[.modificationDate] as? Date {
            return "\(Int(date.timeIntervalSince1970))"
        }
        return "unknown"
    }
}
