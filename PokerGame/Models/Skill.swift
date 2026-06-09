import Foundation

enum SkillKind: String, CaseIterable, Codable, Identifiable {
    case swap        // 换牌术
    case peek        // 偷看
    case unlucky     // 倒霉蛋
    case chaos       // 混乱
    case shield      // 护盾
    case melon       // 吃瓜

    var id: String { rawValue }

    var name: String {
        switch self {
        case .swap: return "换牌术"
        case .peek: return "偷看"
        case .unlucky: return "倒霉蛋"
        case .chaos: return "混乱"
        case .shield: return "护盾"
        case .melon: return "吃瓜"
        }
    }

    var description: String {
        switch self {
        case .swap: return "强制交换自己一张手牌"
        case .peek: return "偷看对手一张底牌"
        case .unlucky: return "对手下一轮必须跟注"
        case .chaos: return "随机重洗一张公共牌"
        case .shield: return "免疫一次技能攻击"
        case .melon: return "摸一张替换最差的手牌"
        }
    }

    /// 系统图标名（SF Symbols 占位，若有 PNG 资源再替换）
    var systemIcon: String {
        switch self {
        case .swap: return "arrow.triangle.2.circlepath"
        case .peek: return "eye"
        case .unlucky: return "exclamationmark.triangle"
        case .chaos: return "tornado"
        case .shield: return "shield.lefthalf.filled"
        case .melon: return "leaf"
        }
    }

    var cooldownTurns: Int {
        switch self {
        case .swap: return 3
        case .peek: return 2
        case .unlucky: return 4
        case .chaos: return 4
        case .shield: return 3
        case .melon: return 3
        }
    }
}

struct SkillState: Identifiable, Codable {
    let kind: SkillKind
    var cooldownLeft: Int = 0
    var id: String { kind.rawValue }
    var ready: Bool { cooldownLeft <= 0 }
}
