import Foundation
import SwiftUI

/// 单个节点的运行态（已购买与等级）。
struct SkillNodeSave: Codable, Equatable {
    var owned: Bool = false
    var level: Int = 0   // 0..5
}

/// 整棵技能树的持久化数据。
struct SkillTreeSave: Codable {
    var nodes: [String: SkillNodeSave] = [:]
}

@MainActor
final class SkillTreeStore: ObservableObject {
    private let key = "PokerGame.SkillTree.v1"
    @Published private(set) var save: SkillTreeSave

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(SkillTreeSave.self, from: data) {
            self.save = decoded
        } else {
            self.save = SkillTreeSave()
            persist()
        }
    }

    // MARK: - 查询

    func node(_ id: String) -> SkillNodeSave {
        save.nodes[id] ?? SkillNodeSave()
    }

    func isOwned(_ id: String) -> Bool { node(id).owned }

    func level(_ id: String) -> Int { node(id).level }

    func currentSuccess(_ def: SkillNodeDef) -> Double {
        def.tier.baseSuccess + Double(level(def.id)) * 0.06
    }

    /// 计算节点当前在 UI 中应显示的状态。
    func unlockState(_ def: SkillNodeDef, wallet: Wallet) -> NodeUnlockState {
        let n = node(def.id)
        if n.owned { return .owned(level: n.level) }
        if def.tier == .t3 { return .lockedByTier }

        // 前置节点（任一即可）
        let prereqs = def.prerequisiteIds
        if !prereqs.isEmpty {
            let satisfied = prereqs.contains { isOwned($0) }
            if !satisfied {
                return .lockedByPrerequisite(missingIds: prereqs)
            }
        }

        // 时长门槛
        if wallet.totalPlayMinutes < def.tier.unlockMinutes {
            return .lockedByPlayTime(neededMinutes: def.tier.unlockMinutes)
        }

        // 金币
        if wallet.coins < def.tier.buyCost {
            return .insufficientCoins(price: def.tier.buyCost)
        }

        return .purchasable
    }

    /// 升到 (level+1) 级所需的「单次扣费」（差分成本）
    func nextUpgradeDelta(_ def: SkillNodeDef) -> Int? {
        let table = def.tier.upgradeCostPerLevel
        let lv = level(def.id)
        guard lv < table.count else { return nil }   // 已满级
        let prev = lv == 0 ? 0 : table[lv - 1]
        return table[lv] - prev
    }

    // MARK: - 操作

    /// 购买节点。返回是否成功。
    @discardableResult
    func purchase(_ def: SkillNodeDef, wallet: WalletStore) -> Bool {
        let state = unlockState(def, wallet: wallet.wallet)
        guard case .purchasable = state else { return false }
        guard wallet.spendCoins(def.tier.buyCost) else { return false }

        var n = node(def.id)
        n.owned = true
        n.level = 0
        save.nodes[def.id] = n
        persist()
        return true
    }

    /// 升级节点一级。返回是否成功。
    @discardableResult
    func upgrade(_ def: SkillNodeDef, wallet: WalletStore) -> Bool {
        var n = node(def.id)
        guard n.owned, def.tier != .t3 else { return false }
        guard let delta = nextUpgradeDelta(def) else { return false }
        guard wallet.wallet.coins >= delta else { return false }
        guard wallet.spendCoins(delta) else { return false }

        n.level += 1
        save.nodes[def.id] = n
        persist()
        return true
    }

    /// 开局加载：拿到所有已购节点的运行态信息。
    func loadedNodes() -> [LoadedNode] {
        SkillCatalog.all.compactMap { def in
            let n = node(def.id)
            guard n.owned else { return nil }
            return LoadedNode(
                id: def.id,
                name: def.name,
                school: def.school,
                effect: def.effect,
                cooldownTurns: def.cooldownTurns,
                successRate: def.tier.baseSuccess + Double(n.level) * 0.06,
                systemIcon: def.systemIcon,
                schoolLabel: def.school.label
            )
        }
    }

    // MARK: - 持久化

    private func persist() {
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 调试用：清空。
    func debugReset() {
        save = SkillTreeSave()
        persist()
    }
}

/// 进入对局时注入给 GameViewModel 的"已装载节点"快照。
struct LoadedNode: Identifiable, Equatable {
    let id: String
    let name: String
    let school: School
    let effect: SkillEffect
    let cooldownTurns: Int
    let successRate: Double      // 0..1
    let systemIcon: String
    let schoolLabel: String
}
