import SwiftUI

struct HomeQuestsView: View {
    @ObservedObject var progressStore: ProgressStore
    @Binding var path: [AppRoute]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DailyQuestsCard(progressStore: progressStore, clayStyle: true)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("home-daily-quests")
                HStack(spacing: 12) {
                    entry("错题复习", id: "quests-review", route: .review)
                    entry("装扮商店", id: "quests-shop", route: .shop)
                }
                WeeklyReportCard(progressStore: progressStore, clayStyle: true)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("home-weekly-report")
                // 依赖尚未合并的 RD-01 占位目的地仍有入口，不生成新的玩法页面。
                DisclosureGroup("更多玩法") {
                    VStack(spacing: 8) {
                        entry("识字地图", id: "quests-hanzi-map", route: .hanziMap(bookId: progressStore.activeBookId ?? "g1up"))
                        entry("识字关卡", id: "quests-hanzi-lesson", route: .hanziLesson(bookId: progressStore.activeBookId ?? "g1up", char: "日"))
                        entry("成语动画", id: "quests-idiom-player", route: .idiomPlayer(id: "shou-zhu-dai-tu"))
                        entry("睡前绘本", id: "quests-bedtime-stories", route: .bedtimeStories)
                    }.padding(.top, 8)
                }
                .font(ClayFont.body).padding(16)
                .background(ClayColor.creamBottom, in: RoundedRectangle(cornerRadius: ClayRadius.largeButton))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("quests-more")
            }.padding(16).frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
        }
        .background(ClayGradient.buttonCream.view.ignoresSafeArea())
        .accessibilityElement(children: .contain).accessibilityIdentifier("quests-screen")
    }

    private func entry(_ title: String, id: String, route: AppRoute) -> some View {
        Button { path.append(route) } label: {
            Text(title).font(ClayFont.body).frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(ClayColor.ink)
                .background(ClayColor.white, in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
        }.buttonStyle(ClayPressStyle()).accessibilityIdentifier(id)
    }
}
