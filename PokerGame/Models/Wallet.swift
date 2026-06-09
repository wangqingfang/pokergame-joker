import Foundation
import SwiftUI

/// 玩家钱包（跨局持久化）
struct Wallet: Codable {
    var coins: Int = 2000
    var totalPlayMinutes: Int = 0
    var lastBailoutAt: Date? = nil
    var bailoutCount: Int = 0
    var ownedExtraSkillIds: [String] = []
}

@MainActor
final class WalletStore: ObservableObject {
    private let key = "PokerGame.Wallet.v1"
    @Published private(set) var wallet: Wallet

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Wallet.self, from: data) {
            self.wallet = decoded
        } else {
            self.wallet = Wallet()
            persist()
        }
    }

    // MARK: - 数值规格 (来自 PRD-P1)
    static let entryFee: Int = 500
    static let entryChipsRatio: Int = 2          // 500 金币 -> 1000 筹码
    static let entryChips: Int = entryFee * entryChipsRatio
    static let bailoutAmount: Int = 1500
    static let bailoutThreshold: Int = entryFee  // < 500 触发补给

    /// 第 N 次补给的冷却（秒）。
    /// ⚠️ 测试期：前 3 次 4 秒，之后 24 秒（便于回归补给流程）。
    /// 发布正式版前改回：`count < 3 ? 4 * 3600 : 24 * 3600`
    static func bailoutCooldown(forCount count: Int) -> TimeInterval {
        count < 3 ? 4 : 24
    }

    // MARK: - 操作
    func canStartMatch() -> Bool { wallet.coins >= Self.entryFee }

    func payEntry() {
        guard canStartMatch() else { return }
        wallet.coins -= Self.entryFee
        persist()
    }

    /// 比赛结束时把桌上剩余筹码按 2:1 兑换回钱包。
    func settleMatch(remainingChips: Int) {
        let gain = remainingChips / Self.entryChipsRatio
        wallet.coins += gain
        persist()
    }

    func addPlayMinutes(_ minutes: Int) {
        guard minutes > 0 else { return }
        wallet.totalPlayMinutes += minutes
        persist()
    }

    func purchaseExtraSkill(_ id: String, price: Int) -> Bool {
        guard wallet.coins >= price else { return false }
        guard !wallet.ownedExtraSkillIds.contains(id) else { return false }
        wallet.coins -= price
        wallet.ownedExtraSkillIds.append(id)
        persist()
        return true
    }

    // MARK: - 补给
    /// 当前是否可领补给（钱包不够开局，且冷却已到）。
    func bailoutAvailable() -> Bool {
        guard wallet.coins < Self.bailoutThreshold else { return false }
        return remainingBailoutCooldown() <= 0
    }

    /// 距下次可补给剩余秒数（≤ 0 表示可领）。
    func remainingBailoutCooldown() -> TimeInterval {
        guard let last = wallet.lastBailoutAt else { return 0 }
        let cd = Self.bailoutCooldown(forCount: wallet.bailoutCount)
        return max(0, last.addingTimeInterval(cd).timeIntervalSinceNow)
    }

    func claimBailout() {
        guard wallet.coins < Self.bailoutThreshold else { return }
        guard remainingBailoutCooldown() <= 0 else { return }
        wallet.coins += Self.bailoutAmount
        wallet.bailoutCount += 1
        wallet.lastBailoutAt = Date()
        persist()
    }

    // MARK: - 持久化
    private func persist() {
        if let data = try? JSONEncoder().encode(wallet) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 仅供调试：重置钱包。
    func debugReset() {
        wallet = Wallet()
        persist()
    }
}
