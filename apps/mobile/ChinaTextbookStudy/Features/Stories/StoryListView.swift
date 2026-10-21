import SwiftUI

struct StoryListView: View {
    var bookId: String? = nil
    @Binding var path: [AppRoute]
    @ObservedObject private var progress = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var books: [Book] = []
    @State private var selected = ""
    @State private var stories: [Story] = []
    @State private var bedtime = false
    @State private var bedtimeStory: Story?
    @State private var loadError: String?

    private var units: [Int] { Set(stories.map(\.unitNumber)).sorted() }

    var body: some View {
        Stage { _ in
            StoryNightScene().overlay { if bedtime { ClayColor.black.opacity(0.32) } }
        } content: { ctx in
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ClayIconButton(icon: .back, id: "shell-back") { dismiss() }
                    TitleRibbon(title: "故事绘本", color: .blue)
                    Menu {
                        ForEach(books) { book in
                            Button(book.fullName) { selected = book.id; load() }
                                .accessibilityIdentifier("story-book-\(book.id)")
                        }
                    } label: {
                        Label(books.first { $0.id == selected }?.fullName ?? "选择语文书", systemImage: "chevron.down")
                            .font(ClayFont.body).foregroundStyle(ClayColor.ink)
                            .padding(.horizontal, 12).frame(minHeight: ctx.minimumTapDimension)
                            .background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
                    }
                    .accessibilityLabel("切换故事课本").accessibilityIdentifier("story-book-picker")
                    Spacer(minLength: 0)
                    Button { bedtime.toggle() } label: {
                        Text("🌙 睡前模式 \(bedtime ? "开" : "关")").font(ClayFont.largeButton)
                            .padding(.horizontal, 12).frame(minHeight: ctx.minimumTapDimension)
                            .background(bedtime ? ClayColor.blueEdge : ClayColor.darkPill,
                                        in: RoundedRectangle(cornerRadius: ClayRadius.button))
                    }
                    .buttonStyle(ClayPressStyle()).foregroundStyle(ClayColor.white)
                    .accessibilityLabel("睡前模式").accessibilityValue(bedtime ? "开" : "关")
                    .accessibilityIdentifier("story-bedtime-toggle")
                }
                if stories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical").font(ClayFont.happy(size: 44))
                        Text(loadError ?? "这本书还没有课外故事").font(ClayFont.body)
                        Text("换一本语文书，找找新的故事吧").font(ClayFont.body)
                    }
                    .foregroundStyle(ClayColor.white).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("story-shelf-empty")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(units, id: \.self) { unit in
                                Text("第\(unit)单元 · \(stories.first { $0.unitNumber == unit }?.unitTitle ?? "")")
                                    .font(ClayFont.body).foregroundStyle(ClayColor.white)
                                    .accessibilityAddTraits(.isHeader)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                                    ForEach(stories.filter { $0.unitNumber == unit }) { story in shelfCard(story) }
                                }
                            }
                        }.padding(8)
                    }
                    .accessibilityIdentifier("story-shelf-scroll")
                }
            }
            .padding(.vertical, 14)
            .frame(width: max(0, ctx.size.width - ctx.safeArea.leading - ctx.safeArea.trailing - 32),
                   height: max(0, ctx.size.height - ctx.safeArea.top - ctx.safeArea.bottom))
            .offset(x: ctx.safeArea.leading + 16, y: ctx.safeArea.top)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .fullScreenCover(item: $bedtimeStory) { story in
            StoryReaderView(bookId: story.bookId, storyId: story.id, bedtime: true)
        }
        .task { initialize() }
    }

    private func shelfCard(_ story: Story) -> some View {
        let done = progress.isReadingCompleted(Reading.id(.story, story.id))
        return Button {
            if bedtime { bedtimeStory = story }
            else { path.append(.storyReader(bookId: selected, storyId: story.id)) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                StoryIllustration(story: story).frame(height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: ClayRadius.smallButton))
                HStack {
                    Text(story.title).font(ClayFont.body).lineLimit(2)
                    Spacer(minLength: 0)
                    if done { Image(systemName: "checkmark.seal.fill").foregroundStyle(ClayColor.greenEdge) }
                }
                Text(done ? "已读完 ✓" : "\(story.sentences.count) 页 · \(bedtime ? "听故事，晚安" : "读一读，想一想")")
                    .font(ClayFont.caption)
            }
            .foregroundStyle(ClayColor.ink).padding(10)
            .background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.card))
            .clayShadow(.panel)
        }
        .buttonStyle(ClayPressStyle())
        .accessibilityLabel("\(story.title)，\(done ? "已读" : "未读")，\(story.sentences.count)页")
        .accessibilityIdentifier("story-card-\(story.id)")
    }

    private func initialize() {
        guard selected.isEmpty else { return }
        let index = try? DataLoader.shared.loadSiteIndex()
        books = index?.books.filter { $0.subject == .chinese || $0.id == bookId } ?? []
        let active = index?.books.first { $0.id == progress.activeBookId }
        let preferred = bookId ?? active.flatMap { book in
            book.subject == .chinese ? book.id : books.first { $0.grade == book.grade && $0.semester == book.semester }?.id
        }
        selected = books.first { $0.id == preferred }?.id ?? books.first?.id ?? "chinese-g1up"
        load()
    }

    private func load() {
        loadError = nil
        do { stories = (try DataLoader.shared.loadStories(bookId: selected))?.stories ?? [] }
        catch { stories = []; loadError = "故事暂时打不开，请换一本书试试" }
    }
}
