import SwiftUI

/// "我的技能"：网格列出已购节点，按流派 Tab 分类，点击跳转到技能树（这里以信息卡形式展示）
struct MySkillsView: View {
    @EnvironmentObject var wallet: WalletStore
    @EnvironmentObject var tree: SkillTreeStore
    @Environment(\.dismiss) private var dismiss
    @State private var school: School = .brute

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                schoolTabs
                if ownedInSchool.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ownedInSchool) { def in
                                ownedCard(def)
                            }
                        }
                        .padding(.horizontal, 12).padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .background(
                LinearGradient(colors: [Color(red: 0.04, green: 0.10, blue: 0.06),
                                        Color(red: 0.02, green: 0.05, blue: 0.03)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("我的技能")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var schoolTabs: some View {
        HStack(spacing: 8) {
            ForEach(School.allCases) { s in
                Button { school = s } label: {
                    VStack(spacing: 2) {
                        Text(s.label).font(.subheadline.bold())
                        Text("\(ownedCount(in: s))")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 6).frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(school == s ? s.color.opacity(0.85) : Color.white.opacity(0.06))
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.system(size: 48)).foregroundColor(.white.opacity(0.4))
            Text("还没有 \(school.label) 流派的技能")
                .foregroundColor(.white.opacity(0.7))
            Text("到「技能树」里购买吧").font(.caption).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func ownedCard(_ def: SkillNodeDef) -> some View {
        let lv = tree.level(def.id)
        let success = def.tier.baseSuccess + Double(lv) * 0.06
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: def.systemIcon)
                    .foregroundColor(def.school.color)
                Text(def.name).font(.headline).foregroundColor(.white)
                Spacer()
                Text("T\(def.tier.rawValue)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .foregroundColor(.white)
            }
            Text(def.description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
            HStack {
                Text("★×\(lv)").font(.caption.bold()).foregroundColor(.yellow)
                Spacer()
                Text("\(Int(success * 100))%").font(.caption.bold()).foregroundColor(def.school.color)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(def.school.color.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private var ownedInSchool: [SkillNodeDef] {
        SkillCatalog.nodes(in: school).filter { tree.isOwned($0.id) }
    }

    private func ownedCount(in s: School) -> Int {
        SkillCatalog.nodes(in: s).filter { tree.isOwned($0.id) }.count
    }
}
