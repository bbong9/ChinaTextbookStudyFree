import Foundation

// MARK: - Node building

/// Shared builder for a book's path nodes: lesson nodes with status/stars, a
/// chest node after every 5th lesson of a unit (see `Chest.slots`), plus a
/// trophy「单元挑战」node closing each unit that ships an exam lesson
/// (Wave E1). Used by both the Home tab and BookDetailView so the two paths
/// can't drift.
@MainActor
enum PathNodeBuilder {
    static func nodes(
        bookId: String,
        lessons: [PathLessonMeta],
        progressStore: ProgressStore,
        examSlots: [ExamSlot] = []
    ) -> [PathMapNode] {
        var foundCurrent = false
        let chestByAfterLesson = Dictionary(
            uniqueKeysWithValues: Chest.slots(bookId: bookId, lessons: lessons)
                .map { ($0.afterLessonId, $0) }
        )
        let examByUnit = Dictionary(
            uniqueKeysWithValues: examSlots.map { ($0.unitNumber, $0) }
        )
        var nodes: [PathMapNode] = []
        for (i, row) in lessons.enumerated() {
            let stars = progressStore.stars(for: row.id) ?? 0
            let isCompleted = stars > 0
            let status: LessonStatus
            if isCompleted {
                status = .completed
            } else if !foundCurrent {
                status = .current
                foundCurrent = true
            } else {
                status = .locked
            }
            nodes.append(PathMapNode(
                id: row.id,
                title: row.title,
                unitNumber: row.unitNumber,
                unitTitle: row.unitTitle,
                status: status,
                stars: stars,
                questionCount: row.questionCount
            ))
            if let slot = chestByAfterLesson[row.id] {
                nodes.append(PathMapNode(
                    id: slot.id,
                    title: "宝箱",
                    unitNumber: slot.unitNumber,
                    unitTitle: slot.unitTitle,
                    status: isCompleted ? .completed : .locked,
                    stars: 0,
                    kind: .chest,
                    chestClaimed: progressStore.isChestClaimed(slot.id)
                ))
            }
            // 单元最后一节普通课之后挂「单元挑战」奖杯节点：
            // 本单元全部普通课完成才解锁；accuracy ≥ 0.8 视为征服（金色态）。
            let isLastOfUnit = i + 1 >= lessons.count || lessons[i + 1].unitNumber != row.unitNumber
            if isLastOfUnit, let exam = examByUnit[row.unitNumber] {
                let unitDone = lessons
                    .filter { $0.unitNumber == row.unitNumber }
                    .allSatisfy { progressStore.isLessonCompleted($0.id) }
                let result = progressStore.progress.completedLessons[exam.lessonId]
                let examStatus: LessonStatus = result != nil
                    ? .completed
                    : unitDone ? .current : .locked
                nodes.append(PathMapNode(
                    id: exam.lessonId,
                    title: exam.title,
                    unitNumber: exam.unitNumber,
                    unitTitle: exam.unitTitle,
                    status: examStatus,
                    stars: result?.stars ?? 0,
                    kind: .exam,
                    conquered: (result?.accuracy ?? 0) >= 0.8,
                    questionCount: exam.questionCount
                ))
            }
        }
        return nodes
    }
}

// MARK: - Data model

struct PathMapNode: Identifiable, Hashable {
    enum Kind: Hashable { case lesson, chest, exam }

    let id: String
    let title: String
    let unitNumber: Int
    let unitTitle: String
    let status: LessonStatus
    let stars: Int
    var kind: Kind = .lesson
    /// Chest nodes only: whether the reward was already collected.
    var chestClaimed: Bool = false
    /// Exam nodes only: accuracy ≥ 0.8 conquered the unit (golden trophy).
    var conquered: Bool = false
    /// Lesson nodes only: drives the "+N XP" line in the start popup (0 = unknown).
    var questionCount: Int = 0
}
