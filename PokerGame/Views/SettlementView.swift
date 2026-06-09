import SwiftUI

struct SettlementView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("结算")
                .font(.title.bold())
            Text(vm.settlementText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.players) { p in
                        HStack {
                            Text(p.name).bold()
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(Array(p.holeCards.enumerated()), id: \.offset) { _, c in
                                    CardView(card: c, faceUp: !p.isFolded,
                                             size: CGSize(width: 30, height: 44))
                                }
                            }
                            Text("💰\(p.chips)")
                                .foregroundColor(.orange)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(vm.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption).foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .frame(maxHeight: 120)

            HStack {
                if !vm.gameOver {
                    Button("继续游戏") { vm.continueNextHand() }
                        .buttonStyle(.borderedProminent)
                }
                Button(vm.gameOver ? "重新开始" : "退出") {
                    vm.showSettlement = false
                    if vm.gameOver { vm.gameOver = false; vm.newMatch() }
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom)
        }
        .padding(.top)
    }
}
