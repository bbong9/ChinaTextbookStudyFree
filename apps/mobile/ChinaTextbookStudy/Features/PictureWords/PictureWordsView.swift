import SwiftUI

struct PictureWordsView: View {
    @ObservedObject var progressStore: ProgressStore
    var onBack: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var category: PictureCategory = .animals
    @State private var scene: PictureScene = .farm
    @State private var selected: PictureWord?
    @State private var showAlbum = false
    @State private var bounce = false
    @State private var tapSequence = 0

    var body: some View {
        Stage { layout in
            PictureWordScene(scene: scene, layout: layout)
        } content: { layout in
            sceneItems(layout)
                .accessibilityHidden(showAlbum)
            if let selected { wordCard(selected, layout: layout).accessibilityHidden(showAlbum) }
            header(layout)
                .accessibilityHidden(showAlbum)
            footer(layout)
                .accessibilityHidden(showAlbum)
            if showAlbum { album(layout) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("picture-words-screen")
        .onAppear { ClayKaiFontStore.shared.startIfNeeded() }
        .onDisappear { AudioPlayer.shared.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { AudioPlayer.shared.stop() }
        }
        .task(id: tapSequence) {
            guard tapSequence > 0, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.13)) { bounce = true }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { bounce = false }
        }
        .onChange(of: reduceMotion) { _, _ in bounce = false }
    }

    private func header(_ layout: StageLayout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ClayIconButton(icon: .back, id: "shell-back", label: "返回上一页", action: onBack)
                TitleRibbon(title: "看图识物 · 3–6 岁", color: .green)
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    ForEach(PictureCategory.allCases) { item in
                        Button { changeCategory(item) } label: {
                            Text(item.emoji).font(ClayFont.happy(size: 30))
                                .frame(width: 64 / layout.scale, height: 64 / layout.scale)
                                .background(ClayColor.creamTop, in: Circle())
                                .overlay { Circle().strokeBorder(category == item ? ClayColor.orange : ClayColor.creamEdge,
                                                                lineWidth: category == item ? 4 : 2) }
                                .clayShadow(.icon)
                        }
                        .buttonStyle(ClayPressStyle())
                        .accessibilityLabel("\(item.name)分类")
                        .accessibilityValue(category == item ? "已选中" : "")
                        .accessibilityIdentifier("picture-category-\(item.id)")
                    }
                }
            }
            HStack {
                Text(category == .animals ? "点一点小动物，听它的名字和叫声" : "点一点，听听它的名字")
                    .font(ClayFont.label).foregroundStyle(ClayColor.greenEdge)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(ClayColor.white.opacity(0.8), in: Capsule())
                Spacer(minLength: 4)
                if category == .animals { scenePicker(layout) }
            }
            .frame(height: 44 / layout.scale)
            .frame(width: max(0, layout.size.width - layout.safeArea.leading - layout.safeArea.trailing
                               - 48 - 270 / min(1, layout.scale)), alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: max(0, layout.size.width - layout.safeArea.leading - layout.safeArea.trailing - 32))
        .position(x: (layout.safeArea.leading + layout.size.width - layout.safeArea.trailing) / 2,
                  y: layout.safeArea.top + 16 + (108 / layout.scale + 8) / 2)
    }

    /// 以设计稿中的三位农场伙伴为主角，其余词条在同一场景前后错落摆放。
    private func sceneItems(_ layout: StageLayout) -> some View {
        let words = PictureWords.words(in: scene)
        return ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle())
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                let spot = position(index, count: words.count, layout: layout)
                let panelLeft = layout.size.width - layout.safeArea.trailing - 16 - 270 / min(1, layout.scale)
                let sceneOrigin = layout.place(x: 0, y: 0).x
                let right = selected == nil ? 550 : min(550, panelLeft - sceneOrigin - 12 / layout.scale)
                let margin = max(56, 44 / layout.scale)
                let x = margin + (spot.x - margin) * (right - 2 * margin) / (550 - 2 * margin)
                item(word, side: spot.side, minimum: 64 / layout.scale)
                    .position(layout.place(x: x, y: spot.y))
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 40).onEnded { gesture in
            guard category == .animals, abs(gesture.translation.width) > abs(gesture.translation.height) else { return }
            stepScene(gesture.translation.width < 0 ? 1 : -1)
        })
        .accessibilityElement(children: .contain)
    }

    private func position(_ index: Int, count: Int, layout: StageLayout) -> (x: CGFloat, y: CGFloat, side: CGFloat) {
        if scene == .farm {
            if index < 3 {
                return ([150, 312, 488][index], [290, 310, 305][index], [100, 100, 112][index])
            }
            return (CGFloat(index - 3) * 103 + 62, 192, 64 / layout.scale)
        }
        if count <= 4 { return (CGFloat(index) * 140 + 90, 292, 100) }
        let columns = count > 8 ? 5 : 4
        let column = index % columns, row = index / columns
        return (CGFloat(column) * (500 / CGFloat(columns)) + 64, CGFloat(row) * 108 + 205, 68 / layout.scale)
    }

    private func item(_ word: PictureWord, side: CGFloat, minimum: CGFloat) -> some View {
        Button { discover(word) } label: {
            ZStack {
                if selected?.id == word.id {
                    ClayGradient.glow.view.clipShape(Ellipse()).frame(width: side * 1.45, height: side * 1.35)
                }
                PictureWordArt(word: word, size: side)
                    .scaleEffect(selected?.id == word.id && bounce && !reduceMotion ? 1.06 : 1)
                    .offset(y: selected?.id == word.id && bounce && !reduceMotion ? -6 : 0)
            }
            .frame(width: max(minimum, side), height: max(minimum, side))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word.char)
        .accessibilityHint("听名字和介绍，记入图鉴")
        .accessibilityValue(selected?.id == word.id ? "已选中" : "")
        .accessibilityIdentifier("picture-item-\(word.id)")
    }

    private func wordCard(_ word: PictureWord, layout: StageLayout) -> some View {
        let scale = min(1, layout.scale)
        let width: CGFloat = 270 / scale
        let top = max(layout.safeArea.top + 16 + 64 / layout.scale + 12, layout.place(x: 0, y: 50).y)
        let available = layout.size.height - layout.safeArea.bottom - 16 - 64 / layout.scale - 12 - top
        let height = max(0, min(word.char.count > 1 ? 208 / scale : 156 / scale, available))
        return ScrollView {
        VStack(spacing: 2) {
            HStack(alignment: .center, spacing: 8) {
                Text(word.char)
                    .clayKaiFont(size: ClayFont.pictureCharacterSize / scale)
                    .foregroundStyle(ClayColor.ink)
                    .fixedSize()
                    .accessibilityIdentifier("picture-card-character")
                if word.char.count == 1 {
                    VStack(alignment: .leading, spacing: 3) { pronunciation(word, scale: scale) }
                }
            }
            if word.char.count > 1 {
                HStack(spacing: 8) { pronunciation(word, scale: scale) }
            }
            Text(word.sound).font(ClayFont.caption).foregroundStyle(ClayColor.woodDark)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(width: width)
        }
        .frame(width: width, height: height)
        .background(ClayColor.white, in: RoundedRectangle(cornerRadius: ClayRadius.pictureCard))
        .clipShape(RoundedRectangle(cornerRadius: ClayRadius.pictureCard))
        .clayShadow(.bubble)
        .position(x: layout.size.width - layout.safeArea.trailing - 16 - width / 2,
                  y: top + height / 2)
        .id(word.id)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("picture-word-card")
    }

    @ViewBuilder private func pronunciation(_ word: PictureWord, scale: CGFloat) -> some View {
        Text(word.pinyin).font(ClayFont.nunito(size: ClayFont.picturePinyinSize / scale))
            .foregroundStyle(ClayColor.orangeDeep).fixedSize()
            .accessibilityIdentifier("picture-card-pinyin")
        HStack(spacing: 4) {
            Text(word.english).font(ClayFont.say).foregroundStyle(ClayColor.petClean)
                .accessibilityIdentifier("picture-card-english")
            SayButton(id: "picture-speak-english", label: "朗读英文\(word.english)") {
                SpeechTextIndex.shared.register(word)
                AudioPlayer.shared.play(path: word.englishAudio)
            }
        }
    }

    private func footer(_ layout: StageLayout) -> some View {
        ZStack {
            Button {
                AudioPlayer.shared.stop(); showAlbum = true
            } label: {
                VStack(spacing: 0) {
                    Image(systemName: "book.closed.fill").font(ClayFont.happy(size: 27))
                    Text("图鉴 \(progressStore.pictureWordsSeen.count) / \(PictureWords.all.count)").font(ClayFont.label)
                }
                .foregroundStyle(ClayColor.creamText)
                .frame(width: 116, height: 64 / layout.scale)
                .claySurface(.buttonCream, radius: ClayRadius.button, edge: ClayColor.creamEdge)
            }
            .buttonStyle(ClayPressStyle())
            .accessibilityLabel("打开图鉴")
            .accessibilityValue("\(progressStore.pictureWordsSeen.count) / \(PictureWords.all.count)")
            .accessibilityIdentifier("picture-album")
            .stageAnchor(.bottomTrailing, in: layout, size: .init(width: 116, height: 64 / layout.scale))
        }
    }

    private func scenePicker(_ layout: StageLayout) -> some View {
        HStack(spacing: 4) {
            ForEach(category.scenes) { item in
                Button { changeScene(item) } label: {
                    Text(item.name).font(ClayFont.label)
                        .foregroundStyle(scene == item ? ClayColor.white : ClayColor.greenEdge)
                        .frame(width: 44 / layout.scale, height: 44 / layout.scale)
                        .background(scene == item ? ClayColor.completed : ClayColor.creamTop, in: Capsule())
                }
                .buttonStyle(ClayPressStyle())
                .accessibilityLabel("\(item.name)场景")
                .accessibilityValue(scene == item ? "当前场景" : "")
                .accessibilityIdentifier("picture-scene-button-\(item.id)")
            }
        }
    }

    private func album(_ layout: StageLayout) -> some View {
        ZStack {
            ClayColor.petWall
            VStack(spacing: 12) {
                HStack {
                    ClayIconButton(icon: .back, id: "picture-album-close", label: "返回探索") { showAlbum = false }
                    TitleRibbon(title: "我的图鉴 · \(progressStore.pictureWordsSeen.count) / 50", color: .green)
                    Spacer()
                }
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96 / layout.scale), spacing: 12)], spacing: 12) {
                        ForEach(PictureWords.all) { word in
                            let seen = progressStore.pictureWordsSeen.contains(word.id)
                            Button {
                                guard seen else { return }
                                showAlbum = false; category = word.category; scene = word.scene; discover(word)
                            } label: {
                                VStack(spacing: 4) {
                                    PictureWordArt(word: word, size: 68 / layout.scale, silhouette: !seen)
                                        .frame(height: 76 / layout.scale)
                                    Text(seen ? word.char : "待发现").font(ClayFont.label)
                                }
                                .foregroundStyle(ClayColor.statText)
                                .frame(maxWidth: .infinity, minHeight: 108 / layout.scale)
                                .background(ClayColor.creamTop, in: RoundedRectangle(cornerRadius: ClayRadius.card))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(ClayPressStyle())
                            .disabled(!seen)
                            .accessibilityLabel(seen ? "\(word.char)，已发现" : "\(word.category.name)，未发现")
                            .accessibilityIdentifier("picture-album-\(word.id)")
                        }
                    }
                    .padding(8)
                }
                .accessibilityIdentifier("picture-album-grid")
            }
            .padding(.leading, layout.safeArea.leading + 16).padding(.trailing, layout.safeArea.trailing + 16)
            .padding(.top, layout.safeArea.top + 16).padding(.bottom, layout.safeArea.bottom + 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("picture-album-screen")
        .environment(\.petAnimationsPaused, true)
        .accessibilityAddTraits(.isModal)
    }

    private func discover(_ word: PictureWord) {
        selected = word; bounce = false; tapSequence += 1
        progressStore.discoverPictureWord(word.id)
        HapticEngine.shared.tap()
        speak(word)
    }

    private func speak(_ word: PictureWord) {
        SpeechTextIndex.shared.register(word)
        AudioPlayer.shared.play(paths: word.chineseAudio.map(Optional.some))
    }

    private func changeCategory(_ value: PictureCategory) {
        category = value; changeScene(value.scenes[0])
    }

    private func changeScene(_ value: PictureScene) {
        AudioPlayer.shared.stop(); scene = value; selected = nil; bounce = false
    }

    private func stepScene(_ delta: Int) {
        guard category == .animals, let index = category.scenes.firstIndex(of: scene) else { return }
        let next = min(category.scenes.count - 1, max(0, index + delta))
        changeScene(category.scenes[next])
    }
}

struct PictureWordArt: View {
    let word: PictureWord
    let size: CGFloat
    var silhouette = false
    var body: some View {
        Group {
            switch word.art {
            case .clay(let kind):
                PetView(kind: kind, mood: .happy, size: size, accessory: .noAccessory)
            case .emoji(let emoji):
                Text(emoji).font(ClayFont.happy(size: size * 0.86))
            }
        }
        .compositingGroup()
        .brightness(silhouette ? -1 : 0)
        .opacity(silhouette ? 0.25 : 1)
        .accessibilityHidden(true)
    }
}
