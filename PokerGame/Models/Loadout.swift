import Foundation
import SwiftUI

/// 装备槽中可装载的条目：基础技能 或 已购扩展节点。
/// 持久化时统一用 String 存：基础技能用 SkillKind.rawValue，扩展节点用 SkillNodeDef.id。
enum LoadoutEntry: Identifiable, Equatable, Hashable {
    case base(SkillKind)
    case extra(LoadedNode)

    static func == (lhs: LoadoutEntry, rhs: LoadoutEntry) -> Bool {
        lhs.slotKey == rhs.slotKey
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(slotKey)
    }

    var id: String {
        switch self {
        case .base(let k): return "base:\(k.rawValue)"
        case .extra(let n): return "extra:\(n.id)"
        }
    }

    var slotKey: String {
        switch self {
        case .base(let k): return k.rawValue
        case .extra(let n): return n.id
        }
    }

    var name: String {
        switch self {
        case .base(let k): return k.name
        case .extra(let n): return n.name
        }
    }

    var systemIcon: String {
        switch self {
        case .base(let k): return k.systemIcon
        case .extra(let n): return n.systemIcon
        }
    }

    /// 主色（基础技能用紫色，扩展节点用流派色）
    var tintHex: UInt32 {
        switch self {
        case .base: return 0xBF5AF2
        case .extra(let n): return n.school.fxColorHex
        }
    }

    var tint: Color {
        Color(red: Double((tintHex >> 16) & 0xFF) / 255.0,
              green: Double((tintHex >> 8) & 0xFF) / 255.0,
              blue: Double(tintHex & 0xFF) / 255.0)
    }

    /// 显示用的副标题（流派 / "基础"）
    var subtitle: String {
        switch self {
        case .base: return "基础"
        case .extra(let n): return n.schoolLabel
        }
    }
}

// MARK: - 解析后的出战配置（运行时使用）
struct ResolvedLoadout {
    let name: String
    let entries: [LoadoutEntry]   // 1..4

    var baseKinds: [SkillKind] {
        entries.compactMap { if case .base(let k) = $0 { return k } else { return nil } }
    }
    var extras: [LoadedNode] {
        entries.compactMap { if case .extra(let n) = $0 { return n } else { return nil } }
    }
}

// MARK: - 持久化模型

struct Loadout: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    /// 长度恒为 4，nil 表示空槽。值为 SkillKind.rawValue 或 SkillNodeDef.id
    var slots: [String?]

    init(id: UUID = UUID(), name: String, slots: [String?]) {
        self.id = id
        self.name = name
        // 强制 4 槽
        var s = slots
        while s.count < 4 { s.append(nil) }
        self.slots = Array(s.prefix(4))
    }
}

struct LoadoutSave: Codable {
    var loadouts: [Loadout]
    var activeId: UUID
}

// MARK: - Store

@MainActor
final class LoadoutStore: ObservableObject {
    private let key = "PokerGame.Loadouts.v1"
    @Published private(set) var save: LoadoutSave

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(LoadoutSave.self, from: data) {
            self.save = decoded
        } else {
            self.save = LoadoutStore.makeDefaults()
            self.persist()
        }
    }

    /// 内置 3 套预设
    private static func makeDefaults() -> LoadoutSave {
        let brute = Loadout(name: "暴力 build",
                            slots: [SkillKind.unlucky.rawValue,
                                    SkillKind.chaos.rawValue,
                                    SkillKind.swap.rawValue,
                                    nil])
        let defense = Loadout(name: "防守 build",
                              slots: [SkillKind.shield.rawValue,
                                      SkillKind.peek.rawValue,
                                      SkillKind.melon.rawValue,
                                      nil])
        let mix = Loadout(name: "混合 build",
                          slots: [SkillKind.peek.rawValue,
                                  SkillKind.shield.rawValue,
                                  SkillKind.swap.rawValue,
                                  SkillKind.melon.rawValue])
        return LoadoutSave(loadouts: [brute, defense, mix], activeId: brute.id)
    }

    // MARK: 查询

    var active: Loadout {
        save.loadouts.first(where: { $0.id == save.activeId }) ?? save.loadouts[0]
    }

    /// 解析 active loadout 为运行时条目。需要传入"已购扩展节点"列表用于校验有效性。
    func resolveActive(ownedExtras: [LoadedNode]) -> ResolvedLoadout {
        let extraById = Dictionary(uniqueKeysWithValues: ownedExtras.map { ($0.id, $0) })
        let entries: [LoadoutEntry] = active.slots.compactMap { slot in
            guard let key = slot else { return nil }
            if let kind = SkillKind(rawValue: key) {
                return .base(kind)
            }
            if let node = extraById[key] {
                return .extra(node)
            }
            return nil // 失效（可能已删档/未购买）
        }
        return ResolvedLoadout(name: active.name, entries: entries)
    }

    func canStart(ownedExtras: [LoadedNode]) -> Bool {
        !resolveActive(ownedExtras: ownedExtras).entries.isEmpty
    }

    // MARK: 操作

    func setActive(_ id: UUID) {
        guard save.loadouts.contains(where: { $0.id == id }) else { return }
        save.activeId = id
        persist()
    }

    func updateActiveSlot(index: Int, key: String?) {
        guard let li = save.loadouts.firstIndex(where: { $0.id == save.activeId }) else { return }
        var loadout = save.loadouts[li]
        guard (0..<4).contains(index) else { return }
        // 同一技能不可重复
        if let key = key, loadout.slots.contains(where: { $0 == key }) {
            return
        }
        loadout.slots[index] = key
        save.loadouts[li] = loadout
        persist()
    }

    /// 切换某个 entry 的装载状态：已装载 → 卸下；未装载 → 放入第一个空槽
    func toggle(entryKey: String) {
        guard let li = save.loadouts.firstIndex(where: { $0.id == save.activeId }) else { return }
        var loadout = save.loadouts[li]
        if let existing = loadout.slots.firstIndex(where: { $0 == entryKey }) {
            loadout.slots[existing] = nil
        } else if let empty = loadout.slots.firstIndex(where: { $0 == nil }) {
            loadout.slots[empty] = entryKey
        } else {
            return // 已满
        }
        save.loadouts[li] = loadout
        persist()
    }

    func renameActive(_ name: String) {
        guard let li = save.loadouts.firstIndex(where: { $0.id == save.activeId }) else { return }
        save.loadouts[li].name = name
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - AI 流派人设
extension School {
    /// AI 释放技能时的台词
    var aiTaunt: String {
        switch self {
        case .brute: return "狮子搏兔！"
        case .mage: return "虚虚实实……"
        case .guardian: return "稳如老狗"
        case .trickster: return "嘿嘿嘿……"
        }
    }

    /// 该流派 AI 的基础技能池（从 6 个基础技能中选）
    var aiSkillPool: [SkillKind] {
        switch self {
        case .brute: return [.unlucky, .chaos, .swap]
        case .mage: return [.peek, .swap, .melon]
        case .guardian: return [.shield, .melon, .peek]
        case .trickster: return [.chaos, .peek, .unlucky]
        }
    }
}
