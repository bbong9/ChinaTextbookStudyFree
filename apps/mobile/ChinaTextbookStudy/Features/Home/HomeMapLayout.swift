import SwiftUI

/// 只布局 builder 的结果；不推导解锁、宝箱或挑战规则。
struct HomeMapLayout {
    struct Entry: Identifiable, Equatable {
        let node: PathMapNode
        let number: Int
        let point: CGPoint
        var id: String { node.id }
        /// RD-13 接入时传汉字，课本节点继续传全书序号。
        func label(character: String? = nil) -> String { character ?? String(number) }
    }
    struct Unit: Identifiable, Equatable {
        let number: Int
        let title: String
        let origin: CGFloat
        let width: CGFloat
        let entries: [Entry]
        var id: Int { number }
        var locked: Bool {
            let lessons = entries.filter { $0.node.kind == .lesson }
            return !lessons.isEmpty && lessons.allSatisfy { $0.node.status == .locked }
        }
        var road: [CGPoint] {
            [CGPoint(x: -24, y: 300)] + entries.map(\.point) + [CGPoint(x: width + 24, y: 300)]
        }
    }
    struct Anchor: Identifiable {
        let id: String
        let gap: CGFloat
    }
    let units: [Unit]
    let anchors: [Anchor]
    let width: CGFloat
    let current: Entry?
    let currentX: CGFloat?

    init(nodes: [PathMapNode]) {
        var units: [Unit] = [], origin: CGFloat = 0
        var number = 0
        var groups: [[PathMapNode]] = []
        for node in nodes {
            if groups.last?.first?.unitNumber != node.unitNumber { groups.append([]) }
            groups[groups.count - 1].append(node)
        }
        for (index, group) in groups.enumerated() {
            let start: CGFloat = index == 0 ? 338 : 112
            let width = max(844, start + CGFloat(group.count) * 62 + 90)
            let entries = group.enumerated().map { offset, node in
                if node.kind == .lesson { number += 1 }
                return Entry(node: node, number: number,
                             point: CGPoint(x: start + CGFloat(offset) * 62,
                                            y: 272 - 22 * sin(CGFloat(offset) * .pi / 8)))
            }
            units.append(Unit(number: group[0].unitNumber, title: group[0].unitTitle,
                              origin: origin, width: width, entries: entries))
            origin += width
        }
        self.units = units
        var precedingEnd: CGFloat = 0
        anchors = units.flatMap { unit in
            unit.entries.map { entry in
                let x = unit.origin + entry.point.x
                let anchor = Anchor(id: entry.id, gap: max(0, x - precedingEnd))
                precedingEnd = x + 1
                return anchor
            }
        }
        width = max(844, origin)
        // 沿用旧地图：挑战节点不抢占主线定位，全通后定位最后一节课。
        let resolvedCurrent = nodes.first { $0.status == .current && $0.kind != .exam }
            .flatMap { node in units.flatMap(\.entries).first { $0.id == node.id } }
            ?? units.flatMap(\.entries).last { $0.node.kind == .lesson }
        current = resolvedCurrent
        currentX = units.first { unit in unit.entries.contains { $0.id == resolvedCurrent?.id } }
            .flatMap { unit in resolvedCurrent.map { unit.origin + $0.point.x } }
    }

    static func parallaxCorrection(offset: CGFloat, rate: CGFloat, reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 0 : offset * (1 - rate)
    }

    static func currentVisible(x: CGFloat?, offset: CGFloat, viewport: CGFloat) -> Bool {
        guard let x else { return true }
        return x + offset >= 44 && x + offset <= viewport - 44
    }

    static func maxXP(_ node: PathMapNode) -> Int {
        Economy.xpForLesson(correctCount: node.questionCount, perfect: true,
                            firstPerfect: node.stars < 3, isWeekend: Economy.isWeekend(),
                            isExam: node.kind == .exam)
    }
}
