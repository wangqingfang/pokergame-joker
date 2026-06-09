import SwiftUI

struct SkillBarView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        let me = vm.players[0]
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(me.skills) { s in
                    Button {
                        handleTap(s)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: s.kind.systemIcon)
                                .font(.title3)
                                .foregroundColor(s.ready ? .white : .gray)
                            Text(s.kind.name)
                                .font(.caption2)
                                .foregroundColor(.white)
                            if !s.ready {
                                Text("CD\(s.cooldownLeft)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(width: 56, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(s.ready ? Color.indigo.opacity(0.7) : Color.gray.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(vm.pendingSkill == s.kind ? Color.yellow : .clear,
                                        lineWidth: 2)
                        )
                    }
                    .disabled(!s.ready || !vm.humanIsActive)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func handleTap(_ s: SkillState) {
        switch s.kind {
        case .shield, .chaos, .melon:
            vm.playerCastSkill(s.kind)
        case .swap:
            // 默认换第一张（可改为弹选择面板）
            vm.playerCastSkill(.swap, ownCardIndex: 0)
        case .peek, .unlucky:
            vm.pendingSkill = s.kind
            vm.statusMessage = "请点击一个 AI 头像作为目标"
        }
    }
}
