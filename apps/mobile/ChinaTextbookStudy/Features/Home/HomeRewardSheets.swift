import SwiftUI

// MARK: - Daily login reward card

/// 出战宠物送金币：每天第一次打开应用时的轻量登录奖励卡。
/// 文案诚实：断签时按 0 档发放，不吹嘘一条已经断掉的连胜。
struct DailyRewardCard: View {
    let claim: ProgressStore.DailyRewardClaim
    let onDismiss: () -> Void

    private var subtitle: String {
        claim.effectiveStreak > 0
            ? "已连续学习 \(claim.effectiveStreak) 天，继续加油！"
            : "今天也来学一点吧！"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 14) {
                PetView(mood: .happy, size: 88, reactTo: .correct)

                Text("每日见面礼")
                    .duoFont(.heading, weight: .black)
                    .foregroundStyle(DuoColors.ink)

                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 20, weight: .heavy))
                    Text("+\(claim.gems)")
                        .duoNumeral(.title, weight: .black)
                }
                .foregroundStyle(DuoColors.beetle)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(DuoColors.beetle.opacity(0.14), in: .capsule)

                Text(subtitle)
                    .duoFont(.caption)
                    .foregroundStyle(DuoColors.inkMuted)
                    .multilineTextAlignment(.center)

                Button("收下啦") { onDismiss() }
                    .buttonStyle(ChunkyButtonStyle(.primary))
                    .accessibilityIdentifier("daily-reward-dismiss")
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(DuoColors.surface, in: .rect(cornerRadius: Radius.large))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.large)
                    .strokeBorder(DuoColors.border, lineWidth: 2)
            }
            .padding(28)
        }
        .onAppear { SFXEngine.shared.play(.unlock) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("daily-reward-card")
    }
}

// MARK: - Streak sheet

struct StreakDetailSheet: View {
    @ObservedObject var progressStore: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private let freezeCost = Economy.freezeCost
    private let makeupCost = Economy.streakMakeupCost

    /// Same tri-state as the HUD flame: studied today = lit, otherwise grey.
    private var flameColor: Color {
        progressStore.studiedToday ? DuoColors.fox : DuoColors.darkInkSofter
    }

    private var freezesFull: Bool { progressStore.streakFreezes >= Economy.maxFreezes }

    /// The broken-chain state where the 50-gem make-up can still revive it:
    /// nothing studied today, shields can't cover the gap, streak not yet
    /// overwritten by a new run.
    private var canOfferMakeup: Bool {
        !progressStore.studiedToday
            && progressStore.displayStreak == 0
            && progressStore.progress.streak > 0
            && SRS.daysBetween(progressStore.progress.lastActiveDate, SRS.todayString()) >= 2
    }

    /// Status line at the top: studied / still savable / already broken.
    private var statusText: String? {
        if progressStore.studiedToday { return "今日已打卡 ✓" }
        let display = progressStore.displayStreak
        if display > 0 { return "今天再学一节，保住 \(display) 天连胜" }
        if progressStore.progress.streak > 0 { return "连胜中断了，今天重新出发" }
        return nil   // brand-new learner: "开始你的连胜" below says it all
    }

    private var statusColor: Color {
        if progressStore.studiedToday { return DuoColors.primary }
        return progressStore.displayStreak > 0 ? DuoColors.fox : DuoColors.darkInkMuted
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    if let statusText {
                        Text(statusText)
                            .duoFont(.caption, weight: .heavy)
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(statusColor.opacity(0.14), in: .capsule)
                    }

                    ZStack {
                        Circle()
                            .fill(flameColor.opacity(0.18))
                            .frame(width: 112, height: 112)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 66, weight: .heavy))
                            .foregroundStyle(flameColor)
                    }

                    Text("\(progressStore.displayStreak)")
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(DuoColors.darkInk)
                        .monospacedDigit()

                    Text(progressStore.displayStreak > 0 ? "天连胜" : "开始你的连胜")
                        .duoFont(.body, weight: .heavy)
                        .foregroundStyle(DuoColors.darkInkMuted)
                }
                .padding(.top, 8)

                // 本周 7 格日历（ios-path-8）：哪天学了一眼看清。
                VStack(alignment: .leading, spacing: 10) {
                    Text("本周")
                        .duoFont(.caption)
                        .tracking(1.2)
                        .foregroundStyle(DuoColors.darkInkMuted)
                    StreakCalendarView(
                        entries: progressStore.weekXPEntries().map { (dateKey: $0.date, studied: $0.xp > 0) },
                        todayIndex: progressStore.todayIndexInWeek(),
                        todayStudied: progressStore.studiedToday
                    )
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DuoColors.darkSurface, in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(DuoColors.darkSurfaceAlt, lineWidth: 2)
                }

                VStack(alignment: .leading, spacing: 14) {
                    // Broken chain + makeup still possible → the 50-gem revive.
                    if canOfferMakeup {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "bandage.fill")
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundStyle(DuoColors.fox)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("补回 \(progressStore.progress.streak) 天连胜")
                                        .duoFont(.body, weight: .heavy)
                                        .foregroundStyle(DuoColors.darkInk)
                                    Text("用金币补上昨天的卡，今天再学一节就接上啦")
                                        .duoFont(.caption)
                                        .foregroundStyle(DuoColors.darkInkMuted)
                                }
                                Spacer()
                            }
                            Button {
                                if progressStore.makeUpYesterdayStreak() {
                                    HapticEngine.shared.success()
                                    SFXEngine.shared.play(.purchase)
                                } else {
                                    HapticEngine.shared.wrong()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.circle.fill").font(.system(size: 14, weight: .heavy))
                                    Text("连胜补卡  \(makeupCost)")
                                }
                            }
                            .buttonStyle(ChunkyButtonStyle(
                                progressStore.gems >= makeupCost ? .primary : .disabled
                            ))
                            .disabled(progressStore.gems < makeupCost)
                            .accessibilityIdentifier("streak-makeup")
                        }
                        .padding(14)
                        .background(DuoColors.fox.opacity(0.12), in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(DuoColors.fox.opacity(0.4), lineWidth: 2)
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(DuoColors.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("连胜护盾 \(progressStore.streakFreezes)/\(Economy.maxFreezes)")
                                .duoFont(.subhead, weight: .heavy)
                                .foregroundStyle(DuoColors.darkInk)
                            Text("一天没学习时，自动顶替你的连胜 · 每周一自动补 1 个")
                                .duoFont(.caption)
                                .foregroundStyle(DuoColors.darkInkMuted)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(DuoColors.darkSurface, in: .rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(DuoColors.darkSurfaceAlt, lineWidth: 2)
                    }

                    Button {
                        if progressStore.buyStreakFreeze(cost: freezeCost) {
                            HapticEngine.shared.success()
                            SFXEngine.shared.play(.purchase)
                        } else {
                            HapticEngine.shared.wrong()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "star.circle.fill").font(.system(size: 14, weight: .heavy))
                            Text(freezesFull
                                 ? "护盾已满 \(Economy.maxFreezes)/\(Economy.maxFreezes)"
                                 : "购买护盾  \(freezeCost)")
                        }
                    }
                    .buttonStyle(ChunkyButtonStyle(
                        (!freezesFull && progressStore.gems >= freezeCost) ? .secondary : .disabled
                    ))
                    .disabled(freezesFull || progressStore.gems < freezeCost)
                    .accessibilityIdentifier("streak-buy-freeze")
                }

                Spacer(minLength: 4)

                Button("知道了") { dismiss() }
                    .buttonStyle(ChunkyButtonStyle(.primary))
                    .accessibilityIdentifier("streak-detail-dismiss")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("连胜")
        .background(DuoColors.darkBg.ignoresSafeArea())
    }
}

// MARK: - Gem shop sheet

struct GemShopSheet: View {
    @ObservedObject var progressStore: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private let refillCost = Economy.heartRefillCost
    private let freezeCost = Economy.freezeCost

    @State private var flash: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Balance banner
                HStack(spacing: 10) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(DuoColors.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(progressStore.gems)")
                            .duoNumeral(.title, weight: .black)
                            .foregroundStyle(DuoColors.darkInk)
                        Text("我的金币")
                            .duoFont(.micro, weight: .heavy)
                            .foregroundStyle(DuoColors.darkInkMuted)
                    }
                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(DuoColors.secondary.opacity(0.14), in: .rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(DuoColors.secondary.opacity(0.4), lineWidth: 2)
                }

                if let flash {
                    Text(flash)
                        .duoFont(.caption, weight: .heavy)
                        .foregroundStyle(DuoColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DuoColors.primary.opacity(0.15), in: .rect(cornerRadius: 10))
                }

                Text("金币商店")
                    .duoFont(.caption)
                    .tracking(1.2)
                    .foregroundStyle(DuoColors.darkInkMuted)

                shopRow(
                    icon: "heart.fill",
                    iconColor: DuoColors.danger,
                    title: "补满红心",
                    subtitle: progressStore.hearts >= ProgressStore.maxHearts ? "红心已满" : "立即补满 5 颗红心",
                    cost: refillCost,
                    enabled: progressStore.hearts < ProgressStore.maxHearts && progressStore.gems >= refillCost
                ) {
                    if progressStore.buyHeartRefill(cost: refillCost) {
                        HapticEngine.shared.success()
                        SFXEngine.shared.play(.purchase)
                        flash = "红心已补满！"
                    } else {
                        HapticEngine.shared.wrong()
                    }
                }

                shopRow(
                    icon: "snowflake",
                    iconColor: DuoColors.secondary,
                    title: "连胜护盾",
                    subtitle: progressStore.streakFreezes >= Economy.maxFreezes
                        ? "护盾已满 \(Economy.maxFreezes)/\(Economy.maxFreezes)"
                        : "当前拥有 \(progressStore.streakFreezes)/\(Economy.maxFreezes) 个",
                    cost: freezeCost,
                    enabled: progressStore.streakFreezes < Economy.maxFreezes && progressStore.gems >= freezeCost
                ) {
                    if progressStore.buyStreakFreeze(cost: freezeCost) {
                        HapticEngine.shared.success()
                        SFXEngine.shared.play(.purchase)
                        flash = "已购买连胜护盾！"
                    } else {
                        HapticEngine.shared.wrong()
                    }
                }

                Text("完成课程可获得更多金币")
                    .duoFont(.caption)
                    .foregroundStyle(DuoColors.darkInkMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                Button("关闭") { dismiss() }
                    .buttonStyle(ChunkyButtonStyle(.primary))
                    .accessibilityIdentifier("coins-detail-dismiss")
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(DuoColors.darkBg.ignoresSafeArea())
    }

    @ViewBuilder
    private func shopRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        cost: Int,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.22)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 22, weight: .heavy)).foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).duoFont(.body, weight: .heavy).foregroundStyle(DuoColors.darkInk)
                    Text(subtitle).duoFont(.caption).foregroundStyle(DuoColors.darkInkMuted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill").font(.system(size: 13, weight: .heavy))
                    Text("\(cost)").duoNumeral(.caption, weight: .black)
                }
                .foregroundStyle(enabled ? DuoColors.secondary : DuoColors.darkInkSofter)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (enabled ? DuoColors.secondary.opacity(0.18) : DuoColors.darkSurfaceAlt.opacity(0.4)),
                    in: .capsule
                )
            }
            .padding(14)
            .background(DuoColors.darkSurface, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(DuoColors.darkSurfaceAlt, lineWidth: 2)
            }
            .opacity(enabled ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityIdentifier("coins-buy-\(icon)")
    }
}

// MARK: - Heart detail sheet

struct HeartDetailSheet: View {
    @ObservedObject var progressStore: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var tick = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("红心")
                    .duoFont(.title, weight: .black)
                    .foregroundStyle(DuoColors.darkInk)
                    .padding(.top, 6)

                HStack(spacing: 10) {
                    ForEach(0..<ProgressStore.maxHearts, id: \.self) { i in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(i < progressStore.hearts ? DuoColors.danger : DuoColors.darkSurfaceAlt)
                    }
                }

                if progressStore.hearts >= ProgressStore.maxHearts {
                    Text("你的红心已满！")
                        .duoFont(.body, weight: .heavy)
                        .foregroundStyle(DuoColors.darkInkMuted)
                } else if let next = progressStore.nextHeartAt {
                    VStack(spacing: 4) {
                        Text("下一颗红心还需")
                            .duoFont(.caption, weight: .heavy)
                            .foregroundStyle(DuoColors.darkInkMuted)
                        Text(formatCountdown(to: next, now: tick))
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(DuoColors.danger)
                            .monospacedDigit()
                        Text("每 5 分钟恢复 1 颗红心")
                            .duoFont(.micro)
                            .foregroundStyle(DuoColors.darkInkMuted)
                    }
                }

                if progressStore.streakFreezes > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "snowflake").foregroundStyle(DuoColors.secondary)
                        Text("连胜护盾 × \(progressStore.streakFreezes)")
                            .duoFont(.caption, weight: .heavy)
                            .foregroundStyle(DuoColors.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DuoColors.secondary.opacity(0.14), in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DuoColors.secondary.opacity(0.35), lineWidth: 2)
                    }
                }

                Button {
                    if progressStore.buyHeartRefill(cost: Economy.heartRefillCost) {
                        HapticEngine.shared.success()
                        SFXEngine.shared.play(.purchase)
                    } else {
                        HapticEngine.shared.wrong()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill").font(.system(size: 13, weight: .heavy))
                        Text("补满红心  \(Economy.heartRefillCost)")
                    }
                }
                .buttonStyle(ChunkyButtonStyle(
                    (progressStore.hearts < ProgressStore.maxHearts && progressStore.gems >= Economy.heartRefillCost) ? .secondary : .disabled
                ))
                .disabled(progressStore.hearts >= ProgressStore.maxHearts || progressStore.gems < Economy.heartRefillCost)
                .accessibilityIdentifier("hearts-buy-refill")

                Button("知道了") { dismiss() }
                    .buttonStyle(ChunkyButtonStyle(.primary))
                    .accessibilityIdentifier("hearts-detail-dismiss")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(DuoColors.darkBg.ignoresSafeArea())
        .onReceive(timer) { _ in
            tick = Date()
            progressStore.tickHeartRecharge()
        }
    }

    private func formatCountdown(to date: Date, now: Date) -> String {
        let remaining = max(0, date.timeIntervalSince(now))
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

