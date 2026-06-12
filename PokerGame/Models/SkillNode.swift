import Foundation
import SwiftUI

// MARK: - 流派 / 层级

enum School: String, Codable, CaseIterable, Identifiable {
    case brute, mage, guardian, trickster

    var id: String { rawValue }

    var label: String {
        switch self {
        case .brute: return "暴力"
        case .mage: return "智谋"
        case .guardian: return "守护"
        case .trickster: return "诡谲"
        }
    }

    var color: Color {
        switch self {
        case .brute: return .red
        case .mage: return .blue
        case .guardian: return .green
        case .trickster: return .purple
        }
    }

    var fxColorHex: UInt32 {
        switch self {
        case .brute: return 0xFF453A
        case .mage: return 0x0A84FF
        case .guardian: return 0x32D74B
        case .trickster: return 0xBF5AF2
        }
    }
}

enum SkillTier: Int, Codable, CaseIterable {
    case t1 = 1, t2 = 2, t3 = 3

    /// 基础成功率
    var baseSuccess: Double {
        switch self {
        case .t1: return 0.6
        case .t2: return 0.45
        case .t3: return 0.3
        }
    }

    /// 购买成本（金币）。T3 仅占位，P2 阶段不可购。
    var buyCost: Int {
        switch self {
        case .t1: return 800
        case .t2: return 3000
        case .t3: return 0
        }
    }

    /// 解锁所需累计游戏时长（分钟）。
    /// ⚠️ 测试期：T2 改为 2 分钟便于快速验证。正式版改回 120。
    var unlockMinutes: Int {
        switch self {
        case .t1: return 0
        case .t2: return 2
        case .t3: return Int.max  // 占位，P4 抽卡才解锁
        }
    }

    /// 升级累计成本表（升到 1/2/3/4/5 级所花的总金币）
    /// PRD-P2 §3：T1 200/400/800/1600/3200，T2 800/1600/3200/6400/12800
    var upgradeCostPerLevel: [Int] {
        switch self {
        case .t1: return [200, 400, 800, 1600, 3200]
        case .t2: return [800, 1600, 3200, 6400, 12800]
        case .t3: return []   // P2 不开放升级
        }
    }
}

// MARK: - 节点底层效果（复用既有 6 个 SkillKind 实现）

/// 节点底层效果分类——P2 阶段先全部映射到现有 SkillKind，
/// 描述会单独区分（比如"双偷看"在描述上提示 ×2，底层先用单次 peek 实现）。
enum SkillEffect: String, Codable {
    case forceCall          // backed by .unlucky
    case peek               // backed by .peek
    case chaosCommunity     // backed by .chaos
    case swapOwn            // backed by .swap
    case shield             // backed by .shield
    case meloning           // backed by .melon

    var backed: SkillKind {
        switch self {
        case .forceCall: return .unlucky
        case .peek: return .peek
        case .chaosCommunity: return .chaos
        case .swapOwn: return .swap
        case .shield: return .shield
        case .meloning: return .melon
        }
    }
}

// MARK: - 节点静态定义

struct SkillNodeDef: Identifiable, Codable {
    let id: String
    let name: String
    let school: School
    let tier: SkillTier
    let effect: SkillEffect
    let prerequisiteIds: [String]
    let description: String
    let systemIcon: String
}

extension SkillNodeDef {
    /// 牌局内冷却（沿用底层 SkillKind 设定）
    var cooldownTurns: Int { effect.backed.cooldownTurns }
}

// MARK: - 静态目录（4 流派 × 7 节点 = 28 个，T3 各 1 占位）

enum SkillCatalog {
    static let all: [SkillNodeDef] = brute + mage + guardian + trickster

    static func node(id: String) -> SkillNodeDef? {
        all.first { $0.id == id }
    }

    static func nodes(in school: School) -> [SkillNodeDef] {
        all.filter { $0.school == school }
    }

    // MARK: 暴力流（红 / Brute）
    private static let brute: [SkillNodeDef] = [
        // T1
        .init(id: "brute.t1.fist", name: "重拳", school: .brute, tier: .t1, effect: .forceCall,
              prerequisiteIds: [],
              description: "强势压制：指定一名对手下一轮必须跟注。",
              systemIcon: "hand.raised.fill"),
        .init(id: "brute.t1.stun", name: "震慑", school: .brute, tier: .t1, effect: .forceCall,
              prerequisiteIds: [],
              description: "气势汹汹：让目标无法弃牌，必须跟注一回合。",
              systemIcon: "bolt.fill"),
        .init(id: "brute.t1.taunt", name: "挑衅", school: .brute, tier: .t1, effect: .forceCall,
              prerequisiteIds: [],
              description: "嘴炮拉满：嘲讽目标必须跟注。",
              systemIcon: "flame.fill"),
        // T2
        .init(id: "brute.t2.combo", name: "连续重拳", school: .brute, tier: .t2, effect: .forceCall,
              prerequisiteIds: ["brute.t1.fist"],
              description: "连击：迫使目标连续两轮跟注（基于强制跟注实现）。",
              systemIcon: "figure.boxing"),
        .init(id: "brute.t2.doubleBlind", name: "全场翻倍盲", school: .brute, tier: .t2, effect: .chaosCommunity,
              prerequisiteIds: ["brute.t1.stun"],
              description: "搅局：随机重洗一张公共牌，制造混乱。",
              systemIcon: "arrow.up.arrow.down.circle.fill"),
        .init(id: "brute.t2.forceCall", name: "强制跟注", school: .brute, tier: .t2, effect: .forceCall,
              prerequisiteIds: ["brute.t1.taunt"],
              description: "钉死：所选目标的下一轮强制跟注，不允许弃牌。",
              systemIcon: "lock.fill"),
        // T3 占位
        .init(id: "brute.t3.shred", name: "撕牌", school: .brute, tier: .t3, effect: .forceCall,
              prerequisiteIds: ["brute.t2.combo", "brute.t2.forceCall"],
              description: "[P4 抽卡解锁] 撕碎对手底牌，强制重发。",
              systemIcon: "scissors")
    ]

    // MARK: 智谋流（蓝 / Mage）
    private static let mage: [SkillNodeDef] = [
        .init(id: "mage.t1.peek", name: "偷看", school: .mage, tier: .t1, effect: .peek,
              prerequisiteIds: [],
              description: "暗中窥探：偷看一名对手的一张底牌。",
              systemIcon: "eye"),
        .init(id: "mage.t1.swap", name: "换牌", school: .mage, tier: .t1, effect: .swapOwn,
              prerequisiteIds: [],
              description: "瞒天过海：替换自己一张手牌。",
              systemIcon: "arrow.triangle.2.circlepath"),
        .init(id: "mage.t1.mist", name: "迷雾", school: .mage, tier: .t1, effect: .chaosCommunity,
              prerequisiteIds: [],
              description: "扰乱视线：随机重洗一张公共牌。",
              systemIcon: "wind"),
        .init(id: "mage.t2.doublePeek", name: "双偷看", school: .mage, tier: .t2, effect: .peek,
              prerequisiteIds: ["mage.t1.peek"],
              description: "贪心偷看：连看对手两张（基于偷看实现）。",
              systemIcon: "eyes"),
        .init(id: "mage.t2.rewrite", name: "改公共牌", school: .mage, tier: .t2, effect: .chaosCommunity,
              prerequisiteIds: ["mage.t1.mist"],
              description: "改写命运：替换一张公共牌。",
              systemIcon: "wand.and.stars"),
        .init(id: "mage.t2.twist", name: "概率扭曲", school: .mage, tier: .t2, effect: .swapOwn,
              prerequisiteIds: ["mage.t1.swap"],
              description: "强行改运：替换自己一张手牌（高级换牌）。",
              systemIcon: "infinity.circle.fill"),
        .init(id: "mage.t3.master", name: "操控全场", school: .mage, tier: .t3, effect: .chaosCommunity,
              prerequisiteIds: ["mage.t2.doublePeek", "mage.t2.rewrite"],
              description: "[P4 抽卡解锁] 操控所有公共牌。",
              systemIcon: "globe.asia.australia.fill")
    ]

    // MARK: 守护流（绿 / Guardian）
    private static let guardian: [SkillNodeDef] = [
        .init(id: "guardian.t1.shield", name: "护盾", school: .guardian, tier: .t1, effect: .shield,
              prerequisiteIds: [],
              description: "结界：免疫下一次技能伤害。",
              systemIcon: "shield.lefthalf.filled"),
        .init(id: "guardian.t1.heal", name: "回血", school: .guardian, tier: .t1, effect: .shield,
              prerequisiteIds: [],
              description: "回血：开启护盾抵挡下一次伤害（治疗式守护）。",
              systemIcon: "cross.case.fill"),
        .init(id: "guardian.t1.reflect", name: "反弹", school: .guardian, tier: .t1, effect: .shield,
              prerequisiteIds: [],
              description: "反弹：抵挡下一次技能并反震发起者（基于护盾实现）。",
              systemIcon: "arrowshape.turn.up.backward.fill"),
        .init(id: "guardian.t2.doubleShield", name: "双护盾", school: .guardian, tier: .t2, effect: .shield,
              prerequisiteIds: ["guardian.t1.shield"],
              description: "双重护盾：连续抵挡两次（基于护盾叠加）。",
              systemIcon: "shield.checkered"),
        .init(id: "guardian.t2.teamBuff", name: "团队加持", school: .guardian, tier: .t2, effect: .shield,
              prerequisiteIds: ["guardian.t1.heal"],
              description: "守护光环：自身护盾，并附带气场。",
              systemIcon: "person.3.sequence.fill"),
        .init(id: "guardian.t2.refund", name: "入场费返还", school: .guardian, tier: .t2, effect: .shield,
              prerequisiteIds: ["guardian.t1.reflect"],
              description: "庇护：开启护盾并奖励本手抗伤判定。",
              systemIcon: "gift.circle.fill"),
        .init(id: "guardian.t3.immune", name: "免疫一手", school: .guardian, tier: .t3, effect: .shield,
              prerequisiteIds: ["guardian.t2.doubleShield", "guardian.t2.refund"],
              description: "[P4 抽卡解锁] 一整手免疫所有技能。",
              systemIcon: "checkmark.shield.fill")
    ]

    // MARK: 诡谲流（紫 / Trickster）
    private static let trickster: [SkillNodeDef] = [
        .init(id: "trick.t1.poison", name: "慢毒", school: .trickster, tier: .t1, effect: .forceCall,
              prerequisiteIds: [],
              description: "下毒：缓慢施压，强迫目标跟注。",
              systemIcon: "drop.degreesign.fill"),
        .init(id: "trick.t1.mark", name: "标记", school: .trickster, tier: .t1, effect: .peek,
              prerequisiteIds: [],
              description: "暗中标记：偷看一名对手的一张底牌。",
              systemIcon: "eye.trianglebadge.exclamationmark"),
        .init(id: "trick.t1.cloak", name: "隐身", school: .trickster, tier: .t1, effect: .shield,
              prerequisiteIds: [],
              description: "隐身：开启护盾躲避下次技能。",
              systemIcon: "person.fill.questionmark"),
        .init(id: "trick.t2.combo", name: "组合阴招", school: .trickster, tier: .t2, effect: .forceCall,
              prerequisiteIds: ["trick.t1.poison"],
              description: "阴招连击：强迫目标跟注并干扰节奏。",
              systemIcon: "tornado"),
        .init(id: "trick.t2.disguise", name: "伪装手牌", school: .trickster, tier: .t2, effect: .peek,
              prerequisiteIds: ["trick.t1.mark"],
              description: "伪装：偷看对手底牌并扰乱判读。",
              systemIcon: "theatermasks.fill"),
        .init(id: "trick.t2.markedCard", name: "记号牌", school: .trickster, tier: .t2, effect: .peek,
              prerequisiteIds: ["trick.t1.cloak"],
              description: "做记号：偷看对手并保持隐蔽。",
              systemIcon: "pencil.and.scribble"),
        .init(id: "trick.t3.swap", name: "偷天换日", school: .trickster, tier: .t3, effect: .peek,
              prerequisiteIds: ["trick.t2.combo", "trick.t2.disguise"],
              description: "[P4 抽卡解锁] 暗中调换对手与你的手牌。",
              systemIcon: "wand.and.rays")
    ]
}

// MARK: - 节点解锁状态

enum NodeUnlockState: Equatable {
    case owned(level: Int)
    case purchasable
    case lockedByPrerequisite(missingIds: [String])
    case lockedByPlayTime(neededMinutes: Int)
    case lockedByTier              // T3 占位
    case insufficientCoins(price: Int)

    var isOwned: Bool {
        if case .owned = self { return true }
        return false
    }
}
