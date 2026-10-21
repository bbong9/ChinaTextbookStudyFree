import SwiftUI

struct HomeMapHUD: View {
    @ObservedObject var progressStore: ProgressStore
    let stage: StageLayout
    let book: Book?
    let onAvatar: () -> Void
    let onCoins: () -> Void
    let onStreak: () -> Void
    let onHearts: () -> Void
    let onCheckIn: () -> Void
    let onShop: () -> Void
    let onQuests: () -> Void
    let onParent: () -> Void
    let onBook: () -> Void
    let onGo: () -> Void
    let onDock: (DockIcon.Kind) -> Void
    var onDebugGallery: () -> Void = {}

    private let dockKinds: [DockIcon.Kind] = [.hanzi, .math, .eng, .animal, .story, .idiom, .books]
    private var horizontalInset: CGFloat { 12 }
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 6) {
                    Button(action: onAvatar) {
                        AvatarBadge(level: Level.levelInfo(progressStore.progress.xp).level) {
                            PetView(size: 52).allowsHitTesting(false)
                        }
                        .frame(width: 66, height: 68)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("头像菜单")
                    .accessibilityIdentifier("hud-avatar")
                    #if DEBUG
                    .onLongPressGesture(minimumDuration: 0.8, perform: onDebugGallery)
                    .accessibilityAction(named: "打开黏土组件预览", onDebugGallery)
                    #endif
                    stat(icon: nil, text: progressStore.gems.formatted(), id: "hud-coins", label: "金币", action: onCoins)
                    stat(icon: .flame, text: "连签\(progressStore.displayStreak)天", id: "hud-streak", label: "连签", action: onStreak)
                    stat(icon: .heart, text: "\(progressStore.hearts)", id: "hud-hearts", label: "红心", action: onHearts)
                }
                dailyGoal.padding(.top, 7)
                HStack(spacing: 4) {
                    topIcon(.checkin, id: "hud-checkin", action: onCheckIn)
                        .overlay(alignment: .topTrailing) {
                            if progressStore.pendingDailyReward != nil {
                                Circle().fill(ClayColor.petCoral).frame(width: 8, height: 8).allowsHitTesting(false)
                            }
                        }
                    topIcon(.shop, id: "hud-pet-shop", action: onShop)
                    topIcon(.task, id: "hud-quests", action: onQuests)
                    topIcon(.parent, id: "hud-parent", action: onParent)
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 12) {
                bookBadge
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(dockKinds) { kind in
                        Button { onDock(kind) } label: {
                            VStack(spacing: 0) {
                                DockIcon(kind: kind, size: 46)
                                OutlinedLabel(text: kind.label)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minWidth: stage.minimumTapDimension, minHeight: stage.minimumTapDimension)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ClayPressStyle())
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(kind.label).accessibilityIdentifier("dock-\(kind.rawValue)")
                    }
                }
                GoButton(id: "hud-go", action: onGo)
                    .disabled(book == nil)
            }
        }
        .padding(.leading, stage.safeArea.leading + horizontalInset)
        .padding(.trailing, stage.safeArea.trailing + horizontalInset)
        .padding(.top, stage.safeArea.top + 8)
        .padding(.bottom, stage.safeArea.bottom + 12)
        .frame(width: stage.size.width, height: stage.size.height)
    }

    private func stat(icon: ClayIcon?, text: String, id: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { StatPill(icon: icon, text: text).clayHitTarget() }
            .buttonStyle(ClayPressStyle()).accessibilityLabel("\(label) \(text)")
            .accessibilityIdentifier(id).padding(.top, 9)
    }

    private var dailyGoal: some View {
        let reached = progressStore.todayXp >= progressStore.dailyGoal
        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 3) {
                    Text(reached ? "今日目标 ✓" : "今日目标").font(ClayFont.label)
                    Spacer(minLength: 0)
                    Text("\(progressStore.todayXp)/\(progressStore.dailyGoal) XP").font(ClayFont.level)
                }
                GeometryReader { geometry in
                    Capsule().fill(ClayColor.white.opacity(0.25))
                        .overlay(alignment: .leading) {
                            Capsule().fill(ClayColor.completed)
                                .frame(width: geometry.size.width * min(1, CGFloat(progressStore.todayXp) / CGFloat(max(1, progressStore.dailyGoal))))
                        }
                }.frame(height: 6)
            }
            PetCoin(size: 18)
        }
        .foregroundStyle(ClayColor.white).padding(.horizontal, 10)
        .frame(minWidth: 130, maxWidth: .infinity).frame(height: 40)
        .background(reached ? ClayColor.greenEdge : ClayColor.darkPill, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今日目标，\(progressStore.todayXp) / \(progressStore.dailyGoal) XP\(reached ? "，已达标" : "")")
        .accessibilityIdentifier("hud-daily-goal")
    }

    private func topIcon(_ kind: DockIcon.Kind, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                DockIcon(kind: kind, size: 42)
                OutlinedLabel(text: kind.label)
            }
            .frame(width: max(48, stage.minimumTapDimension), height: max(62, stage.minimumTapDimension))
            .contentShape(Rectangle())
        }
        .buttonStyle(ClayPressStyle()).accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.label).accessibilityIdentifier(id)
    }

    private var bookBadge: some View {
        Button(action: onBook) {
            HStack(spacing: 3) {
                DockIcon(kind: .books, size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(edition).font(ClayFont.caption)
                    Text(book.map { $0.gradeName + ($0.semester == "up" ? "上" : "下") } ?? "选择课本")
                        .font(ClayFont.label)
                }
                .foregroundStyle(ClayColor.white)
            }
            .frame(width: 124, height: 50)
            .background(ClayGradient.blue.view, in: RoundedRectangle(cornerRadius: ClayRadius.largeButton))
            .clayShadow(.stat).clayHitTarget()
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel("换年级或换课本，\(book?.fullName ?? "没有选书")")
        .accessibilityIdentifier("hud-book")
    }

    private var edition: String {
        guard let name = book?.fullName else { return "课本库" }
        if let range = name.range(of: "版") { return String(name[..<range.upperBound]) }
        return book?.subjectName ?? "课本乐园"
    }
}
