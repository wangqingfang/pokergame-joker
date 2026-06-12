import SwiftUI

struct BailoutView: View {
    @EnvironmentObject var store: WalletStore
    @Environment(\.dismiss) private var dismiss
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.top, 36)

            Text("筹码补给站")
                .font(.title.bold())

            VStack(spacing: 6) {
                Text("当前钱包：\(store.wallet.coins) 金币")
                    .foregroundColor(.yellow)
                Text("低于 \(WalletStore.bailoutThreshold) 金币，无法继续开局")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider().padding(.horizontal, 40)

            content
                .padding(.horizontal, 24)

            Spacer()

            Button("返回主菜单") { dismiss() }
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.04, green: 0.12, blue: 0.07),
                                    Color(red: 0.0, green: 0.05, blue: 0.03)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .foregroundColor(.white)
        .onReceive(timer) { _ in now = Date() }
    }

    @ViewBuilder
    private var content: some View {
        let remaining = store.remainingBailoutCooldown()
        if store.wallet.coins >= WalletStore.bailoutThreshold {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("钱包还够开局，无需补给。")
            }
        } else if remaining <= 0 {
            VStack(spacing: 12) {
                Text("可以领取 \(WalletStore.bailoutAmount) 金币")
                    .font(.title3.bold())
                    .foregroundColor(.green)
                Text(cooldownHint)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Button {
                    store.claimBailout()
                    dismiss()
                } label: {
                    Label("领取 \(WalletStore.bailoutAmount) 金币", systemImage: "gift.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.green, .teal],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        } else {
            VStack(spacing: 12) {
                Text("下次可领取还需")
                    .foregroundColor(.white.opacity(0.8))
                Text(formatCountdown(remaining))
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                Text(cooldownHint)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var cooldownHint: String {
        let n = store.wallet.bailoutCount
        // ⚠️ 测试期文案；发布正式版改回小时
        if n < 3 {
            return "已补给 \(n) 次。【测试模式】前 3 次冷却 4 秒，第 4 次起 24 秒。"
        } else {
            return "已补给 \(n) 次。【测试模式】当前冷却 24 秒。"
        }
    }

    private func formatCountdown(_ s: TimeInterval) -> String {
        let total = Int(s)
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}
