import Foundation

enum PictureCategory: String, CaseIterable, Identifiable {
    case animals, fruit, transport, body
    var id: String { rawValue }
    var name: String {
        switch self { case .animals: return "动物"; case .fruit: return "水果"
        case .transport: return "交通工具"; case .body: return "身体部位" }
    }
    var emoji: String {
        switch self { case .animals: return "🐑"; case .fruit: return "🍎"
        case .transport: return "🚗"; case .body: return "👋" }
    }
    var scenes: [PictureScene] {
        switch self { case .animals: return [.farm, .forest, .water]
        case .fruit: return [.orchard]; case .transport: return [.road]; case .body: return [.mirror] }
    }
}

enum PictureScene: String, CaseIterable, Identifiable {
    case farm, forest, water, orchard, road, mirror
    var id: String { rawValue }
    var name: String {
        switch self { case .farm: return "农场"; case .forest: return "森林"; case .water: return "水边"
        case .orchard: return "果园"; case .road: return "马路"; case .mirror: return "镜子房" }
    }
    var category: PictureCategory {
        switch self { case .farm, .forest, .water: return .animals
        case .orchard: return .fruit; case .road: return .transport; case .mirror: return .body }
    }
}

struct PictureWord: Identifiable, Equatable {
    enum Art: Equatable { case clay(PetKind), emoji(String) }
    let id: String
    let char: String
    let pinyin: String
    let english: String
    /// 常见叫声的文字拟声；不适合拟声的词条用短介绍，不当作真实动物录音。
    let sound: String
    let art: Art
    let scene: PictureScene
    var category: PictureCategory { scene.category }
    var nameAudio: String { "/audio/picture-words/\(id)-name.mp3" }
    var pinyinAudio: String { "/audio/picture-words/\(id)-pinyin.mp3" }
    var soundAudio: String { "/audio/picture-words/\(id)-sound.mp3" }
    var englishAudio: String { "/audio/picture-words/\(id)-english.mp3" }
    var chineseAudio: [String] { [nameAudio, pinyinAudio, soundAudio] }

    init(_ id: String, _ char: String, _ pinyin: String, _ english: String,
         _ sound: String, _ scene: PictureScene, _ art: Art) {
        self.id = id; self.char = char; self.pinyin = pinyin; self.english = english
        self.sound = sound; self.scene = scene; self.art = art
    }
}

/// RD-16 的完整词表。拼音按词标注，轻声不标调；英文名用单数。
/// 「猫头鹰」保留幼儿常用全名，是卡片 1–2 字约定的唯一例外，见 PR 疑问。
enum PictureWords {
    static let all: [PictureWord] = [
        .init("duck", "鸭", "yā", "duck", "嘎嘎，鸭子会游泳。", .farm, .clay(.duck)),
        .init("pig", "猪", "zhū", "pig", "哼哼，小猪用鼻子拱地。", .farm, .clay(.pig)),
        .init("sheep", "羊", "yáng", "sheep", "咩咩，羊毛软软的。", .farm, .clay(.sheep)),
        .init("cow", "牛", "niú", "cow", "哞哞，牛爱吃草。", .farm, .emoji("🐄")),
        .init("horse", "马", "mǎ", "horse", "咴咴，马儿跑得快。", .farm, .emoji("🐎")),
        .init("chicken", "鸡", "jī", "chicken", "咯咯，母鸡会下蛋。", .farm, .emoji("🐔")),
        .init("dog", "狗", "gǒu", "dog", "汪汪，小狗摇尾巴。", .farm, .emoji("🐕")),
        .init("cat", "猫", "māo", "cat", "喵喵，小猫有胡须。", .farm, .clay(.cat)),
        .init("fox", "狐狸", "hú li", "fox", "狐狸有一条蓬松的大尾巴。", .forest, .clay(.fox)),
        .init("owl", "猫头鹰", "māo tóu yīng", "owl", "咕咕，猫头鹰有一双大眼睛。", .forest, .clay(.owl)),
        .init("rabbit", "兔", "tù", "rabbit", "兔子的耳朵长长的。", .forest, .emoji("🐇")),
        .init("deer", "鹿", "lù", "deer", "小鹿的腿细细长长。", .forest, .emoji("🦌")),
        .init("tiger", "老虎", "lǎo hǔ", "tiger", "嗷呜，老虎身上有条纹。", .forest, .emoji("🐅")),
        .init("monkey", "猴", "hóu", "monkey", "猴子会爬树。", .forest, .emoji("🐒")),
        .init("squirrel", "松鼠", "sōng shǔ", "squirrel", "松鼠会用前爪抱着食物。", .forest, .emoji("🐿️")),
        .init("panda", "熊猫", "xióng māo", "panda", "熊猫爱吃竹子。", .forest, .emoji("🐼")),
        .init("penguin", "企鹅", "qǐ é", "penguin", "企鹅有翅膀，游泳很拿手。", .water, .clay(.penguin)),
        .init("fish", "鱼", "yú", "fish", "鱼用鳃呼吸，用鳍游泳。", .water, .emoji("🐟")),
        .init("frog", "青蛙", "qīng wā", "frog", "呱呱，青蛙会跳也会游泳。", .water, .emoji("🐸")),
        .init("turtle", "龟", "guī", "turtle", "龟的身上有硬硬的壳。", .water, .emoji("🐢")),
        .init("apple", "苹果", "píng guǒ", "apple", "苹果圆圆的。", .orchard, .emoji("🍎")),
        .init("banana", "香蕉", "xiāng jiāo", "banana", "香蕉弯弯的。", .orchard, .emoji("🍌")),
        .init("watermelon", "西瓜", "xī guā", "watermelon", "西瓜有厚厚的瓜皮。", .orchard, .emoji("🍉")),
        .init("grape", "葡萄", "pú tao", "grape", "葡萄一串一串地生长。", .orchard, .emoji("🍇")),
        .init("orange", "橙子", "chéng zi", "orange", "橙子的果皮有清香。", .orchard, .emoji("🍊")),
        .init("pear", "梨", "lí", "pear", "梨的果肉脆脆的。", .orchard, .emoji("🍐")),
        .init("peach", "桃子", "táo zi", "peach", "桃子里面有一颗硬核。", .orchard, .emoji("🍑")),
        .init("strawberry", "草莓", "cǎo méi", "strawberry", "草莓表面有许多小点点。", .orchard, .emoji("🍓")),
        .init("cherry", "樱桃", "yīng táo", "cherry", "樱桃小小的，里面有核。", .orchard, .emoji("🍒")),
        .init("lemon", "柠檬", "níng méng", "lemon", "柠檬尝起来酸酸的。", .orchard, .emoji("🍋")),
        .init("car", "汽车", "qì chē", "car", "汽车在马路上行驶。", .road, .emoji("🚗")),
        .init("train", "火车", "huǒ chē", "train", "火车沿着铁轨行驶。", .road, .emoji("🚂")),
        .init("plane", "飞机", "fēi jī", "airplane", "飞机在天空中飞行。", .road, .emoji("✈️")),
        .init("ship", "轮船", "lún chuán", "ship", "轮船在水上航行。", .road, .emoji("🚢")),
        .init("bus", "巴士", "bā shì", "bus", "巴士可以接送许多乘客。", .road, .emoji("🚌")),
        .init("truck", "卡车", "kǎ chē", "truck", "卡车可以运送货物。", .road, .emoji("🚚")),
        .init("bicycle", "单车", "dān chē", "bicycle", "单车也叫自行车，用脚蹬踏板。", .road, .emoji("🚲")),
        .init("subway", "地铁", "dì tiě", "subway", "地铁是城市里的轨道交通。", .road, .emoji("🚇")),
        .init("motorcycle", "摩托", "mó tuō", "motorcycle", "摩托车行驶时要戴好头盔。", .road, .emoji("🏍️")),
        .init("tram", "电车", "diàn chē", "tram", "有轨电车沿着轨道行驶。", .road, .emoji("🚋")),
        .init("eye", "眼睛", "yǎn jing", "eye", "眼睛帮助我们看世界。", .mirror, .emoji("👁️")),
        .init("ear", "耳朵", "ěr duo", "ear", "耳朵帮助我们听声音。", .mirror, .emoji("👂")),
        .init("nose", "鼻子", "bí zi", "nose", "鼻子帮助我们闻气味。", .mirror, .emoji("👃")),
        .init("mouth", "嘴", "zuǐ", "mouth", "嘴巴可以说话和吃东西。", .mirror, .emoji("👄")),
        .init("hand", "手", "shǒu", "hand", "小手可以握住东西。", .mirror, .emoji("✋")),
        .init("foot", "脚", "jiǎo", "foot", "双脚帮助我们站立和行走。", .mirror, .emoji("🦶")),
        .init("tooth", "牙齿", "yá chǐ", "tooth", "牙齿帮助我们嚼食物。", .mirror, .emoji("🦷")),
        .init("tongue", "舌头", "shé tou", "tongue", "舌头帮助我们尝味道。", .mirror, .emoji("👅")),
        .init("arm", "手臂", "shǒu bì", "arm", "手臂可以弯曲和伸直。", .mirror, .emoji("💪")),
        .init("leg", "腿", "tuǐ", "leg", "腿可以弯曲，帮助我们走路。", .mirror, .emoji("🦵")),
    ]

    static let ids = Set(all.map(\.id))
    static func word(_ id: String) -> PictureWord? { all.first { $0.id == id } }
    static func words(in scene: PictureScene) -> [PictureWord] { all.filter { $0.scene == scene } }
    static func seen(_ stored: [String]?) -> Set<String> { Set(stored ?? []).intersection(ids) }
}
