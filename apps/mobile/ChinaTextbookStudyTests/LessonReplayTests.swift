import XCTest
import ZIPFoundation
@testable import ChinaTextbookStudy

/// RD-10 改展示层前录下的固定回放。题目来自实际打包 seed，判分与结算调用生产代码。
@MainActor
final class LessonReplayTests: XCTestCase {
    func testFixedSeedAnswersKeepLessonOutcomeAndHearts() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("rd10-replay-\(UUID().uuidString)")
        let saved = ["progress.json", "prefs.json"].map { ($0, try? Data(contentsOf: PersistenceService.url(for: $0))) }
        defer {
            try? FileManager.default.removeItem(at: directory)
            for (name, data) in saved {
                let url = PersistenceService.url(for: name)
                if let data { try? data.write(to: url) } else { try? FileManager.default.removeItem(at: url) }
            }
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: XCTUnwrap(Bundle.main.url(forResource: "seed-data", withExtension: "zip")), to: directory)
        let lesson = try DataLoader(dataRoot: directory.appendingPathComponent("data"))
            .loadLesson(bookId: "g1up", lessonId: "g1up-u1-kp1")
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-21T04:00:00Z"))
        let store = ProgressStore(now: now)
        store.resetProgress()
        let heartsBefore = store.hearts

        // 前 12 次各答一题；第 1、4 题故意答错，最后依序重练这两题。
        let ids = [1, 3, 6, 8, 9, 11, 14, 15, 19, 20, 22, 23, 1, 8]
        let answers = ["对", "对", "C", "A", "D", "C", "C", "C", "3", "6", "7", "8", "错", "B"]
        let expectedGrades = [false, true, true, false, true, true, true, true, true, true, true, true, true, true]
        let byId = Dictionary(uniqueKeysWithValues: lesson.questions.map { ($0.id, $0) })
        var solved: Set<Int> = []
        var missed: Set<Int> = []
        for (offset, id) in ids.enumerated() {
            let question = try XCTUnwrap(byId[id])
            let ok = Grade.gradeAnswer(question: question, userAnswer: answers[offset])
            XCTAssertEqual(ok, expectedGrades[offset], "固定答案第 \(offset + 1) 次判分改变")
            if ok { solved.insert(id) } else {
                missed.insert(id)
                store.loseHeart(now: now)
            }
        }
        XCTAssertEqual(lesson.questions.map(\.id), Array(ids.prefix(12)), "seed 题目顺序改变，需重新审阅基线")
        XCTAssertEqual(solved.count, 12)
        let correctCount = lesson.questions.count - missed.count
        let outcome = store.completeLesson(lessonId: lesson.id, correctCount: correctCount, questionCount: lesson.questions.count, now: now)
        XCTAssertEqual(correctCount, 10)
        XCTAssertEqual(outcome.xpGained, 100)
        XCTAssertEqual(outcome.stars, 2)
        XCTAssertEqual(heartsBefore, 5)
        XCTAssertEqual(store.hearts, 3)
        XCTAssertFalse(outcome.weekendDoubled)
        XCTAssertFalse(outcome.examDoubled)
        print("RD-10 LessonOutcome: lesson=g1up-u1-kp1 answers=14 correct=10/12 XP=\(outcome.xpGained) stars=\(outcome.stars) hearts=\(heartsBefore)->\(store.hearts)")
    }
}
