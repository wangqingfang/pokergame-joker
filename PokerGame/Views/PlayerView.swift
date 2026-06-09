import SwiftUI
import UIKit

struct PlayerView: View {
    let player: Player
    let isActive: Bool
    let revealHole: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                avatar
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(isActive ? Color.yellow : Color.white.opacity(0.4),
                                        lineWidth: isActive ? 3 : 1)
                    )
                if player.shielded {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.cyan)
                        .background(Color.black.opacity(0.4).clipShape(Circle()))
                }
            }
            Text(player.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
            Text("💰 \(player.chips)")
                .font(.caption2)
                .foregroundColor(.yellow)
            if player.currentBet > 0 {
                Text("下注 \(player.currentBet)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            if player.lastAction != .none {
                Text(player.lastAction.label)
                    .font(.caption2)
                    .foregroundColor(player.isFolded ? .gray : .green)
            }
            // 手牌
            HStack(spacing: 4) {
                ForEach(Array(player.holeCards.enumerated()), id: \.offset) { _, c in
                    CardView(card: c,
                             faceUp: revealHole || player.kind == .human,
                             size: CGSize(width: 36, height: 52))
                }
            }
            .opacity(player.isFolded ? 0.4 : 1.0)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var avatar: some View {
        if UIImage(named: player.avatarAssetName) != nil {
            Image(player.avatarAssetName).resizable().scaledToFill()
        } else {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(player.name.prefix(1)))
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
    }
}
