import Foundation

// 7张牌取最佳5张的德州扑克牌型评估器
struct HandRank: Comparable, Equatable {
    enum Category: Int, Comparable {
        case highCard = 0, pair, twoPair, threeOfAKind, straight,
             flush, fullHouse, fourOfAKind, straightFlush, royalFlush

        var label: String {
            switch self {
            case .highCard: return "高牌"
            case .pair: return "一对"
            case .twoPair: return "两对"
            case .threeOfAKind: return "三条"
            case .straight: return "顺子"
            case .flush: return "同花"
            case .fullHouse: return "葫芦"
            case .fourOfAKind: return "四条"
            case .straightFlush: return "同花顺"
            case .royalFlush: return "皇家同花顺"
            }
        }

        static func < (l: Category, r: Category) -> Bool { l.rawValue < r.rawValue }
    }

    let category: Category
    let tiebreakers: [Int] // 高位优先

    static func < (l: HandRank, r: HandRank) -> Bool {
        if l.category != r.category { return l.category < r.category }
        for (a, b) in zip(l.tiebreakers, r.tiebreakers) where a != b { return a < b }
        return false
    }

    static func == (l: HandRank, r: HandRank) -> Bool {
        l.category == r.category && l.tiebreakers == r.tiebreakers
    }
}

enum HandEvaluator {

    static func evaluate(_ cards: [Card]) -> HandRank {
        precondition(cards.count >= 5)
        var best: HandRank?
        for combo in combinations(cards, choose: 5) {
            let r = evaluate5(combo)
            if best == nil || r > best! { best = r }
        }
        return best!
    }

    private static func evaluate5(_ five: [Card]) -> HandRank {
        let sorted = five.sorted { $0.rank > $1.rank }
        let ranks = sorted.map { $0.rank.rawValue }
        let suits = sorted.map { $0.suit }
        let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues { $0.count }
        // 排序：先按出现次数降序，再按 rank 降序
        let grouped = counts.sorted {
            if $0.value != $1.value { return $0.value > $1.value }
            return $0.key > $1.key
        }
        let countSeq = grouped.map { $0.value }
        let rankSeq = grouped.map { $0.key }

        let isFlush = Set(suits).count == 1
        let (isStraight, straightHigh) = checkStraight(ranks)

        if isFlush && isStraight {
            if straightHigh == 14 { return HandRank(category: .royalFlush, tiebreakers: [14]) }
            return HandRank(category: .straightFlush, tiebreakers: [straightHigh])
        }
        if countSeq == [4, 1] { return HandRank(category: .fourOfAKind, tiebreakers: rankSeq) }
        if countSeq == [3, 2] { return HandRank(category: .fullHouse, tiebreakers: rankSeq) }
        if isFlush { return HandRank(category: .flush, tiebreakers: ranks) }
        if isStraight { return HandRank(category: .straight, tiebreakers: [straightHigh]) }
        if countSeq == [3, 1, 1] { return HandRank(category: .threeOfAKind, tiebreakers: rankSeq) }
        if countSeq == [2, 2, 1] { return HandRank(category: .twoPair, tiebreakers: rankSeq) }
        if countSeq == [2, 1, 1, 1] { return HandRank(category: .pair, tiebreakers: rankSeq) }
        return HandRank(category: .highCard, tiebreakers: ranks)
    }

    private static func checkStraight(_ ranks: [Int]) -> (Bool, Int) {
        let unique = Array(Set(ranks)).sorted(by: >)
        guard unique.count == 5 else { return (false, 0) }
        if unique[0] - unique[4] == 4 { return (true, unique[0]) }
        // A-2-3-4-5
        if unique == [14, 5, 4, 3, 2] { return (true, 5) }
        return (false, 0)
    }

    private static func combinations<T>(_ arr: [T], choose k: Int) -> [[T]] {
        guard k > 0 else { return [[]] }
        guard arr.count >= k else { return [] }
        if arr.count == k { return [arr] }
        let first = arr[0]
        let rest = Array(arr.dropFirst())
        let with = combinations(rest, choose: k - 1).map { [first] + $0 }
        let without = combinations(rest, choose: k)
        return with + without
    }
}
