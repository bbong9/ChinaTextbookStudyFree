import XCTest
import SwiftUI
import ZIPFoundation
@testable import ChinaTextbookStudy

/// 在真实模拟器窗口里承载生产 LessonShell / QuestionRendererView。
/// 每台设备一次跑完八种展示，固定数据并局部暂停装饰动画，不改课程与路由。
@MainActor
final class LessonPresentationTests: XCTestCase {
    func testComboPresentation() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = UIHostingController(rootView:
            ZStack {
                LessonScene(bookId: "g1up")
                ComboOverlayView(combo: 3)
            }.ignoresSafeArea().environment(\.clayMotionPaused, true)
                .transaction { $0.disablesAnimations = true }.statusBarHidden())
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        try await Task.sleep(for: .milliseconds(600))
        let screenshot = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: screenshot)
        attachment.name = "rd-10-combo"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEightSeedQuestionPresentations() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("rd10-layout-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.unzipItem(at: XCTUnwrap(Bundle.main.url(forResource: "seed-data", withExtension: "zip")), to: directory)
        let loader = DataLoader(dataRoot: directory.appendingPathComponent("data"))
        let math = try loader.loadLesson(bookId: "g1up", lessonId: "g1up-u1-kp1")
        let chinese = try loader.loadLesson(bookId: "chinese-g1down", lessonId: "chinese-g1down-u1-kp1")
        let english = try loader.loadLesson(bookId: "english-g3up", lessonId: "english-g3up-u1-kp1")
        let calculation = try loader.loadLesson(bookId: "g1up", lessonId: "g1up-u2-kp3")
        func question(_ lesson: Lesson, _ type: QuestionType) throws -> Question {
            try XCTUnwrap(lesson.questions.first { $0.type == type }, "\(lesson.id) 缺少 \(type.rawValue)")
        }
        var wordProblem = try question(math, .fillBlank)
        wordProblem.type = .wordProblem // seed 没有该类型；只在测试中投影现成的应用题题干。
        let samples: [(String, String, Question)] = [
            ("choice", math.bookId, try question(math, .choice)),
            ("trueFalse", math.bookId, try question(math, .trueFalse)),
            ("fillBlank", math.bookId, try question(math, .fillBlank)),
            ("calculation", calculation.bookId, try question(calculation, .calculation)),
            ("wordProblem", math.bookId, wordProblem),
            ("fillBlankText", english.bookId, try question(english, .fillBlankText)),
            ("wordOrder", chinese.bookId, try question(chinese, .wordOrder)),
            ("matching", chinese.bookId, try question(chinese, .matching))
        ]
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first { $0.isKeyWindow }
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        XCTAssertGreaterThan(window.bounds.width, window.bounds.height, "截图必须是横屏")
        for (name, bookId, sample) in samples {
            window.rootViewController = UIHostingController(rootView: LessonPresentationHarness(bookId: bookId, question: sample))
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(450))
            window.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let screenshot = renderer.image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "rd-10-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
            print("RD-10 layout: \(name) book=\(bookId) question=\(sample.id) viewport=\(window.bounds.size)")
        }
    }
}

private struct LessonPresentationHarness: View {
    let bookId: String
    let question: Question
    @State private var answer = ""
    var body: some View {
        LessonShell(bookId: bookId, question: question, instruction: instruction, checked: false) {
            LessonHeader(progress: 0, count: "0/12") {
                ClayIconButton(icon: .back, id: "lesson-close", label: "关闭") {}
            } trailing: {
                StatPill(icon: .heart, text: "5")
                LessonSymbolButton(symbol: "gearshape.fill", label: "课堂设置", id: "lesson-settings") {}
                ClayIconButton(icon: .help, id: "lesson-help", label: "知识讲解") {}
            }
        } answers: {
            QuestionRendererView(question: question, answer: answer, phase: .answering,
                                 isCorrect: nil, onChange: { answer = $0 })
        } action: {
            ClayButton(title: "检查", id: "检查答案") {}.disabled(answer.isEmpty).opacity(answer.isEmpty ? 0.55 : 1)
        } feedback: {
            EmptyView()
        }
        .environment(\.clayMotionPaused, true)
        .environment(\.petAnimationsPaused, true)
        .transaction { $0.disablesAnimations = true }
        .statusBarHidden().preferredColorScheme(.light)
    }
    private var instruction: String {
        switch question.type {
        case .choice: return "选择正确答案"
        case .trueFalse: return "判断对错"
        case .fillBlank, .fillBlankText: return "填写答案"
        case .calculation: return "计算结果"
        case .wordProblem: return "解答应用题"
        case .wordOrder: return "组成正确的句子"
        case .matching: return "将配对连线"
        }
    }
}
