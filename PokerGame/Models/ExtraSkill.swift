import Foundation
import SwiftUI

/// P1 阶段的扩展技能（列表式商店，非树）。
/// 暂以 SkillKind 既有效果为载体，购买后追加到玩家技能栏。
enum ExtraSkillId: String, CaseIterable, Codable, Identifiable {
    case bruteFist     // 重拳：复用 unlucky 的"逼跟"作为打击效果
    case mageMist      // 迷雾：复用 chaos 的"扰乱公共牌"作为信息混淆
    case guardianHeal  // 回血：复用 shield 的"免疫一次"作为保护效果
    case tricksterMark // 标记：复用 peek 的"偷看"作为信息侦察

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bruteFist: return "重拳"
        case .mageMist: return "迷雾"
        case .guardianHeal: return "回血"
        case .tricksterMark: return "标记"
        }
    }

    var schoolLabel: String {
        switch self {
        case .bruteFist: return "暴力"
        case .mageMist: return "智谋"
        case .guardianHeal: return "守护"
        case .tricksterMark: return "诡谲"
        }
    }

    var schoolColor: Color {
        switch self {
        case .bruteFist: return .red
        case .mageMist: return .blue
        case .guardianHeal: return .green
        case .tricksterMark: return .purple
        }
    }

    var description: String {
        switch self {
        case .bruteFist: return "强势压制：指定一名对手下一轮必须跟注。"
        case .mageMist: return "扰乱视线：随机重洗一张公共牌。"
        case .guardianHeal: return "守护壁障：开启护盾，免疫下一次技能伤害。"
        case .tricksterMark: return "暗中标记：偷看一名对手的一张底牌。"
        }
    }

    var systemIcon: String {
        switch self {
        case .bruteFist: return "hand.raised.fill"
        case .mageMist: return "wind"
        case .guardianHeal: return "cross.case.fill"
        case .tricksterMark: return "eye.trianglebadge.exclamationmark"
        }
    }

    /// P1 统一定价（来自 PRD-P1 § 3）
    var price: Int { 800 }

    /// 牌局内映射到的现有 SkillKind 效果
    var backedBy: SkillKind {
        switch self {
        case .bruteFist: return .unlucky
        case .mageMist: return .chaos
        case .guardianHeal: return .shield
        case .tricksterMark: return .peek
        }
    }

    /// 牌局内的冷却（沿用底层 SkillKind 的设定）
    var cooldownTurns: Int { backedBy.cooldownTurns }
}
