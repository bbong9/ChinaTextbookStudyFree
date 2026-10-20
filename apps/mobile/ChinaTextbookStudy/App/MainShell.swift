import SwiftUI

/// iPhone / iPad 共用一个横屏导航栈，首页始终是唯一根页面。
struct MainShell: View {
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject var downloader: AssetDownloader
    let siteIndex: SiteIndex

    @State private var path: [AppRoute] = []
    @State private var showFirstLessonToast = false
    @State private var didAutoStartFirstLesson = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                progressStore: progressStore,
                downloader: downloader,
                siteIndex: siteIndex,
                path: $path
            )
            .safeAreaInset(edge: .top, spacing: 0) {
                temporaryEntrances
            }
            .navigationDestination(for: AppRoute.self) { route in
                RouteView(
                    route: route,
                    progressStore: progressStore,
                    downloader: downloader,
                    siteIndex: siteIndex,
                    path: $path
                )
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: progressStore.hasCompletedOnboarding) { _, done in
            if done, isBrandNewLearner { startFirstLessonAfterOnboarding() }
        }
        .overlay(alignment: .top) {
            if showFirstLessonToast {
                firstLessonToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
    }

    /// RD-09 将入口收进地图和头像菜单；这里只保留能滚动、能点到的按钮。
    private var temporaryEntrances: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: Space.m) {
                    entry("排行", id: "league", route: .league)
                    entry("错题本", id: "review", route: .review)
                    entry("商店", id: "shop", route: .shop)
                    entry("我的", id: "profile", route: .profile)
                    entry("成就墙", id: "achievements", route: .achievements)
                    Menu {
                        ForEach(1...6, id: \.self) { grade in
                            Button("\(grade) 年级") { path.append(.bookList(grade: grade)) }
                                .accessibilityIdentifier("shell-grade-\(grade)")
                        }
                    } label: {
                        Text("按年级")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("按年级浏览课本")
                    .accessibilityIdentifier("shell-open-grades")
                }
                .padding(.horizontal, Space.m)
            }
            .frame(height: 44)
            .accessibilityIdentifier("shell-legacy-routes")

            ScrollView(.horizontal) {
                HStack(spacing: Space.m) {
                    ForEach(AppRoute.temporaryRoutes(bookId: progressStore.activeBookId ?? siteIndex.books.first?.id ?? "g1up"), id: \.self) { route in
                        if let placeholder = route.placeholder {
                            entry(placeholder.title, id: placeholder.id, route: route)
                        }
                    }
                }
                .padding(.horizontal, Space.m)
            }
            .frame(height: 44)
            .accessibilityIdentifier("shell-new-routes")
        }
        .duoFont(.caption)
        .foregroundStyle(DuoColors.ink)
        .background(DuoColors.bg)
    }

    private func entry(_ title: String, id: String, route: AppRoute) -> some View {
        Button { path.append(route) } label: {
            Text(title)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("shell-open-\(id)")
    }

    // MARK: - Post-onboarding first lesson (ios-retention-11)

    /// `hasCompletedOnboarding` 变真有两条路：真的走完新手引导，以及
    /// `acceptCloudRestore()` 里「恢复存档的老学员不用再走引导」（iosretention-3）。
    /// 只有前者该被推进第一课 —— 带着一身进度回来的孩子被塞进第一课，
    /// 既莫名其妙又会盖掉他真正的进度页。
    ///
    /// 判据用「一点进度都没有」：云端恢复提示本身就要求备份里
    /// `completedLessons` 非空或 `xp > 0`（见 `checkCloudRestoreOffer`），
    /// 所以恢复完成时这两项必有其一不为零，恒被挡在门外。
    private var isBrandNewLearner: Bool {
        progressStore.totalCompletedLessons == 0 && progressStore.progress.xp == 0
    }

    /// Resolve the active book's very first path lesson and push it. If the
    /// book isn't downloaded yet (outline load throws) we simply stay on the
    /// home screen, where the download card takes over.
    private func startFirstLessonAfterOnboarding() {
        guard !didAutoStartFirstLesson else { return }
        guard
            let bookId = progressStore.activeBookId,
            let outline = try? DataLoader.shared.loadOutline(bookId: bookId),
            let first = outline.pathLessonMetas(bookId: bookId).first
        else { return }

        didAutoStartFirstLesson = true
        withAnimation(Motion.bounce) { showFirstLessonToast = true }
        // Let the onboarding fade + toast land, then push the lesson.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            path.append(.lesson(bookId: bookId, lessonId: first.id))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) { showFirstLessonToast = false }
        }
    }

    private var firstLessonToast: some View {
        HStack(spacing: 10) {
            PetView(mood: .cheer, size: 52, reactTo: .correct)
            Text("我们马上开始第一课！")
                .duoFont(.subhead)
                .foregroundStyle(DuoColors.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(DuoColors.surface, in: .capsule)
        .overlay { Capsule().strokeBorder(DuoColors.border, lineWidth: 2) }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .padding(.top, 8)
        .allowsHitTesting(false)
        .accessibilityIdentifier("first-lesson-toast")
    }

}

/// 统一解析全屏目的地；旧页面暂用外壳页头，RD-02 / RD-22 再替换样式。
struct RouteView: View {
    let route: AppRoute
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject var downloader: AssetDownloader
    let siteIndex: SiteIndex
    @Binding var path: [AppRoute]

    var body: some View {
        Group {
            if let title = route.shellTitle {
                VStack(spacing: 0) {
                    pageHeader(title)
                        .fixedSize(horizontal: false, vertical: true)
                        .zIndex(1)
                    destination
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                }
            } else {
                destination
            }
        }
        .background(DuoColors.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    /// 显式占用页头高度，避免旧页面的固有高度把返回按钮挤到屏幕外。
    private func pageHeader(_ title: String) -> some View {
        HStack(spacing: Space.m) {
            Button {
                guard !path.isEmpty else { return }
                path.removeLast()
            } label: {
                Label("返回", systemImage: "chevron.left")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回上一页")
            .accessibilityIdentifier("shell-back")
            Text(title)
                .duoFont(.subhead)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("shell-page-title")
            Spacer(minLength: 0)
            switch route {
            case .reviewRunner, .storyReader, .passageReader:
                MuteToggle()
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, Space.m)
        .foregroundStyle(DuoColors.ink)
        .background(DuoColors.bg)
    }

    @ViewBuilder
    private var destination: some View {
        switch route {
        #if DEBUG
        case .clayGallery:
            ClayGallery { path.removeLast() }
        #endif
        case .league:
            LeagueView(progressStore: progressStore)
        case .petFamily, .petHome, .petShop, .checkIn, .quests, .parentCenter,
             .hanziMap, .hanziLesson, .mathTrain, .englishBalloons, .animals,
             .idiomPicker, .idiomPlayer, .bedtimeStories, .readingRoom:
            if let placeholder = route.placeholder {
                Text("建设中")
                    .duoFont(.heading)
                    .foregroundStyle(DuoColors.inkMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DuoColors.bg.ignoresSafeArea())
                    .accessibilityIdentifier("placeholder-\(placeholder.id)")
            }
        case .bookList(let grade):
            BookListView(grade: grade, siteIndex: siteIndex, path: $path)
        case .bookDetail(let bookId):
            BookDetailView(
                bookId: bookId,
                progressStore: progressStore,
                downloader: downloader,
                path: $path
            )
        case .lesson(let bookId, let lessonId):
            LessonRunnerView(
                bookId: bookId,
                lessonId: lessonId,
                progressStore: progressStore,
                path: $path
            )
        case .lessonResult(let result):
            LessonResultView(
                result: result,
                progressStore: progressStore,
                path: $path
            )
        case .review:
            ReviewView(progressStore: progressStore, path: $path)
        case .reviewRunner:
            MistakeReviewRunnerView(progressStore: progressStore, path: $path)
        case .achievements:
            AchievementsView(progressStore: progressStore)
        case .stories(let bookId):
            StoryListView(bookId: bookId, path: $path)
        case .storyReader(let bookId, let storyId):
            StoryReaderView(bookId: bookId, storyId: storyId)
        case .reading(let bookId):
            PassageListView(bookId: bookId, path: $path)
        case .passageReader(let bookId, let passageId):
            PassageReaderView(bookId: bookId, passageId: passageId)
        case .shop:
            ShopView(progressStore: progressStore)
        case .profile:
            ProfileView(progressStore: progressStore, path: $path)
        case .settings:
            SettingsView(progressStore: progressStore)
        case .guide(let bookId, let unitNumber):
            UnitGuideView(bookId: bookId, unitNumber: unitNumber)
        case .jumpTest(let bookId, let unitNumber):
            JumpTestView(
                bookId: bookId,
                unitNumber: unitNumber,
                progressStore: progressStore,
                path: $path
            )
        }
    }
}
