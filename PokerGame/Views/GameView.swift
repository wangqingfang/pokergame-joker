import SwiftUI
import UIKit

struct GameView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            background
            VStack(spacing: 8) {
                // AI 区域：横向 3 个
                HStack(spacing: 8) {
                    ForEach(Array(vm.players.enumerated()).filter { $0.element.kind == .ai },
                            id: \.element.id) { idx, p in
                        PlayerView(
                            player: p,
                            isActive: vm.activeIndex == idx,
                            revealHole: vm.revealAll
                        ) {
                            handleAITap(idx: idx)
                        }
                    }
                }
                .padding(.top, 8)

                Spacer(minLength: 0)

                // 公共牌 + 底池
                VStack(spacing: 8) {
                    Text("底池：\(vm.pot)  ·  当前下注：\(vm.currentBet)")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    HStack(spacing: 6) {
                        ForEach(0..<5) { i in
                            if i < vm.community.count {
                                CardView(card: vm.community[i], faceUp: true)
                            } else {
                                CardView(card: nil, faceUp: false)
                                    .opacity(0.3)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.25))
                )

                // 状态提示
                if !vm.statusMessage.isEmpty {
                    Text(vm.statusMessage)
                        .font(.caption)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                // 玩家
                PlayerView(
                    player: vm.players[0],
                    isActive: vm.activeIndex == 0,
                    revealHole: true
                ) { }

                // 技能栏
                SkillBarView(vm: vm)

                // 操作栏
                ActionBarView(vm: vm)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $vm.showSettlement) {
            SettlementView(vm: vm)
                .presentationDetents([.medium])
        }
    }

    private func handleAITap(idx: Int) {
        guard let pending = vm.pendingSkill else { return }
        vm.playerCastSkill(pending, target: idx)
    }

    private var background: some View {
        Group {
            if UIImage(named: "Background") != nil {
                Image("Background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [Color(red: 0.05, green: 0.2, blue: 0.1),
                                        Color(red: 0.0, green: 0.1, blue: 0.05)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview { GameView() }
