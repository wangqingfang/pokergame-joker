import SwiftUI

struct ActionBarView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showRaisePanel = false

    var body: some View {
        let toCall = vm.toCallForHuman
        let me = vm.players[0]

        VStack(spacing: 8) {
            // 加注快捷选项
            if showRaisePanel && vm.humanIsActive {
                raiseQuickPanel(me: me)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                Button { vm.playerFold() } label: {
                    Text("弃牌").font(.callout.bold()).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!vm.humanIsActive)

                Button { vm.playerCheckOrCall() } label: {
                    Text(toCall == 0 ? "过牌" : "跟注 \(toCall)")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!vm.humanIsActive)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRaisePanel.toggle()
                    }
                } label: {
                    Text(showRaisePanel ? "收起" : "加注 ▾")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!vm.humanIsActive || me.chips == 0)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func raiseQuickPanel(me: Player) -> some View {
        let myStack = me.chips + me.currentBet
        let bb = vm.bigBlind
        let cb = vm.currentBet
        let pot = vm.pot

        // 各种加注预设值
        let options: [(String, Int)] = [
            ("3 BB", bb * 3),
            ("3-bet", max(cb * 3, bb * 3)),
            ("4-bet", max(cb * 4, bb * 4)),
            ("半池", pot / 2),
            ("满池", pot),
            ("All-in", myStack)
        ]

        VStack(spacing: 6) {
            // 显示当前底池/筹码上下文
            HStack {
                Text("底池 \(pot) · 你 \(me.chips)")
                    .font(.caption2).foregroundColor(.white.opacity(0.85))
                Spacer()
                Text(cb > 0 ? "需跟 \(vm.toCallForHuman)" : "可过牌")
                    .font(.caption2).foregroundColor(.yellow)
            }
            .padding(.horizontal, 12)

            // 第一行：3BB / 3-bet / 4-bet
            HStack(spacing: 8) {
                ForEach(options.prefix(3), id: \.0) { item in
                    raiseChip(label: item.0, amount: item.1, myStack: myStack, isAllIn: false)
                }
            }
            // 第二行：半池 / 满池 / All-in
            HStack(spacing: 8) {
                ForEach(options.suffix(3), id: \.0) { item in
                    let isAll = item.0 == "All-in"
                    raiseChip(label: item.0, amount: item.1, myStack: myStack, isAllIn: isAll)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.55))
        )
        .padding(.horizontal)
    }

    private func raiseChip(label: String, amount: Int, myStack: Int, isAllIn: Bool) -> some View {
        let actual = min(max(amount, vm.bigBlind), myStack)
        let disabled = actual <= vm.currentBet || myStack <= 0
        return Button {
            if isAllIn {
                vm.playerAllIn()
            } else {
                vm.playerRaise(amount: actual)
            }
            withAnimation { showRaisePanel = false }
        } label: {
            VStack(spacing: 2) {
                Text(label).font(.caption.bold())
                Text("\(actual)").font(.system(size: 11)).foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isAllIn
                          ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                          : LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
            )
            .foregroundColor(.white)
            .opacity(disabled ? 0.35 : 1.0)
        }
        .disabled(disabled)
    }
}
