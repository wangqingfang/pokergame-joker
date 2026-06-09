import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var store: WalletStore
    @State private var showShop = false
    @State private var showBailout = false
    /// 通过外部回调触发"开始一局"，由 RootView 决定是否进入 GameView
    var onStart: () -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 22) {
                // 顶部钱包条
                walletBar
                    .padding(.top, 8)

                Spacer()

                Text("无厘头德州扑克")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.6), radius: 6)

                Text("赢的钱攒着，输了肉疼，技能慢慢解锁。")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                VStack(spacing: 14) {
                    primaryButton
                    secondaryButton(title: "技能商店",
                                    systemImage: "bag.fill",
                                    color: .indigo) { showShop = true }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .sheet(isPresented: $showShop) {
            ShopView().environmentObject(store)
        }
        .sheet(isPresented: $showBailout) {
            BailoutView().environmentObject(store)
        }
    }

    private var primaryButton: some View {
        Button {
            tappedStart()
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("开始一局（入场 \(WalletStore.entryFee)）")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: store.canStartMatch()
                               ? [Color.orange, Color.red]
                               : [Color.gray.opacity(0.6)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!store.canStartMatch() && !store.bailoutAvailable())
    }

    private func secondaryButton(title: String, systemImage: String,
                                 color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.8))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func tappedStart() {
        if store.canStartMatch() {
            store.payEntry()
            onStart()
        } else {
            showBailout = true
        }
    }

    private var walletBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                Text("\(store.wallet.coins)").bold().foregroundColor(.yellow)
                    .contentTransition(.numericText())
                    .animation(.spring(), value: store.wallet.coins)
            }
            HStack(spacing: 4) {
                Image(systemName: "clock").foregroundColor(.cyan)
                Text(playTimeLabel).font(.caption).foregroundColor(.white)
            }
            Spacer()
            if store.wallet.coins < WalletStore.bailoutThreshold {
                Button { showBailout = true } label: {
                    Label("领取补给", systemImage: "gift.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.green.opacity(0.85)))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.45))
        )
        .padding(.horizontal, 16)
    }

    private var playTimeLabel: String {
        let m = store.wallet.totalPlayMinutes
        return m >= 60 ? "\(m / 60)h\(m % 60)m" : "\(m)m"
    }

    private var background: some View {
        LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.10),
                                Color(red: 0.0, green: 0.06, blue: 0.04)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
