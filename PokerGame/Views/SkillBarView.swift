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
                        baseSkillCell(s)
                    }
                    .disabled(!s.ready || !vm.humanIsActive)
                }

                if !me.extraSkills.isEmpty {
                    Divider().frame(height: 36).background(Color.white.opacity(0.3))
                }

                ForEach(me.extraSkills) { es in
                    Button {
                        handleExtraTap(es.kind)
                    } label: {
                        extraSkillCell(es)
                    }
                    .disabled(!es.ready || !vm.humanIsActive)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func baseSkillCell(_ s: SkillState) -> some View {
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
                .stroke(vm.pendingSkill == s.kind ? Color.yellow : .clear, lineWidth: 2)
        )
    }

    private func extraSkillCell(_ es: ExtraSkillState) -> some View {
        VStack(spacing: 2) {
            Image(systemName: es.kind.systemIcon)
                .font(.title3)
                .foregroundColor(es.ready ? .white : .gray)
            Text(es.kind.name)
                .font(.caption2)
                .foregroundColor(.white)
            if !es.ready {
                Text("CD\(es.cooldownLeft)")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            } else {
                Text(es.kind.schoolLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(es.kind.schoolColor)
            }
        }
        .frame(width: 56, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(es.ready
                      ? LinearGradient(colors: [es.kind.schoolColor.opacity(0.85),
                                                es.kind.schoolColor.opacity(0.5)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                      : LinearGradient(colors: [Color.gray.opacity(0.4)],
                                       startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(vm.pendingExtraSkill == es.kind ? Color.yellow : .clear, lineWidth: 2)
        )
    }

    private func handleTap(_ s: SkillState) {
        switch s.kind {
        case .shield, .chaos, .melon:
            vm.playerCastSkill(s.kind)
        case .swap:
            vm.playerCastSkill(.swap, ownCardIndex: 0)
        case .peek, .unlucky:
            vm.pendingSkill = s.kind
            vm.pendingExtraSkill = nil
            vm.statusMessage = "请点击一个 AI 头像作为目标"
        }
    }

    private func handleExtraTap(_ id: ExtraSkillId) {
        if vm.extraSkillNeedsTarget(id) {
            vm.pendingExtraSkill = id
            vm.pendingSkill = nil
            vm.statusMessage = "请点击一个 AI 头像作为【\(id.name)】的目标"
        } else {
            vm.playerCastExtraSkill(id)
        }
    }
}
