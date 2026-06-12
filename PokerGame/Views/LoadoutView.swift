import SwiftUI

/// P3 出战配置页：4 槽 + 预设 Tab + 技能池 + 入场按钮
struct LoadoutView: View {
    @EnvironmentObject var wallet: WalletStore
    @EnvironmentObject var tree: SkillTreeStore
    @EnvironmentObject var loadouts: LoadoutStore
    @Environment(\.dismiss) private var dismiss

    /// 由父视图传入的"开始一局"回调（已扣入场费后再切到牌桌）
    var onStart: () -> Void

    @State private var toast: String?

    private var ownedExtras: [LoadedNode] { tree.loadedNodes() }

    /// 当前 active loadout 的 4 个槽（解析失败的退化为 nil）
    private var slots: [String?] { loadouts.active.slots }

    /// 已装载技能数
    private var equippedCount: Int { slots.compactMap { $0 }.count }

    private var canStart: Bool {
        equippedCount >= 1 && wallet.canStartMatch()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                walletBar
                presetTabs
                slotsRow
                Divider().background(Color.white.opacity(0.18)).padding(.horizontal, 12)
                ScrollView { skillPool }
                bottomBar
            }
            .padding(.top, 8)
            .background(
                LinearGradient(colors: [Color(red: 0.04, green: 0.10, blue: 0.06),
                                        Color(red: 0.02, green: 0.05, blue: 0.03)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("出战配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if let t = toast {
                    Text(t).font(.callout.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .foregroundColor(.white)
                        .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: 顶部钱包条
    private var walletBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                Text("\(wallet.wallet.coins)").bold().foregroundColor(.yellow)
            }
            Spacer()
            Text("已装 \(equippedCount)/4").font(.footnote).foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.5)))
        .padding(.horizontal, 12)
    }

    // MARK: 预设 Tab
    private var presetTabs: some View {
        HStack(spacing: 8) {
            ForEach(loadouts.save.loadouts) { lo in
                Button { loadouts.setActive(lo.id) } label: {
                    Text(lo.name)
                        .font(.subheadline.bold())
                        .padding(.vertical, 6).frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(loadouts.active.id == lo.id
                                      ? Color.indigo.opacity(0.85)
                                      : Color.white.opacity(0.06))
                        )
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: 4 槽
    private var slotsRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                slotCell(i)
            }
        }
        .padding(.horizontal, 12)
    }

    private func slotCell(_ i: Int) -> some View {
        let key = slots[i]
        let entry: LoadoutEntry? = key.flatMap { resolveEntry($0) }
        return Button {
            if let key {
                loadouts.toggle(entryKey: key)
                showToast("已卸下")
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill((entry?.tint ?? Color.gray.opacity(0.3)).opacity(entry == nil ? 0.3 : 0.6))
                    if let e = entry {
                        Image(systemName: e.systemIcon).font(.title2).foregroundColor(.white)
                    } else {
                        Image(systemName: "plus").font(.title2).foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: 56, height: 56)
                Text(entry?.name ?? "空槽")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(entry?.subtitle ?? "—")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(entry?.tint ?? .clear, lineWidth: entry == nil ? 0 : 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: 技能池
    private var skillPool: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("基础技能").font(.subheadline.bold()).foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 14)
            grid(of: SkillKind.allCases.map { LoadoutEntry.base($0) })

            if !ownedExtras.isEmpty {
                Text("扩展技能（来自技能树）")
                    .font(.subheadline.bold()).foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 14).padding(.top, 4)
                grid(of: ownedExtras.map { LoadoutEntry.extra($0) })
            }
        }
        .padding(.bottom, 12)
    }

    private let cols = [GridItem(.adaptive(minimum: 96), spacing: 10)]

    private func grid(of entries: [LoadoutEntry]) -> some View {
        LazyVGrid(columns: cols, spacing: 10) {
            ForEach(entries) { e in
                poolCell(e)
            }
        }
        .padding(.horizontal, 12)
    }

    private func poolCell(_ e: LoadoutEntry) -> some View {
        let equipped = slots.contains(where: { $0 == e.slotKey })
        let full = !equipped && equippedCount >= 4
        return Button {
            if equipped {
                loadouts.toggle(entryKey: e.slotKey)
                showToast("已卸下")
            } else if full {
                showToast("已满 4 槽，请先卸下一个")
            } else {
                loadouts.toggle(entryKey: e.slotKey)
                showToast("已装载【\(e.name)】")
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: e.systemIcon)
                    .font(.title3)
                    .foregroundColor(equipped ? .white : e.tint)
                Text(e.name).font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white).lineLimit(1)
                Text(e.subtitle).font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(equipped ? e.tint.opacity(0.7) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(equipped ? Color.yellow : e.tint.opacity(0.5), lineWidth: equipped ? 2 : 1)
            )
            .opacity(full ? 0.4 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: 底部按钮
    private var bottomBar: some View {
        VStack(spacing: 6) {
            if equippedCount == 0 {
                Text("至少装载 1 个技能才能开始游戏")
                    .font(.caption).foregroundColor(.orange)
            } else if !wallet.canStartMatch() {
                Text("金币不足 \(WalletStore.entryFee)，请先领取补给")
                    .font(.caption).foregroundColor(.orange)
            }
            Button {
                guard canStart else { return }
                wallet.payEntry()
                onStart()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("开始游戏（入场 \(WalletStore.entryFee)）")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: canStart
                                   ? [Color.orange, Color.red]
                                   : [Color.gray.opacity(0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canStart)
        }
        .padding(.horizontal, 16).padding(.bottom, 14).padding(.top, 6)
        .background(
            Rectangle().fill(Color.black.opacity(0.35))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: 工具

    private func resolveEntry(_ key: String) -> LoadoutEntry? {
        if let k = SkillKind(rawValue: key) { return .base(k) }
        if let n = ownedExtras.first(where: { $0.id == key }) { return .extra(n) }
        return nil
    }

    private func showToast(_ s: String) {
        withAnimation { toast = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { toast = nil }
        }
    }
}
