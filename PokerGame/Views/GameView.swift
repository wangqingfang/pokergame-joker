import SwiftUI
import UIKit

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @State private var shakeProgress: CGFloat = 0

    var body: some View {
        ZStack {
            background
            mainLayout
            // 屏幕中央 + 玩家锚点的飘字
            fxOverlay
        }
        .modifier(ShakeEffect(amount: 6, animatableData: shakeProgress))
        .onChange(of: vm.screenShake) { _ in
            shakeProgress = 0
            withAnimation(.linear(duration: 0.4)) { shakeProgress = 1 }
        }
        .sheet(isPresented: $vm.showSettlement) {
            SettlementView(vm: vm)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled(vm.gameOver)
        }
    }

    private var mainLayout: some View {
        VStack(spacing: 8) {
            // AI 区域：横向 3 个
            HStack(spacing: 8) {
                ForEach(Array(vm.players.enumerated()).filter { $0.element.kind == .ai },
                        id: \.element.id) { idx, p in
                    PlayerView(
                        player: p,
                        isActive: vm.activeIndex == idx,
                        revealHole: vm.revealAll
                    ) { handleAITap(idx: idx) }
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 0)

            potArea

            // 状态提示
            if !vm.statusMessage.isEmpty {
                Text(vm.statusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.black.opacity(0.55))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            PlayerView(
                player: vm.players[0],
                isActive: vm.activeIndex == 0,
                revealHole: true
            ) { }

            SkillBarView(vm: vm)

            ActionBarView(vm: vm)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 8)
    }

    /// 改进点 2：底池信息高度凸显
    private var potArea: some View {
        VStack(spacing: 6) {
            // 大字号底池
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                Text("\(vm.pot)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.pot)
            }
            // 当前下注 / 你需跟
            HStack(spacing: 12) {
                badge(title: "当前下注", value: "\(vm.currentBet)", color: .orange)
                badge(title: "你需跟",
                      value: "\(vm.toCallForHuman)",
                      color: vm.toCallForHuman > 0 ? .red : .green)
                badge(title: "轮次", value: roundLabel, color: .cyan)
            }
            // 公共牌
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    if i < vm.community.count {
                        CardView(card: vm.community[i], faceUp: true)
                    } else {
                        CardView(card: nil, faceUp: false)
                            .opacity(0.25)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color.green.opacity(0.45),
                                              Color.green.opacity(0.20)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                )
        )
        .scaleEffect(potPulseScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.potPulse)
        .id("pot-\(vm.potPulse)")
    }

    private var potPulseScale: CGFloat { 1.0 }

    private func badge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 4).padding(.horizontal, 10)
        .background(
            Capsule().fill(Color.black.opacity(0.4))
        )
    }

    private var roundLabel: String {
        switch vm.round {
        case .preflop: return "翻前"
        case .flop: return "翻牌"
        case .turn: return "转牌"
        case .river: return "河牌"
        case .showdown: return "摊牌"
        }
    }

    /// 改进点 1：屏幕飘字特效层
    private var fxOverlay: some View {
        GeometryReader { geo in
            ForEach(vm.fxBubbles) { bubble in
                FXBubbleView(bubble: bubble)
                    .position(anchorPoint(for: bubble, in: geo.size))
            }
        }
        .allowsHitTesting(false)
    }

    private func anchorPoint(for bubble: FXBubble, in size: CGSize) -> CGPoint {
        guard let pi = bubble.playerIdx else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        // 玩家区固定在底部，AI 0/1/2 在上方等分
        if pi == 0 { return CGPoint(x: size.width / 2, y: size.height - 220) }
        let aiSlot = max(0, pi - 1)
        let cols: CGFloat = 3
        let x = size.width * (CGFloat(aiSlot) + 0.5) / cols
        return CGPoint(x: x, y: 110)
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
