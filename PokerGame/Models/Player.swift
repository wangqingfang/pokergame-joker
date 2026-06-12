import Foundation

enum AIPersonality: String, CaseIterable, Codable {
    case aggressive = "激进鬼"
    case conservative = "保守怪"
    case random = "玄学家"
    case troll = "搞怪精"

    /// 决定是否倾向加注
    var raiseBias: Double {
        switch self {
        case .aggressive: return 0.55
        case .conservative: return 0.15
        case .random: return 0.4
        case .troll: return 0.5
        }
    }

    var foldBias: Double {
        switch self {
        case .aggressive: return 0.05
        case .conservative: return 0.4
        case .random: return 0.25
        case .troll: return 0.2
        }
    }
}

enum PlayerKind: Codable { case human, ai }

enum LastAction: String, Codable {
    case none, check, call, raise, fold, allIn
    var label: String {
        switch self {
        case .none: return ""
        case .check: return "过牌"
        case .call: return "跟注"
        case .raise: return "加注"
        case .fold: return "弃牌"
        case .allIn: return "全下"
        }
    }
}

struct Player: Identifiable {
    let id: UUID = UUID()
    var name: String
    var kind: PlayerKind
    var personality: AIPersonality?
    var avatarAssetName: String   // 资产名（Assets.xcassets 中）
    var chips: Int
    var holeCards: [Card] = []
    var isFolded: Bool = false
    var isAllIn: Bool = false
    var currentBet: Int = 0       // 本轮已下注
    var lastAction: LastAction = .none
    var skills: [SkillState] = SkillKind.allCases.map { SkillState(kind: $0) }
    /// P2: 已装载的扩展技能节点（来自技能树），与基础 6 技能并列
    var extraNodes: [ExtraNodeState] = []
    /// P3: AI 流派人设（仅 AI 玩家有值）
    var school: School? = nil
    /// P3: AI 实际可用的基础技能子集（从 school.aiSkillPool 抽 2-3 个）
    var aiSkillPool: [SkillKind] = []
    var shielded: Bool = false
    var forcedCall: Bool = false  // 倒霉蛋效果
    var revealedByPeek: Card?     // 玩家偷看到的对手牌
}

/// 扩展技能节点的运行时状态
struct ExtraNodeState: Identifiable {
    let node: LoadedNode
    var cooldownLeft: Int = 0
    var id: String { node.id }
    var ready: Bool { cooldownLeft <= 0 }
}
