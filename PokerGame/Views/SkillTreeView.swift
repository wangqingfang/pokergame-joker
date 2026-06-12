import SwiftUI

/// 技能树主页：4 流派 Tab + 3×3 节点矩阵 + 节点详情卡（直接购买/升级）
struct SkillTreeView: View {
    @EnvironmentObject var wallet: WalletStore
    @EnvironmentObject var tree: SkillTreeStore
    @Environment(\.dismiss) private var dismiss

    @State private var school: School = .brute
    @State private var selectedNodeId: String?
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header
                schoolTabs
                grid
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .background(
                LinearGradient(colors: [Color(red: 0.04, green: 0.10, blue: 0.06),
                                        Color(red: 0.02, green: 0.05, blue: 0.03)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("技能树")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(item: bindingForSelectedDef()) { def in
                NodeDetailSheet(def: def, onAction: handleAction)
                    .environmentObject(wallet)
                    .environmentObject(tree)
                    .presentationDetents([.medium])
            }
            .overlay(alignment: .bottom) {
                if let t = toast {
                    Text(t)
                        .font(.callout.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .foregroundColor(.white)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                Text("\(wallet.wallet.coins)").bold().foregroundColor(.yellow)
            }
            HStack(spacing: 4) {
                Image(systemName: "clock").foregroundColor(.cyan)
                Text(playTimeLabel).font(.caption).foregroundColor(.white)
            }
            Spacer()
            Text("已购：\(ownedCount)/\(SkillCatalog.all.count)")
                .font(.footnote).foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
        .padding(.horizontal, 12)
    }

    private var schoolTabs: some View {
        HStack(spacing: 8) {
            ForEach(School.allCases) { s in
                Button { school = s } label: {
                    Text(s.label)
                        .font(.subheadline.bold())
                        .padding(.vertical, 6).frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(school == s ? s.color.opacity(0.85) : Color.white.opacity(0.06))
                        )
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(s.color.opacity(0.6), lineWidth: school == s ? 2 : 0)
                        )
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: 矩阵

    /// 行：T3 在最上、T1 在最下；T1/T2 各 3 列；T3 单节点居中
    private var grid: some View {
        let nodes = SkillCatalog.nodes(in: school)
        let t1 = nodes.filter { $0.tier == .t1 }
        let t2 = nodes.filter { $0.tier == .t2 }
        let t3 = nodes.filter { $0.tier == .t3 }

        return VStack(spacing: 14) {
            row(label: "T3", color: .orange) {
                HStack { Spacer(); ForEach(t3) { nodeCell($0) }; Spacer() }
            }
            row(label: "T2", color: .purple) {
                HStack(spacing: 10) { ForEach(t2) { nodeCell($0) } }
            }
            row(label: "T1", color: .blue) {
                HStack(spacing: 10) { ForEach(t1) { nodeCell($0) } }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private func row<Content: View>(label: String, color: Color,
                                    @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(label)
                .font(.caption.bold())
                .frame(width: 26, height: 26)
                .background(Circle().fill(color.opacity(0.7)))
                .foregroundColor(.white)
            content()
                .frame(maxWidth: .infinity)
        }
    }

    private func nodeCell(_ def: SkillNodeDef) -> some View {
        let state = tree.unlockState(def, wallet: wallet.wallet)
        let owned = state.isOwned
        let lv = tree.level(def.id)
        return Button {
            selectedNodeId = def.id
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(def.school.color.opacity(owned ? 0.55 : 0.18))
                    Image(systemName: def.systemIcon)
                        .font(.title3)
                        .foregroundColor(owned ? .white : def.school.color)
                    if case .lockedByTier = state {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .offset(x: 14, y: -14)
                    }
                }
                .frame(width: 50, height: 50)
                Text(def.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(stateBadge(state, level: lv))
                    .font(.system(size: 9))
                    .foregroundColor(stateBadgeColor(state))
                    .lineLimit(1)
            }
            .frame(width: 70, height: 90)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(for: state, school: def.school),
                            lineWidth: borderWidth(for: state))
            )
        }
        .buttonStyle(.plain)
    }

    private func stateBadge(_ s: NodeUnlockState, level: Int) -> String {
        switch s {
        case .owned: return level >= 5 ? "★×5 满" : "★×\(level)"
        case .purchasable: return "可购"
        case .lockedByPrerequisite: return "前置未解"
        case .lockedByPlayTime(let m): return "需\(m)m"
        case .lockedByTier: return "P4 解锁"
        case .insufficientCoins: return "金币不足"
        }
    }

    private func stateBadgeColor(_ s: NodeUnlockState) -> Color {
        switch s {
        case .owned: return .yellow
        case .purchasable: return .green
        default: return .white.opacity(0.55)
        }
    }

    private func borderColor(for s: NodeUnlockState, school: School) -> Color {
        switch s {
        case .owned: return .yellow
        case .purchasable: return school.color
        default: return .clear
        }
    }

    private func borderWidth(for s: NodeUnlockState) -> CGFloat {
        switch s {
        case .owned, .purchasable: return 2
        default: return 0
        }
    }

    // MARK: 操作

    private func handleAction(_ kind: NodeActionKind, def: SkillNodeDef) {
        switch kind {
        case .purchase:
            if tree.purchase(def, wallet: wallet) {
                showToast("已购买【\(def.name)】")
                selectedNodeId = nil
            } else {
                showToast("购买失败：条件未满足")
            }
        case .upgrade:
            if tree.upgrade(def, wallet: wallet) {
                showToast("【\(def.name)】升级到 ★\(tree.level(def.id))")
            } else {
                showToast("升级失败")
            }
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { toast = nil }
        }
    }

    // MARK: helper

    private var ownedCount: Int {
        SkillCatalog.all.filter { tree.isOwned($0.id) }.count
    }

    private var playTimeLabel: String {
        let m = wallet.wallet.totalPlayMinutes
        return m >= 60 ? "\(m / 60)h\(m % 60)m" : "\(m)m"
    }

    private func bindingForSelectedDef() -> Binding<SkillNodeDef?> {
        Binding(
            get: { selectedNodeId.flatMap(SkillCatalog.node(id:)) },
            set: { newValue in selectedNodeId = newValue?.id }
        )
    }
}

// 让 SkillNodeDef 可作为 sheet item
extension SkillNodeDef: Equatable {
    static func == (lhs: SkillNodeDef, rhs: SkillNodeDef) -> Bool { lhs.id == rhs.id }
}

enum NodeActionKind { case purchase, upgrade }

// MARK: - 节点详情 Sheet

private struct NodeDetailSheet: View {
    @EnvironmentObject var wallet: WalletStore
    @EnvironmentObject var tree: SkillTreeStore
    @Environment(\.dismiss) private var dismiss

    let def: SkillNodeDef
    var onAction: (NodeActionKind, SkillNodeDef) -> Void

    var body: some View {
        let state = tree.unlockState(def, wallet: wallet.wallet)
        let lv = tree.level(def.id)
        let success = def.tier.baseSuccess + Double(lv) * 0.06

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(def.school.color.opacity(0.4))
                    Image(systemName: def.systemIcon)
                        .font(.title)
                        .foregroundColor(def.school.color)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(def.name).font(.title3.bold())
                        Text(def.school.label)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(def.school.color.opacity(0.5)))
                            .foregroundColor(.white)
                        Text("T\(def.tier.rawValue)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                            .foregroundColor(.white)
                    }
                    Text("基础成功率 \(Int(def.tier.baseSuccess * 100))%  →  当前 \(Int(success * 100))%  →  满级 \(Int((def.tier.baseSuccess + 0.30) * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) }
            }

            Text(def.description)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))

            Divider().background(Color.white.opacity(0.2))

            if !def.prerequisiteIds.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("前置").font(.caption.bold()).foregroundColor(.white.opacity(0.7))
                    Text(def.prerequisiteIds.compactMap { SkillCatalog.node(id: $0)?.name }
                            .joined(separator: " / ") + "（任一）")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            actionArea(state: state, level: lv)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(colors: [Color(red: 0.06, green: 0.12, blue: 0.08),
                                    Color(red: 0.02, green: 0.04, blue: 0.03)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .foregroundColor(.white)
    }

    @ViewBuilder
    private func actionArea(state: NodeUnlockState, level: Int) -> some View {
        switch state {
        case .owned:
            ownedActionArea(level: level)
        case .purchasable:
            primaryButton(title: "购买（\(def.tier.buyCost) 金币）", color: def.school.color) {
                onAction(.purchase, def)
            }
        case .lockedByPrerequisite(let ids):
            lockHint("需要先解锁：\(ids.compactMap { SkillCatalog.node(id: $0)?.name }.joined(separator: " 或 "))")
        case .lockedByPlayTime(let m):
            lockHint("需累计游戏时长 \(m) 分钟（当前 \(wallet.wallet.totalPlayMinutes)）")
        case .lockedByTier:
            lockHint("T3 旗舰节点：P4 抽卡阶段开放")
        case .insufficientCoins(let p):
            lockHint("金币不足：需要 \(p)，当前 \(wallet.wallet.coins)")
        }
    }

    @ViewBuilder
    private func ownedActionArea(level: Int) -> some View {
        if def.tier == .t3 {
            lockHint("T3 暂不开放升级（P4 抽卡阶段）")
        } else if level >= 5 {
            disabledButton(title: "已满级 ★×5")
        } else if let delta = tree.nextUpgradeDelta(def) {
            let canAfford = wallet.wallet.coins >= delta
            primaryButton(
                title: "升到 ★×\(level + 1)（\(delta) 金币）",
                color: canAfford ? def.school.color : .gray
            ) {
                if canAfford { onAction(.upgrade, def) }
            }
            .disabled(!canAfford)
        }
    }

    private func primaryButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func disabledButton(title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func lockHint(_ s: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill").foregroundColor(.orange)
            Text(s).font(.callout).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4)))
    }
}
