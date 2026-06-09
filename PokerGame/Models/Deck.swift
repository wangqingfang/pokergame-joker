import Foundation

struct Deck {
    private(set) var cards: [Card] = []

    init() { reset() }

    mutating func reset() {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(suit: suit, rank: $0) }
        }
        cards.shuffle()
    }

    mutating func draw() -> Card? {
        cards.isEmpty ? nil : cards.removeLast()
    }

    var isEmpty: Bool { cards.isEmpty }
}
