import SwiftUI

/// 数值来源：design/index.html 的组件 CSS；SVG 色标见下方 ClayGradient。
enum ClayColor {
    static func hex(_ value: UInt32) -> Color {
        Color(.sRGB, red: Double((value >> 16) & 255) / 255,
              green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
    static let creamTop = hex(0xFFFDF6), creamBottom = hex(0xFFF0D3), creamEdge = hex(0xF0D3A2)
    static let orange = hex(0xFF8A00), orangeDeep = hex(0xD66A00), orangeBright = hex(0xFFAE1F)
    static let ink = hex(0x3A2A1A), darkPill = hex(0x1A202C).opacity(0.78)
    static let outline = hex(0xE0700F), completed = hex(0x5FC23E), completedText = hex(0xFFE2A0)
    static let creamText = hex(0xC45A00), statText = hex(0x5A3A12), orangeTop = hex(0xFFB33B)
    static let ribbonGreenTop = hex(0x7BD655), ribbonGreenBottom = hex(0x45A82E), greenEdge = hex(0x2F7F24)
    static let ribbonBlueTop = hex(0x6FB2FF), ribbonBlueBottom = hex(0x3D8BF2), blueEdge = hex(0x2366C9)
    static let avatarTop = hex(0xFFF9EC), avatarBottom = hex(0xFFE7BC), avatarBorder = hex(0xFFA51F)
    static let levelTop = hex(0x5FB5FF), levelBottom = hex(0x2F7FE0)
    static let flame = hex(0xFF7A2E), flameCore = hex(0xFFD23F)

    // RD-03：art.js / screens.js 的场景色；与 SVG 原值对应。
    static let cubeInk = hex(0x0B4F5E)
    static let dockAnimalShadow = hex(0x173A2A)
    static let cubeDoneSide = hex(0x1F8EA6)
    static let dockAnimalEye = hex(0x2A2230)
    static let cubeShadow = hex(0x2C5E3A)
    static let treeShadow = hex(0x2D6B1F)
    static let trainIron = hex(0x3A3550)
    static let tuft = hex(0x4AA932)
    static let cubeCurrentSide = hex(0x4CC8DC)
    static let flowerStem = hex(0x4FAE34)
    static let cubeGameSide = hex(0x5140B8)
    static let butterflyBody = hex(0x5B3A2A)
    static let flowerLeaf = hex(0x5DBB3C)
    static let gameBadge = hex(0x7563E8)
    static let chestInside = hex(0x7B4420)
    static let cubeLockedInk = hex(0x7FAFB9)
    static let cubeLock = hex(0x8AAAB6)
    static let balloonString = hex(0x8B9AB0)
    static let woodDark = hex(0x8F5527)
    static let windowFrame = hex(0x9A5E2B)
    static let rail = hex(0x9C7A5C)
    static let cubeLockedSide = hex(0x9CC9D2)
    static let windowGlass = hex(0x9EDBF6)
    static let scrollInk = hex(0xB4352A)
    static let trainRoof = hex(0xB8392F)
    static let chestRim = hex(0xB87536)
    static let treeGrain = hex(0xB8763E)
    static let flowerLavender = hex(0xB89BFF)
    static let trainGlass = hex(0xBFEAFF)
    static let cloudShade = hex(0xC4E6FA)
    static let chimney = hex(0xC5703A)
    static let taskRule = hex(0xC9B9A0)
    static let roadEdge = hex(0xCFC4DE)
    static let balloonKnot = hex(0xD5443A)
    static let coinEdge = hex(0xD98A0B)
    static let hillHighlight = hex(0xE2FFB4)
    static let meadowFloor = hex(0x5BB733)
    static let skyTop = hex(0x5FCBF5)
    static let roadFace = hex(0xF1ECF7)
    static let mushroomRim = hex(0xF5D6B6)
    static let scrollPaper = hex(0xF8EBCB)
    static let dockAnimalBlush = hex(0xFF8597)
    static let giftLid = hex(0xFF8A7D)
    static let flowerPink = hex(0xFF8FB1)
    static let butterflyPink = hex(0xFF9AC1)
    static let bookPicture = hex(0xFFB3A7)
    static let bookStar = hex(0xFFC93C)
    static let windowLight = hex(0xFFE59A)
    static let dockAnimalWing = hex(0xFFE97A)
    static let coinEmblem = hex(0xFFF3B0)
    static let bookPage = hex(0xFFF3DA)
    static let starEdge = hex(0xE08A00)
    static let starOffEdge = hex(0xB9C3CF)
    static let starOffFace = hex(0xDCE3EC)
    static let trainNumber = hex(0x2B3A55)
    static let iconButtonDepth = hex(0x966428)
    static let goButtonDepth = hex(0xA03C00)
    static let white = Color.white, black = Color.black

    /// PET_ART 的实色与旧配饰色；渐变继续复用现有 p-* / g-* 令牌。
    enum Pet {
        static let ink = hex(0x2A2230), blush = hex(0xFF8597), mouth = hex(0xB93A4A), tongue = hex(0xFF8C93)
        static let ground = hex(0x173A2A), sprout = hex(0x4BA83A), bloom = hex(0xFFB3CF)
        static let foxTail = hex(0xFFF8F0), foxEar = hex(0xFFD0BE), foxFoot = hex(0xE37419)
        static let catEar = hex(0xFFC6C2), catNose = hex(0xFF8FA3), whisker = hex(0xB7A898)
        static let owlWing = hex(0x7D60D8), owlFeather = hex(0xC8B6F5), owlHat = hex(0x3A2F5C), tassel = hex(0xFFC93C)
        static let eggBlue = hex(0x8CC8FF), eggPink = hex(0xFFB3D1), eggGreen = hex(0x86D96A), crack = hex(0xC59C5E)
        static let duckWing = hex(0xFFE97A), pigFoot = hex(0xEC8BA1), snout = hex(0xFF9DB2), nostril = hex(0xB24E68)
        static let sheepLeg = hex(0x5B4A55), sheepEar = hex(0x6B5864), sheepFace = hex(0xFBE6D6)
        static let accessoryDark = hex(0x2E2E2E), cap = hex(0x1F1F1F), glasses = hex(0x4A3A2A), sunglasses = hex(0x22262B)
        static let gold = hex(0xFFC800), goldDark = hex(0xE0A800), jewel = hex(0xFF6B6B)
        static let party = hex(0xFF6B9D), partyStripe = hex(0xFFD166), partyBand = hex(0x4ECDC4)
        static let wizard = hex(0x7C3AED), wizardBrim = hex(0x5B21B6)
        static let helmetGlass = hex(0xBFE3F7), helmetRim = hex(0xDCE9F0)
        static let pirate = hex(0x1F2328), pirateBand = hex(0x8B0000)
        static let headphones = hex(0x1CB0F6), earcup = hex(0x1899D6)
        static let laurel = hex(0x4C9A2A), laurelLeaf = hex(0x6ABE30), bow = hex(0xE5484D), bowKnot = hex(0xB8353A)
    }
}

enum ClayRadius {
    static let button: CGFloat = 15, smallButton: CGFloat = 13, largeButton: CGFloat = 16
    static let card: CGFloat = 26, pictureCard: CGFloat = 28, ribbon: CGFloat = 14, bubble: CGFloat = 20
}

struct ClayShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
    /// art.js #f-sh
    static let scene = Self(color: ClayColor.hex(0x1D3B53).opacity(0.22), radius: 4, y: 4)
    static let icon = Self(color: ClayColor.hex(0x1E3246).opacity(0.2), radius: 6, y: 6)
    static let panel = Self(color: ClayColor.black.opacity(0.18), radius: 6, y: 6)
    static let orange = Self(color: ClayColor.hex(0xC85A00).opacity(0.3), radius: 6, y: 6)
    static let go = Self(color: ClayColor.hex(0xC85A00).opacity(0.35), radius: 7, y: 6)
    static let blueRibbon = Self(color: ClayColor.black.opacity(0.25), radius: 6, y: 6)
    static let bubble = Self(color: ClayColor.black.opacity(0.15), radius: 7, y: 6)
    static let stat = Self(color: ClayColor.hex(0x1E3C5A).opacity(0.15), radius: 5, y: 4)
}

extension View {
    func clayShadow(_ token: ClayShadow = .scene) -> some View {
        compositingGroup().shadow(color: token.color, radius: token.radius, x: 0, y: token.y)
    }
}

/// 全部 g-* / p-* 均逐项抄自 art.js DEFS，保留 offset、opacity、cx/cy/r。
/// SVG objectBoundingBox 径向渐变在非正方形中是椭圆：先在单位正方形绘制再分别缩放两轴。
enum ClayGradient: String, CaseIterable, Identifiable {
    case sky = "g-sky"
    case night = "g-night"
    case far = "g-far"
    case hill1 = "g-hill1"
    case hill2 = "g-hill2"
    case hill3 = "g-hill3"
    case canopy = "g-canopy"
    case canopy2 = "g-canopy2"
    case trunk = "g-trunk"
    case mush = "g-mush"
    case stem = "g-stem"
    case cubeF = "g-cubeF"
    case cubeL = "g-cubeL"
    case cubeG = "g-cubeG"
    case cubeC = "g-cubeC"
    case gold = "g-gold"
    case coral = "g-coral"
    case blue = "g-blue"
    case violet2 = "g-violet2"
    case green2 = "g-green2"
    case stone = "g-stone"
    case water = "g-water"
    case wood = "g-wood"
    case woodD = "g-woodD"
    case cream = "g-cream"
    case glow = "g-glow"
    case sunglow = "g-sunglow"
    case warmglow = "g-warmglow"
    case mt = "p-mt"
    case leaf = "p-leaf"
    case fox = "p-fox"
    case petCream = "p-cream"
    case white = "p-white"
    case caramel = "p-caramel"
    case navy = "p-navy"
    case orange = "p-orange"
    case violet = "p-violet"
    case mint = "p-mint"
    case lav = "p-lav"
    case egg = "p-egg"
    case pink = "p-pink"
    case yellow = "p-yellow"
    case red = "p-red"
    case buttonCream = "css-cream", buttonOrange = "css-orange"
    case ribbonGreen = "css-green", ribbonBlue = "css-blue"
    case avatar = "css-avatar", level = "css-level", go = "css-go"
    var id: String { rawValue }

    enum Geometry {
        case linear(end: UnitPoint)
        case radial(center: UnitPoint, radius: CGFloat)
    }
    var geometry: Geometry {
        switch self {
        case .sky: return .linear(end: UnitPoint(x: 0, y: 1))
        case .night: return .linear(end: UnitPoint(x: 0, y: 1))
        case .far: return .linear(end: UnitPoint(x: 0, y: 1))
        case .hill1: return .linear(end: UnitPoint(x: 0, y: 1))
        case .hill2: return .linear(end: UnitPoint(x: 0, y: 1))
        case .hill3: return .linear(end: UnitPoint(x: 0, y: 1))
        case .canopy: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .canopy2: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .trunk: return .linear(end: UnitPoint(x: 1, y: 0))
        case .mush: return .radial(center: UnitPoint(x: 0.4, y: 0.25), radius: 0.85)
        case .stem: return .linear(end: UnitPoint(x: 1, y: 0))
        case .cubeF: return .linear(end: UnitPoint(x: 0, y: 1))
        case .cubeL: return .linear(end: UnitPoint(x: 0, y: 1))
        case .cubeG: return .linear(end: UnitPoint(x: 0, y: 1))
        case .cubeC: return .linear(end: UnitPoint(x: 0, y: 1))
        case .gold: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .coral: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .blue: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .violet2: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .green2: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .stone: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .water: return .linear(end: UnitPoint(x: 0, y: 1))
        case .wood: return .linear(end: UnitPoint(x: 0, y: 1))
        case .woodD: return .linear(end: UnitPoint(x: 0, y: 1))
        case .cream: return .linear(end: UnitPoint(x: 0, y: 1))
        case .glow: return .radial(center: UnitPoint(x: 0.5, y: 0.5), radius: 0.5)
        case .sunglow: return .radial(center: UnitPoint(x: 0.5, y: 0.5), radius: 0.5)
        case .warmglow: return .radial(center: UnitPoint(x: 0.5, y: 0.5), radius: 0.5)
        case .mt: return .radial(center: UnitPoint(x: 0.4, y: 0.32), radius: 0.78)
        case .leaf: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .fox: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .petCream: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .white: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .caramel: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .navy: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .orange: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .violet: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .mint: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .lav: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .egg: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .pink: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .yellow: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .red: return .radial(center: UnitPoint(x: 0.38, y: 0.3), radius: 0.78)
        case .go: return .radial(center: UnitPoint(x: 0.35, y: 0.3), radius: sqrt(0.65 * 0.65 + 0.7 * 0.7))
        default: return .linear(end: UnitPoint(x: 0, y: 1))
        }
    }
    var stops: [Gradient.Stop] {
        switch self {
        case .sky: return [.init(color: ClayColor.hex(0x5FCBF5), location: 0), .init(color: ClayColor.hex(0x9DE2FA), location: 0.55), .init(color: ClayColor.hex(0xDDF6FF), location: 1)]
        case .night: return [.init(color: ClayColor.hex(0x14204A), location: 0), .init(color: ClayColor.hex(0x2A3B78), location: 0.6), .init(color: ClayColor.hex(0x41569A), location: 1)]
        case .far: return [.init(color: ClayColor.hex(0xA6E5CB), location: 0), .init(color: ClayColor.hex(0x6CC7A8), location: 1)]
        case .hill1: return [.init(color: ClayColor.hex(0xBDF074), location: 0), .init(color: ClayColor.hex(0x76CC3F), location: 1)]
        case .hill2: return [.init(color: ClayColor.hex(0x9BE35C), location: 0), .init(color: ClayColor.hex(0x5BB733), location: 1)]
        case .hill3: return [.init(color: ClayColor.hex(0x7FD04F), location: 0), .init(color: ClayColor.hex(0x48A22B), location: 1)]
        case .canopy: return [.init(color: ClayColor.hex(0xC2F584), location: 0), .init(color: ClayColor.hex(0x6FC946), location: 0.55), .init(color: ClayColor.hex(0x3F9C2B), location: 1)]
        case .canopy2: return [.init(color: ClayColor.hex(0x90DD63), location: 0), .init(color: ClayColor.hex(0x4FAE36), location: 0.6), .init(color: ClayColor.hex(0x2F7F24), location: 1)]
        case .trunk: return [.init(color: ClayColor.hex(0xDFA36B), location: 0), .init(color: ClayColor.hex(0xA8693A), location: 1)]
        case .mush: return [.init(color: ClayColor.hex(0xFFA594), location: 0), .init(color: ClayColor.hex(0xF45A44), location: 0.55), .init(color: ClayColor.hex(0xC4352A), location: 1)]
        case .stem: return [.init(color: ClayColor.hex(0xFFF9EE), location: 0), .init(color: ClayColor.hex(0xEBD0A6), location: 1)]
        case .cubeF: return [.init(color: ClayColor.hex(0x86E4EF), location: 0), .init(color: ClayColor.hex(0x33AEC7), location: 1)]
        case .cubeL: return [.init(color: ClayColor.hex(0xE4F6F8), location: 0), .init(color: ClayColor.hex(0xBFE1E7), location: 1)]
        case .cubeG: return [.init(color: ClayColor.hex(0xB4A8FF), location: 0), .init(color: ClayColor.hex(0x7563E8), location: 1)]
        case .cubeC: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xBDF4FB), location: 1)]
        case .gold: return [.init(color: ClayColor.hex(0xFFF6B8), location: 0), .init(color: ClayColor.hex(0xFFCD3C), location: 0.5), .init(color: ClayColor.hex(0xE2900A), location: 1)]
        case .coral: return [.init(color: ClayColor.hex(0xFFB9AB), location: 0), .init(color: ClayColor.hex(0xFF6F61), location: 0.6), .init(color: ClayColor.hex(0xD5443A), location: 1)]
        case .blue: return [.init(color: ClayColor.hex(0x9CD2FF), location: 0), .init(color: ClayColor.hex(0x3D8BF2), location: 0.6), .init(color: ClayColor.hex(0x2366C9), location: 1)]
        case .violet2: return [.init(color: ClayColor.hex(0xD9CCFF), location: 0), .init(color: ClayColor.hex(0x8F72F2), location: 0.6), .init(color: ClayColor.hex(0x6448CC), location: 1)]
        case .green2: return [.init(color: ClayColor.hex(0xC5F59B), location: 0), .init(color: ClayColor.hex(0x5FC23E), location: 0.6), .init(color: ClayColor.hex(0x3C9128), location: 1)]
        case .stone: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xECE8F2), location: 0.6), .init(color: ClayColor.hex(0xC5BED3), location: 1)]
        case .water: return [.init(color: ClayColor.hex(0x86DBF6), location: 0), .init(color: ClayColor.hex(0x3AA3DA), location: 1)]
        case .wood: return [.init(color: ClayColor.hex(0xF4BD7C), location: 0), .init(color: ClayColor.hex(0xC98443), location: 1)]
        case .woodD: return [.init(color: ClayColor.hex(0xC98443), location: 0), .init(color: ClayColor.hex(0x8F5527), location: 1)]
        case .cream: return [.init(color: ClayColor.hex(0xFFFDF7), location: 0), .init(color: ClayColor.hex(0xFFEFCF), location: 1)]
        case .glow: return [.init(color: ClayColor.hex(0xFFFFFF).opacity(0.95), location: 0), .init(color: ClayColor.hex(0xC4F7FF).opacity(0.6), location: 0.45), .init(color: ClayColor.hex(0xC4F7FF).opacity(0), location: 1)]
        case .sunglow: return [.init(color: ClayColor.hex(0xFFF6BE).opacity(0.95), location: 0), .init(color: ClayColor.hex(0xFFF6BE).opacity(0), location: 1)]
        case .warmglow: return [.init(color: ClayColor.hex(0xFFE58A).opacity(0.95), location: 0), .init(color: ClayColor.hex(0xFFE58A).opacity(0), location: 1)]
        case .mt: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xFFF6E3), location: 0.5), .init(color: ClayColor.hex(0xF4DCB3), location: 0.85), .init(color: ClayColor.hex(0xE3C08E), location: 1)]
        case .leaf: return [.init(color: ClayColor.hex(0xC9F58C), location: 0), .init(color: ClayColor.hex(0x6FCB45), location: 0.6), .init(color: ClayColor.hex(0x3E9B2C), location: 1)]
        case .fox: return [.init(color: ClayColor.hex(0xFFD7A0), location: 0), .init(color: ClayColor.hex(0xFF9A3C), location: 0.55), .init(color: ClayColor.hex(0xDE6814), location: 1)]
        case .petCream: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xFFF8EE), location: 0.7), .init(color: ClayColor.hex(0xEBDCC8), location: 1)]
        case .white: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xF6F2EC), location: 0.6), .init(color: ClayColor.hex(0xD9CEC0), location: 1)]
        case .caramel: return [.init(color: ClayColor.hex(0xFBD39E), location: 0), .init(color: ClayColor.hex(0xDD9548), location: 1)]
        case .navy: return [.init(color: ClayColor.hex(0x7E95C9), location: 0), .init(color: ClayColor.hex(0x3D5089), location: 0.55), .init(color: ClayColor.hex(0x253159), location: 1)]
        case .orange: return [.init(color: ClayColor.hex(0xFFD27A), location: 0), .init(color: ClayColor.hex(0xF08A12), location: 1)]
        case .violet: return [.init(color: ClayColor.hex(0xD8C8FF), location: 0), .init(color: ClayColor.hex(0x9D7EF2), location: 0.55), .init(color: ClayColor.hex(0x6B4FCB), location: 1)]
        case .mint: return [.init(color: ClayColor.hex(0xD7FDF2), location: 0), .init(color: ClayColor.hex(0x86DFC7), location: 0.55), .init(color: ClayColor.hex(0x3BB393), location: 1)]
        case .lav: return [.init(color: ClayColor.hex(0xF0E6FF), location: 0), .init(color: ClayColor.hex(0xB9A1F2), location: 1)]
        case .egg: return [.init(color: ClayColor.hex(0xFFFFFF), location: 0), .init(color: ClayColor.hex(0xFFF3D9), location: 0.6), .init(color: ClayColor.hex(0xE9CF9F), location: 1)]
        case .pink: return [.init(color: ClayColor.hex(0xFFE9EE), location: 0), .init(color: ClayColor.hex(0xFFB6C4), location: 0.55), .init(color: ClayColor.hex(0xEC8BA1), location: 1)]
        case .yellow: return [.init(color: ClayColor.hex(0xFFF8B5), location: 0), .init(color: ClayColor.hex(0xFFDA3E), location: 0.55), .init(color: ClayColor.hex(0xE7AA10), location: 1)]
        case .red: return [.init(color: ClayColor.hex(0xFF9F92), location: 0), .init(color: ClayColor.hex(0xF2463A), location: 0.6), .init(color: ClayColor.hex(0xB92A22), location: 1)]
        case .buttonCream: return [.init(color: ClayColor.creamTop, location: 0), .init(color: ClayColor.creamBottom, location: 1)]
        case .buttonOrange: return [.init(color: ClayColor.orangeTop, location: 0), .init(color: ClayColor.orange, location: 1)]
        case .ribbonGreen: return [.init(color: ClayColor.ribbonGreenTop, location: 0), .init(color: ClayColor.ribbonGreenBottom, location: 1)]
        case .ribbonBlue: return [.init(color: ClayColor.ribbonBlueTop, location: 0), .init(color: ClayColor.ribbonBlueBottom, location: 1)]
        case .avatar: return [.init(color: ClayColor.avatarTop, location: 0), .init(color: ClayColor.avatarBottom, location: 1)]
        case .level: return [.init(color: ClayColor.levelTop, location: 0), .init(color: ClayColor.levelBottom, location: 1)]
        case .go: return [.init(color: ClayColor.hex(0xFFD66B), location: 0), .init(color: ClayColor.hex(0xFF9A1F), location: 0.6), .init(color: ClayColor.hex(0xE8700A), location: 1)]
        }
    }

    var view: some View {
        GeometryReader { proxy in
            switch geometry {
            case .linear(let end):
                LinearGradient(stops: stops, startPoint: .topLeading, endPoint: end)
            case .radial(let center, let radius):
                RadialGradient(stops: stops, center: center, startRadius: 0, endRadius: radius)
                    .frame(width: 1, height: 1)
                    .scaleEffect(x: proxy.size.width, y: proxy.size.height, anchor: .topLeading)
            }
        }
        .clipped()
    }
}
