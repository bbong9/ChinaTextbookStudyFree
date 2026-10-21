import SwiftUI

struct MapHomeView: View {
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject var downloader: AssetDownloader
    let siteIndex: SiteIndex
    @Binding var path: [AppRoute]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var seeded = false
    @State private var activeSheet: Sheet?
    @State private var showAvatarMenu = false
    @State private var showStories = false
    @State private var hint: String?
    @State private var outline: Outline?
    @State private var pathNodes: [PathMapNode] = []
    @State private var mapLayout = HomeMapLayout(nodes: [])
    @State private var loadError: String?
    @State private var pathMetas: [PathLessonMeta] = []
    @State private var metasBookId: String?
    @State private var examSlots: [ExamSlot] = []
    @State private var activeChest: ActiveChest?
    private struct ActiveChest: Identifiable { let id: String }
    private enum Sheet: String, Identifiable {
        case book, streak, coins, hearts
        var id: String { rawValue }
    }

    private var activeBook: Book? {
        #if DEBUG
        if HomeMapTestSeed.flag("-uitest-map-empty") { return nil }
        #endif
        if let id = progressStore.activeBookId { return siteIndex.books.first { $0.id == id } }
        let grade = progressStore.selectedGrade
        if grade > 0 { return siteIndex.books.first { $0.grade == grade } ?? siteIndex.books.first }
        return siteIndex.books.first
    }

    var body: some View {
        Stage(background: { _ in ClayColor.skyTop }) { stage in
            ZStack(alignment: .topLeading) {
                if outline != nil {
                    HomeMapPath(layout: mapLayout, stage: stage,
                        onTap: start, onGuideTap: { unit in
                            if let book = activeBook { path.append(.guide(bookId: book.id, unitNumber: unit)) }
                        }, onJumpTap: jump,
                        onPetHome: { path.append(.petHome) },
                        onReadingRoom: { path.append(.readingRoom) }, onMath: { path.append(.mathTrain) })
                        .id(activeBook?.id)
                } else {
                    MeadowLayer(horizon: 230)
                    unavailable(stage)
                }
                HomeMapHUD(progressStore: progressStore, stage: stage, book: activeBook,
                    onAvatar: { showAvatarMenu.toggle() },
                    onCoins: { activeSheet = .coins }, onStreak: { activeSheet = .streak },
                    onHearts: { activeSheet = .hearts }, onCheckIn: { path.append(.checkIn) },
                    onShop: { path.append(.petShop) }, onQuests: { path.append(.quests) },
                    onParent: { path.append(.settings) }, onBook: { activeSheet = .book },
                    onGo: {
                        if let current = mapLayout.current { start(current.node) }
                        else { activeSheet = .book }
                    }, onDock: openDock,
                    onDebugGallery: {
                        #if DEBUG
                        path.append(.clayGallery)
                        #endif
                    })
                if showAvatarMenu {
                    avatarMenu
                        .frame(width: 230)
                        .position(x: stage.safeArea.leading + 126, y: stage.safeArea.top + 155)
                }
            }
        }
        .environment(\.clayMotionPaused, effectiveReduceMotion)
        .environment(\.petAnimationsPaused, effectiveReduceMotion)
        .fullScreenCover(item: $activeChest) { chest in
            ChestModalView(onClaim: { gems in
                progressStore.addGems(gems); progressStore.claimChest(chest.id)
            }, onDismiss: { activeChest = nil; reloadOutline() }, showsCoins: true)
                .presentationBackground(.clear)
        }
        .fullScreenCover(item: Binding(get: { progressStore.pendingLeagueResult },
            set: { if $0 == nil { progressStore.clearPendingLeagueResult() } })) { result in
            GeometryReader { geometry in
                // 原结算幕为竖排内容；横屏可滚到继续按钮，不改变结算与清除逻辑。
                ScrollView {
                    LeagueResultView(result: result) { progressStore.clearPendingLeagueResult() }
                        .frame(minHeight: geometry.size.height)
                }.background(DuoColors.bg.ignoresSafeArea())
            }
        }
        .overlay {
            if let claim = progressStore.pendingDailyReward {
                DailyRewardCard(claim: claim) {
                    withAnimation(.easeOut(duration: 0.25)) { progressStore.pendingDailyReward = nil }
                }.transition(.opacity).zIndex(2)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .book:
                    BookPickerSheet(siteIndex: siteIndex, progressStore: progressStore, downloader: downloader,
                        isPresented: Binding(get: { activeSheet == .book }, set: { if !$0 { activeSheet = nil } }),
                        onPick: { bookId in progressStore.setActiveBook(bookId); reloadOutline() },
                        onBrowseGrade: { grade in path.append(.bookList(grade: grade)) })
                case .streak: StreakDetailSheet(progressStore: progressStore)
                case .coins: GemShopSheet(progressStore: progressStore)
                case .hearts: HeartDetailSheet(progressStore: progressStore)
                }
            }.presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .confirmationDialog("故事绘本", isPresented: $showStories, titleVisibility: .visible) {
            if let book = activeBook {
                if book.hasStories == true {
                    Button("课外故事") { path.append(.stories(bookId: book.id)) }.accessibilityIdentifier("home-stories")
                }
                if book.hasPassages == true {
                    Button("课文听读") { path.append(.reading(bookId: book.id)) }.accessibilityIdentifier("home-reading")
                }
            }
            Button("睡前绘本") { path.append(.bedtimeStories) }.accessibilityIdentifier("home-bedtime-stories")
            Button("取消", role: .cancel) {}.accessibilityIdentifier("home-stories-cancel")
        }
        .alert("小提示", isPresented: Binding(get: { hint != nil }, set: { if !$0 { hint = nil } })) {
            Button("知道了", role: .cancel) { hint = nil }.accessibilityIdentifier("home-hint-dismiss")
        } message: { Text(hint ?? "") }
        .onAppear {
            reloadOutline()
            #if DEBUG
            if !seeded, HomeMapTestSeed.flag("-uitest-map-cloud") {
                var fixture = progressStore.progress; fixture.xp = 120
                progressStore.pendingCloudRestore = Backup.makeEnvelope(from: fixture)
            }
            #endif
            seeded = true
        }
        .onChange(of: progressStore.activeBookId) { _, _ in reloadOutline() }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var effectiveReduceMotion: Bool {
        #if DEBUG
        return reduceMotion || HomeMapTestSeed.flag("-uitest-map-reduce-motion")
        #else
        return reduceMotion
        #endif
    }

    private var avatarMenu: some View {
        VStack(spacing: 0) {
            menuEntry("我的", id: "profile", route: .profile)
            menuEntry("成就墙", id: "achievements", route: .achievements)
            menuEntry("排行", id: "league", route: .league)
            menuEntry("错题本", id: "review", route: .review)
            menuEntry("设置", id: "settings", route: .settings)
        }
        .padding(8).background { ClayGradient.buttonCream.view.clipShape(RoundedRectangle(cornerRadius: ClayRadius.largeButton)) }
        .clayShadow(.panel)
    }

    private func menuEntry(_ title: String, id: String, route: AppRoute) -> some View {
        Button { showAvatarMenu = false; path.append(route) } label: {
            Text(title).font(ClayFont.body).foregroundStyle(ClayColor.ink)
                .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("home-menu-\(id)")
    }

    @ViewBuilder private func unavailable(_ stage: StageLayout) -> some View {
        VStack(spacing: 10) {
            if let book = activeBook {
                if let loadError {
                    Text("这本书还没下载").font(ClayFont.body)
                    Text(loadError).font(ClayFont.caption)
                    if let entry = downloadEntry(for: book.id) {
                        BookDownloadCard(entry: entry, downloader: downloader) { reloadOutline() }
                    }
                    Button("选择其他课本") { activeSheet = .book }
                        .font(ClayFont.body).frame(minHeight: 44).accessibilityIdentifier("map-change-unavailable-book")
                } else { ProgressView("正在铺好小路…") }
            } else {
                PetView(mood: .wave, size: 70)
                Text("挑一本书开始学习吧").font(ClayFont.body)
                ClayButton(title: "选择课本", id: "map-empty-book-picker") { activeSheet = .book }
            }
        }
        .padding(16).frame(width: min(430, stage.size.width - 140))
        .foregroundStyle(ClayColor.ink)
        .background { ClayGradient.buttonCream.view.clipShape(RoundedRectangle(cornerRadius: ClayRadius.card)) }
        .clayShadow(.panel)
        .position(x: stage.size.width / 2, y: stage.size.height / 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(activeBook == nil ? "map-empty-state" : "map-download-state")
    }

    private func downloadEntry(for bookId: String) -> ManifestEntry? {
        if let entry = downloader.manifest?.books.first(where: { $0.bookId == bookId }) { return entry }
        #if DEBUG
        if HomeMapTestSeed.flag("-uitest-map-missing-book") {
            return ManifestEntry(bookId: bookId, audioRefCount: 0,
                data: ManifestBundle(name: "rd09-synthetic-data.zip", bytes: 1024, sha256: String(repeating: "0", count: 64)),
                audio: ManifestBundle(name: "rd09-synthetic-audio.zip", bytes: 0, sha256: String(repeating: "0", count: 64)))
        }
        #endif
        return nil
    }

    private func start(_ node: PathMapNode) {
        guard let book = activeBook, node.status != .locked else { return }
        if node.kind == .chest {
            if !node.chestClaimed { activeChest = ActiveChest(id: node.id) }
        } else if hasHeart() {
            path.append(.lesson(bookId: book.id, lessonId: node.id))
        }
    }

    private func jump(_ unit: Int) {
        if let book = activeBook, hasHeart() { path.append(.jumpTest(bookId: book.id, unitNumber: unit)) }
    }

    private func hasHeart() -> Bool {
        progressStore.tickHeartRecharge()
        guard progressStore.hearts > 0 else {
            HapticEngine.shared.wrong(); activeSheet = .hearts; return false
        }
        return true
    }

    private func openDock(_ kind: DockIcon.Kind) {
        switch kind {
        case .hanzi:
            if let book = activeBook, book.id.hasPrefix("chinese-") {
                path.append(.hanziMap(bookId: book.id))
            } else { hint = "这本书还没有识字关卡，换一本语文书试试" }
        case .math: path.append(.mathTrain)
        case .eng: path.append(.englishBalloons)
        case .animal: path.append(.animals)
        case .story:
            if activeBook?.hasStories == true || activeBook?.hasPassages == true { showStories = true }
            else { hint = "这本书还没有故事或课文听读，换一本语文或英语书试试" }
        case .idiom: path.append(.idiomPicker)
        case .books: path.append(.readingRoom)
        default: break
        }
    }

    // 原首页加载流程：每书缓存 metas/examSlots，返回时只刷新 builder 结果。
    private func reloadOutline() {
        guard let book = activeBook else { outline = nil; pathNodes = []; mapLayout = HomeMapLayout(nodes: []); return }
        if progressStore.activeBookId != book.id { progressStore.setActiveBook(book.id) }
        do {
            #if DEBUG
            if HomeMapTestSeed.flag("-uitest-map-missing-book") { throw DataLoaderError.bookNotDownloaded(book.id) }
            #endif
            if metasBookId != book.id || outline == nil {
                let loaded = try DataLoader.shared.loadOutline(bookId: book.id)
                outline = loaded
                pathMetas = loaded.pathLessonMetas(bookId: book.id) { lessonId in
                    (try? DataLoader.shared.loadLesson(bookId: book.id, lessonId: lessonId).questions.count) ?? 0
                }
                examSlots = loaded.examSlots(bookId: book.id); metasBookId = book.id
            }
            pathNodes = PathNodeBuilder.nodes(bookId: book.id, lessons: pathMetas,
                progressStore: progressStore, examSlots: examSlots)
            mapLayout = HomeMapLayout(nodes: pathNodes); loadError = nil
        } catch {
            outline = nil; pathNodes = []; mapLayout = HomeMapLayout(nodes: []); metasBookId = nil
            loadError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }
}
