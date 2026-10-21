import SwiftUI

/// 横屏双栏：左侧选年级，右侧选课本；保持原来的选书和下载状态逻辑。
struct BookPickerSheet: View {
    let siteIndex: SiteIndex
    @ObservedObject var progressStore: ProgressStore
    @ObservedObject var downloader: AssetDownloader
    @Binding var isPresented: Bool
    let onPick: (String) -> Void
    var onBrowseGrade: (Int) -> Void = { _ in }
    @State private var selectedGrade: Int

    init(siteIndex: SiteIndex, progressStore: ProgressStore, downloader: AssetDownloader,
         isPresented: Binding<Bool>, onPick: @escaping (String) -> Void,
         onBrowseGrade: @escaping (Int) -> Void = { _ in }) {
        self.siteIndex = siteIndex; self.progressStore = progressStore; self.downloader = downloader
        _isPresented = isPresented; self.onPick = onPick; self.onBrowseGrade = onBrowseGrade
        _selectedGrade = State(initialValue: progressStore.selectedGrade > 0 ? progressStore.selectedGrade : 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("换本课本").font(ClayFont.body).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("按年级浏览") { isPresented = false; onBrowseGrade(selectedGrade) }
                    .font(ClayFont.caption).frame(minHeight: 44)
                    .accessibilityIdentifier("book-picker-browse-grade")
                Button { isPresented = false } label: {
                    ClayIconView(icon: .close, color: ClayColor.ink).frame(width: 18, height: 18)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("关闭").accessibilityIdentifier("book-picker-close")
            }
            HStack(alignment: .top, spacing: 16) {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(1...6, id: \.self) { grade in
                            Button { selectedGrade = grade; HapticEngine.shared.tap() } label: {
                                Text("\(grade)年级").font(ClayFont.body)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(selectedGrade == grade ? ClayColor.white : ClayColor.ink)
                                    .background(selectedGrade == grade ? ClayColor.orange : ClayColor.creamBottom,
                                                in: RoundedRectangle(cornerRadius: ClayRadius.smallButton))
                            }
                            .buttonStyle(.plain).accessibilityIdentifier("book-picker-grade-\(grade)")
                            .accessibilityAddTraits(selectedGrade == grade ? .isSelected : [])
                        }
                    }
                }.frame(width: 112).accessibilityIdentifier("book-picker-grades")
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(siteIndex.books.filter { $0.grade == selectedGrade }) { book in
                            Button {
                                HapticEngine.shared.tap()
                                progressStore.setSelectedGrade(selectedGrade)
                                onPick(book.id); isPresented = false
                            } label: { bookCard(book) }
                            .buttonStyle(.plain).accessibilityIdentifier("book-picker-book-\(book.id)")
                        }
                    }
                }.accessibilityIdentifier("book-picker-books")
            }
        }
        .padding(16).foregroundStyle(ClayColor.ink)
        .background(ClayGradient.buttonCream.view.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .contain).accessibilityIdentifier("book-picker-screen")
    }

    private func bookCard(_ book: Book) -> some View {
        HStack(spacing: 12) {
            DockIcon(kind: .books, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.fullName).font(ClayFont.body).multilineTextAlignment(.leading)
                Text("\(book.unitsCount) 单元 · \(book.lessonsCount) 节小课").font(ClayFont.caption)
                if downloader.isBookDownloaded(book.id) {
                    Label("已下载", systemImage: "checkmark.circle.fill").font(ClayFont.caption).foregroundStyle(ClayColor.greenEdge)
                } else if let entry = downloader.manifest?.books.first(where: { $0.bookId == book.id }) {
                    Text("需下载 · \(ByteCountFormatter.string(fromByteCount: entry.data.bytes + entry.audio.bytes, countStyle: .file))")
                        .font(ClayFont.caption)
                }
            }
            Spacer(minLength: 0)
            if progressStore.activeBookId == book.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(ClayColor.greenEdge) }
        }
        .foregroundStyle(ClayColor.ink).padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(ClayColor.white.opacity(0.85), in: RoundedRectangle(cornerRadius: ClayRadius.largeButton))
        .overlay { RoundedRectangle(cornerRadius: ClayRadius.largeButton)
            .strokeBorder(progressStore.activeBookId == book.id ? ClayColor.completed : ClayColor.creamEdge, lineWidth: 2) }
    }
}
