import SwiftUI

/// 根容器：在主菜单与游戏页之间切换。
/// 入场费扣除、剩余筹码兑换钱包都在这里完成，避免 GameViewModel 直接依赖钱包逻辑。
struct RootView: View {
    @StateObject private var store = WalletStore()
    @StateObject private var tree = SkillTreeStore()
    @StateObject private var loadouts = LoadoutStore()
    @State private var inGame: Bool = false
    @State private var gameVM: GameViewModel?
    /// 玩家进入对局时的开始时间（用于累计游戏时长）
    @State private var matchStartedAt: Date?

    var body: some View {
        ZStack {
            if inGame, let vm = gameVM {
                GameView(vm: vm) { exitGame(vm: vm) }
                    .transition(.opacity)
            } else {
                MainMenuView(onStart: startGame)
                    .environmentObject(store)
                    .environmentObject(tree)
                    .environmentObject(loadouts)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut, value: inGame)
    }

    private func startGame() {
        // 入场费已在 LoadoutView 的"开始游戏"按钮中扣除
        let resolved = loadouts.resolveActive(ownedExtras: tree.loadedNodes())
        let vm = GameViewModel(loadout: resolved)
        gameVM = vm
        matchStartedAt = Date()
        inGame = true
    }

    private func exitGame(vm: GameViewModel) {
        // 兑换桌上剩余筹码回钱包
        store.settleMatch(remainingChips: vm.humanRemainingChips)
        // 累计游戏时长（分钟）
        if let started = matchStartedAt {
            let minutes = Int(Date().timeIntervalSince(started) / 60)
            store.addPlayMinutes(minutes)
        }
        gameVM = nil
        matchStartedAt = nil
        inGame = false
    }
}
