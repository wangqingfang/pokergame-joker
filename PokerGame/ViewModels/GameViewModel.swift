import Foundation
import SwiftUI

enum BettingRound: Int { case preflop, flop, turn, river, showdown }

/// 屏幕上漂浮的特效气泡（打击感反馈）
struct FXBubble: Identifiable {
    let id = UUID()
    let text: String
    let colorHex: UInt32  // 用 hex 避免 SwiftUI Color 不可 Equatable 的麻烦
    let playerIdx: Int?   // nil = 屏幕中央
    let isBig: Bool       // 大字号 (技能 / All-in)
    var color: Color {
        Color(red: Double((colorHex >> 16) & 0xFF) / 255.0,
              green: Double((colorHex >> 8) & 0xFF) / 255.0,
              blue: Double(colorHex & 0xFF) / 255.0)
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Config
    let smallBlind = 10
    let bigBlind = 20
    let startingChips = 1000

    // MARK: - State
    @Published var players: [Player] = []
    @Published var community: [Card] = []
    @Published var pot: Int = 0
    @Published var currentBet: Int = 0
    @Published var round: BettingRound = .preflop
    @Published var activeIndex: Int = 0
    @Published var dealerIndex: Int = 0
    @Published var log: [String] = []
    @Published var showSettlement: Bool = false
    @Published var settlementText: String = ""
    @Published var revealAll: Bool = false
    @Published var pendingSkill: SkillKind?
    @Published var statusMessage: String = ""
    @Published var gameOver: Bool = false

    /// 屏幕飘字特效
    @Published var fxBubbles: [FXBubble] = []
    /// 当前下注/底池闪烁触发器（每次变动 +1）
    @Published var potPulse: Int = 0
    /// 全局震动 / 闪光 trigger
    @Published var screenShake: Int = 0

    private var deck = Deck()

    init() { newMatch() }

    // MARK: - 新对局
    func newMatch() {
        players = [
            Player(name: "你", kind: .human, personality: nil,
                   avatarAssetName: "PlayerAvatar", chips: startingChips),
            Player(name: "激进鬼", kind: .ai, personality: .aggressive,
                   avatarAssetName: "AI1", chips: startingChips),
            Player(name: "保守怪", kind: .ai, personality: .conservative,
                   avatarAssetName: "AI2", chips: startingChips),
            Player(name: "搞怪精", kind: .ai, personality: .troll,
                   avatarAssetName: "AI3", chips: startingChips)
        ]
        dealerIndex = 0
        gameOver = false
        startNewHand()
    }

    // MARK: - 新一手牌
    func startNewHand() {
        // 检查是否还能继续：必须至少 2 个有筹码的玩家
        guard players.filter({ $0.chips > 0 }).count > 1 else {
            gameOver = true
            settlementText = (players[0].chips > 0)
                ? "🎉 你赢得了所有筹码！"
                : "💀 你的筹码归零了\n\n再来一局？"
            showSettlement = true
            return
        }
        deck.reset()
        community.removeAll()
        pot = 0
        currentBet = 0
        round = .preflop
        revealAll = false
        log.removeAll()
        statusMessage = ""
        pendingSkill = nil
        fxBubbles.removeAll()

        for i in players.indices {
            players[i].holeCards.removeAll()
            players[i].isFolded = players[i].chips <= 0
            players[i].isAllIn = false
            players[i].currentBet = 0
            players[i].lastAction = .none
            players[i].shielded = false
            players[i].forcedCall = false
            players[i].revealedByPeek = nil
            // 改进点 4：每轮开始所有技能立即可用
            for j in players[i].skills.indices {
                players[i].skills[j].cooldownLeft = 0
            }
        }

        // 发底牌
        for _ in 0..<2 {
            for i in players.indices where !players[i].isFolded {
                if let c = deck.draw() { players[i].holeCards.append(c) }
            }
        }

        // 大小盲
        let sbIndex = nextActive(after: dealerIndex)
        let bbIndex = nextActive(after: sbIndex)
        postBlind(playerIndex: sbIndex, amount: smallBlind)
        postBlind(playerIndex: bbIndex, amount: bigBlind)
        currentBet = bigBlind
        activeIndex = nextActive(after: bbIndex)
        potPulse += 1

        appendLog("---- 新一手 ----")
        proceedIfAITurn()
    }

    private func postBlind(playerIndex: Int, amount: Int) {
        let pay = min(players[playerIndex].chips, amount)
        players[playerIndex].chips -= pay
        players[playerIndex].currentBet = pay
        pot += pay
        appendLog("\(players[playerIndex].name) 下盲注 \(pay)")
    }

    private func nextActive(after idx: Int) -> Int {
        var i = idx
        for _ in 0..<players.count {
            i = (i + 1) % players.count
            if !players[i].isFolded && !players[i].isAllIn { return i }
        }
        return idx
    }

    // MARK: - 玩家操作
    func playerCheckOrCall() {
        guard players[activeIndex].kind == .human else { return }
        let toCall = currentBet - players[activeIndex].currentBet
        if toCall == 0 { performAction(idx: activeIndex, action: .check) }
        else { performAction(idx: activeIndex, action: .call) }
    }

    func playerRaise(amount: Int) {
        guard players[activeIndex].kind == .human else { return }
        performAction(idx: activeIndex, action: .raise, raiseTo: amount)
    }

    func playerAllIn() {
        guard players[activeIndex].kind == .human else { return }
        let me = players[activeIndex]
        let target = me.chips + me.currentBet
        performAction(idx: activeIndex, action: .raise, raiseTo: target)
    }

    func playerFold() {
        guard players[activeIndex].kind == .human else { return }
        if players[activeIndex].forcedCall {
            statusMessage = "倒霉蛋效果：必须跟注，无法弃牌！"
            return
        }
        performAction(idx: activeIndex, action: .fold)
    }

    // MARK: - 下注动作
    private func performAction(idx: Int, action: LastAction, raiseTo: Int = 0) {
        var p = players[idx]
        switch action {
        case .check:
            p.lastAction = .check
            appendLog("\(p.name) 过牌")
            emitFX(text: "CHECK", colorHex: 0x7DF9FF, playerIdx: idx, big: false)
        case .call:
            let toCall = currentBet - p.currentBet
            let pay = min(toCall, p.chips)
            p.chips -= pay
            p.currentBet += pay
            pot += pay
            potPulse += 1
            if p.chips == 0 {
                p.isAllIn = true; p.lastAction = .allIn
                emitFX(text: "ALL-IN!", colorHex: 0xFF3B30, playerIdx: idx, big: true)
                screenShake += 1
            } else {
                p.lastAction = .call
                emitFX(text: "+\(pay)", colorHex: 0xFFD60A, playerIdx: idx, big: false)
            }
            appendLog("\(p.name) 跟注 \(pay)")
        case .raise:
            let target = max(currentBet * 2, raiseTo)
            let pay = min(target - p.currentBet, p.chips)
            p.chips -= pay
            p.currentBet += pay
            pot += pay
            potPulse += 1
            currentBet = max(currentBet, p.currentBet)
            if p.chips == 0 {
                p.isAllIn = true; p.lastAction = .allIn
                emitFX(text: "ALL-IN!", colorHex: 0xFF3B30, playerIdx: idx, big: true)
                screenShake += 1
            } else {
                p.lastAction = .raise
                emitFX(text: "RAISE +\(pay)", colorHex: 0xFF9500, playerIdx: idx, big: true)
                screenShake += 1
            }
            appendLog("\(p.name) 加注到 \(p.currentBet)")
        case .fold:
            p.isFolded = true
            p.lastAction = .fold
            appendLog("\(p.name) 弃牌")
            emitFX(text: "FOLD", colorHex: 0x8E8E93, playerIdx: idx, big: false)
        default: break
        }
        p.forcedCall = false
        players[idx] = p
        advanceTurn()
    }

    // MARK: - 推进
    private func advanceTurn() {
        let remaining = players.indices.filter { !players[$0].isFolded }
        if remaining.count == 1 {
            settle(winners: remaining, walkover: true)
            return
        }
        if isBettingRoundComplete() {
            advanceRound()
            return
        }
        activeIndex = nextActive(after: activeIndex)
        proceedIfAITurn()
    }

    private func isBettingRoundComplete() -> Bool {
        let active = players.indices.filter { !players[$0].isFolded && !players[$0].isAllIn }
        guard !active.isEmpty else { return true }
        let allMatched = active.allSatisfy { players[$0].currentBet == currentBet }
        let allActed = active.allSatisfy { players[$0].lastAction != .none }
        return allMatched && allActed
    }

    private func advanceRound() {
        for i in players.indices {
            players[i].currentBet = 0
            if !players[i].isFolded && !players[i].isAllIn { players[i].lastAction = .none }
        }
        currentBet = 0
        switch round {
        case .preflop:
            round = .flop
            for _ in 0..<3 { if let c = deck.draw() { community.append(c) } }
            appendLog("【翻牌】" + community.map { $0.id }.joined(separator: " "))
            emitFX(text: "FLOP", colorHex: 0x32D74B, playerIdx: nil, big: true)
        case .flop:
            round = .turn
            if let c = deck.draw() { community.append(c) }
            appendLog("【转牌】" + community.last!.id)
            emitFX(text: "TURN", colorHex: 0x32D74B, playerIdx: nil, big: true)
        case .turn:
            round = .river
            if let c = deck.draw() { community.append(c) }
            appendLog("【河牌】" + community.last!.id)
            emitFX(text: "RIVER", colorHex: 0x32D74B, playerIdx: nil, big: true)
        case .river:
            round = .showdown
            doShowdown()
            return
        case .showdown: return
        }
        activeIndex = nextActive(after: dealerIndex)
        proceedIfAITurn()
    }

    private func doShowdown() {
        revealAll = true
        let contenders = players.indices.filter { !players[$0].isFolded }
        var bestRank: HandRank?
        var winners: [Int] = []
        for i in contenders {
            let r = HandEvaluator.evaluate(players[i].holeCards + community)
            if bestRank == nil || r > bestRank! {
                bestRank = r
                winners = [i]
            } else if let b = bestRank, r == b {
                winners.append(i)
            }
        }
        settle(winners: winners, walkover: false, rank: bestRank)
    }

    private func settle(winners: [Int], walkover: Bool, rank: HandRank? = nil) {
        let share = pot / max(winners.count, 1)
        for i in winners { players[i].chips += share }
        let names = winners.map { players[$0].name }.joined(separator: "、")
        if walkover {
            settlementText = "🏆 \(names) 赢得 \(pot) 筹码（其他人都弃牌了）"
        } else {
            settlementText = "🏆 \(names) 凭【\(rank?.category.label ?? "?")】赢得 \(pot) 筹码"
        }
        appendLog(settlementText)
        showSettlement = true
        revealAll = true
        for w in winners {
            emitFX(text: "WIN! +\(share)", colorHex: 0xFFD60A, playerIdx: w, big: true)
        }
    }

    func continueNextHand() {
        showSettlement = false
        dealerIndex = (dealerIndex + 1) % players.count
        startNewHand()
    }

    // MARK: - AI
    private func proceedIfAITurn() {
        guard !showSettlement, !gameOver else { return }
        guard players[activeIndex].kind == .ai else { return }
        let myIdx = activeIndex
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run { self?.aiAct(idx: myIdx) }
        }
    }

    private func aiAct(idx: Int) {
        guard activeIndex == idx else { return }
        let p = players[idx]
        guard !p.isFolded, !p.isAllIn else { advanceTurn(); return }
        let personality = p.personality ?? .random
        let toCall = currentBet - p.currentBet
        let strength = aiHandStrength(player: p)
        let r = Double.random(in: 0...1)

        if p.forcedCall && toCall > 0 {
            performAction(idx: idx, action: .call); return
        }
        if maybeAICastSkill(idx: idx) { advanceTurn(); return }

        if toCall == 0 {
            if r < personality.raiseBias && strength > 0.4 {
                performAction(idx: idx, action: .raise, raiseTo: max(bigBlind * 2, currentBet * 2))
            } else {
                performAction(idx: idx, action: .check)
            }
        } else {
            let foldChance = personality.foldBias + (toCall > p.chips / 4 ? 0.2 : 0) - strength * 0.3
            if r < foldChance && strength < 0.3 && !p.forcedCall {
                performAction(idx: idx, action: .fold)
            } else if r < personality.raiseBias && strength > 0.55 {
                performAction(idx: idx, action: .raise, raiseTo: currentBet * 2)
            } else {
                performAction(idx: idx, action: .call)
            }
        }
    }

    private func aiHandStrength(player p: Player) -> Double {
        if community.isEmpty {
            let ranks = p.holeCards.map { $0.rank.rawValue }
            let high = Double(ranks.max() ?? 2) / 14.0
            let pair = ranks.count == 2 && ranks[0] == ranks[1] ? 0.4 : 0
            return min(1.0, high * 0.7 + pair)
        }
        let r = HandEvaluator.evaluate(p.holeCards + community)
        return min(1.0, Double(r.category.rawValue) / 9.0 + 0.1)
    }

    private func maybeAICastSkill(idx: Int) -> Bool {
        guard Double.random(in: 0...1) < 0.15 else { return false }
        let ready = players[idx].skills.filter { $0.ready }
        guard let pick = ready.randomElement() else { return false }
        switch pick.kind {
        case .shield:
            applyShield(to: idx)
        case .peek:
            let opponents = players.indices.filter { $0 != idx && !players[$0].isFolded }
            guard let target = opponents.randomElement() else { return false }
            if players[target].shielded {
                players[target].shielded = false
                appendLog("\(players[idx].name) 想偷看，被 \(players[target].name) 的护盾挡住了")
            } else {
                appendLog("\(players[idx].name) 偷看了 \(players[target].name) 一张底牌")
            }
        case .unlucky:
            let opponents = players.indices.filter { $0 != idx && !players[$0].isFolded }
            guard let target = opponents.randomElement() else { return false }
            if players[target].shielded { players[target].shielded = false }
            else { players[target].forcedCall = true }
            appendLog("\(players[idx].name) 对 \(players[target].name) 释放【倒霉蛋】")
        case .chaos:
            guard !community.isEmpty else { return false }
            let ci = Int.random(in: 0..<community.count)
            if let c = deck.draw() {
                appendLog("\(players[idx].name) 把公共牌 \(community[ci].id) 换成 \(c.id)")
                community[ci] = c
            }
        case .swap:
            guard let c = deck.draw() else { return false }
            let hi = Int.random(in: 0..<players[idx].holeCards.count)
            players[idx].holeCards[hi] = c
            appendLog("\(players[idx].name) 使用了【换牌术】")
        case .melon:
            guard let c = deck.draw() else { return false }
            let worstIdx = players[idx].holeCards.indices.min { players[idx].holeCards[$0].rank < players[idx].holeCards[$1].rank } ?? 0
            players[idx].holeCards[worstIdx] = c
            appendLog("\(players[idx].name) 使用了【吃瓜】")
        }
        markSkillCooldown(playerIdx: idx, kind: pick.kind)
        emitFX(text: "【\(pick.kind.name)】", colorHex: 0xBF5AF2, playerIdx: idx, big: true)
        screenShake += 1
        return false
    }

    // MARK: - 玩家技能
    func playerCastSkill(_ kind: SkillKind, target: Int? = nil, ownCardIndex: Int? = nil) {
        let me = 0
        guard let si = players[me].skills.firstIndex(where: { $0.kind == kind }) else { return }
        guard players[me].skills[si].ready else {
            statusMessage = "技能冷却中"; return
        }
        switch kind {
        case .shield:
            applyShield(to: me)
        case .peek:
            guard let t = target, !players[t].isFolded else {
                statusMessage = "请选择有效的对手"; return
            }
            if players[t].shielded {
                players[t].shielded = false
                statusMessage = "被对方护盾挡住了"
            } else {
                let c = players[t].holeCards.randomElement()
                players[me].revealedByPeek = c
                statusMessage = "你偷看到 \(players[t].name) 的底牌：\(c?.id ?? "?")"
            }
        case .unlucky:
            guard let t = target, !players[t].isFolded else {
                statusMessage = "请选择对手"; return
            }
            if players[t].shielded { players[t].shielded = false; statusMessage = "被护盾抵消" }
            else { players[t].forcedCall = true; statusMessage = "\(players[t].name) 下一轮必须跟注" }
        case .chaos:
            guard !community.isEmpty else {
                statusMessage = "需要先翻出公共牌"; return
            }
            let ci = Int.random(in: 0..<community.count)
            if let c = deck.draw() { community[ci] = c; statusMessage = "公共牌已被搅乱" }
        case .swap:
            guard let oc = ownCardIndex, oc < players[me].holeCards.count, let c = deck.draw() else {
                statusMessage = "牌堆已空"; return
            }
            players[me].holeCards[oc] = c
            statusMessage = "已换牌"
        case .melon:
            guard let c = deck.draw() else { statusMessage = "牌堆已空"; return }
            let worstIdx = players[me].holeCards.indices.min { players[me].holeCards[$0].rank < players[me].holeCards[$1].rank } ?? 0
            players[me].holeCards[worstIdx] = c
            statusMessage = "已替换最差的一张"
        }
        markSkillCooldown(playerIdx: me, kind: kind)
        appendLog("你 释放了【\(kind.name)】")
        emitFX(text: "【\(kind.name)】", colorHex: 0xBF5AF2, playerIdx: me, big: true)
        screenShake += 1
        pendingSkill = nil
    }

    private func applyShield(to idx: Int) {
        players[idx].shielded = true
        appendLog("\(players[idx].name) 开启了护盾")
    }

    private func markSkillCooldown(playerIdx: Int, kind: SkillKind) {
        guard let si = players[playerIdx].skills.firstIndex(where: { $0.kind == kind }) else { return }
        players[playerIdx].skills[si].cooldownLeft = kind.cooldownTurns
    }

    // MARK: - 特效
    func emitFX(text: String, colorHex: UInt32, playerIdx: Int?, big: Bool) {
        let bubble = FXBubble(text: text, colorHex: colorHex, playerIdx: playerIdx, isBig: big)
        fxBubbles.append(bubble)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                self?.fxBubbles.removeAll { $0.id == bubble.id }
            }
        }
    }

    // MARK: - 工具
    private func appendLog(_ s: String) {
        log.append(s)
        if log.count > 80 { log.removeFirst(log.count - 80) }
    }

    var humanIsActive: Bool { players[activeIndex].kind == .human && !showSettlement }
    var toCallForHuman: Int { max(0, currentBet - players[0].currentBet) }
}
