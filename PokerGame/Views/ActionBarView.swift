import SwiftUI

struct ActionBarView: View {
    @ObservedObject var vm: GameViewModel
    @State private var raiseAmount: Double = 40

    var body: some View {
        let toCall = vm.toCallForHuman
        let me = vm.players[0]
        let minRaise = max(vm.currentBet * 2, vm.bigBlind * 2)
        let maxRaise = me.chips + me.currentBet

        VStack(spacing: 8) {
            if maxRaise > minRaise {
                HStack {
                    Text("加注：\(Int(raiseAmount))")
                        .font(.caption)
                        .foregroundColor(.white)
                    Slider(value: $raiseAmount,
                           in: Double(minRaise)...Double(maxRaise),
                           step: Double(vm.bigBlind))
                }
                .padding(.horizontal)
            }
            HStack(spacing: 10) {
                Button {
                    vm.playerFold()
                } label: {
                    Text("弃牌").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!vm.humanIsActive)

                Button {
                    vm.playerCheckOrCall()
                } label: {
                    Text(toCall == 0 ? "过牌" : "跟注 \(toCall)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!vm.humanIsActive)

                Button {
                    vm.playerRaise(amount: Int(raiseAmount))
                } label: {
                    Text("加注").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!vm.humanIsActive || maxRaise <= minRaise)
            }
            .padding(.horizontal)
        }
        .onAppear {
            if raiseAmount < Double(minRaise) { raiseAmount = Double(minRaise) }
        }
    }
}
