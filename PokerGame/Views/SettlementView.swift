import SwiftUI

struct SettlementView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(vm.gameOver ? "游戏结束" : "本手结算")
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
                                .foregroundColor(p.chips == 0 ? .red : .orange)
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

            // 改进点 5：游戏结束时只能选择重新开始
            HStack(spacing: 12) {
                if vm.gameOver {
                    Button {
                        vm.showSettlement = false
                        vm.newMatch()
                    } label: {
                        Label("重新开始", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button {
                        vm.continueNextHand()
                    } label: {
                        Label("下一手", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button {
                        vm.showSettlement = false
                        vm.newMatch()
                    } label: {
                        Label("重置牌局", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }
}
