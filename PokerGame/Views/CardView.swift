import SwiftUI

struct CardView: View {
    let card: Card?
    let faceUp: Bool
    var size: CGSize = CGSize(width: 56, height: 80)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(faceUp ? Color.white : Color.indigo)
                .shadow(radius: 2)
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)

            if faceUp, let c = card {
                VStack(spacing: 2) {
                    Text(c.rank.label)
                        .font(.system(size: size.height * 0.28, weight: .bold))
                    Text(c.suit.symbol)
                        .font(.system(size: size.height * 0.32))
                }
                .foregroundColor(c.suit.isRed ? .red : .black)
            } else {
                // 卡背图案
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.indigo.opacity(0.85))
                        .padding(4)
                    Image(systemName: "suit.club.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: size.height * 0.4))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
