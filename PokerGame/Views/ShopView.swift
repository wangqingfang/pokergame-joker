import SwiftUI

struct ShopView: View {
    @EnvironmentObject var store: WalletStore
    @Environment(\.dismiss) private var dismiss
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    walletHeader
                    ForEach(ExtraSkillId.allCases) { skill in
                        skillCard(skill)
                    }
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color(red: 0.04, green: 0.10, blue: 0.06).ignoresSafeArea())
            .navigationTitle("技能商店")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if let t = toast {
                    Text(t)
                        .font(.callout.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.8)))
                        .foregroundColor(.white)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
        }
    }

    private var walletHeader: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
            Text("钱包：\(store.wallet.coins)").bold().foregroundColor(.yellow)
            Spacer()
            Text("已购：\(store.wallet.ownedExtraSkillIds.count)/\(ExtraSkillId.allCases.count)")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4)))
    }

    private func skillCard(_ skill: ExtraSkillId) -> some View {
        let owned = store.wallet.ownedExtraSkillIds.contains(skill.rawValue)
        let canAfford = store.wallet.coins >= skill.price
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(skill.schoolColor.opacity(0.25))
                Image(systemName: skill.systemIcon)
                    .font(.title)
                    .foregroundColor(skill.schoolColor)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(skill.name).font(.headline).foregroundColor(.white)
                    Text(skill.schoolLabel)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(skill.schoolColor.opacity(0.4)))
                        .foregroundColor(.white)
                }
                Text(skill.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("💰\(skill.price)")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
                buyButton(skill: skill, owned: owned, canAfford: canAfford)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(skill.schoolColor.opacity(owned ? 0.7 : 0.25), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func buyButton(skill: ExtraSkillId, owned: Bool, canAfford: Bool) -> some View {
        if owned {
            Text("已拥有")
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(Color.gray.opacity(0.5)))
                .foregroundColor(.white)
        } else {
            Button {
                if store.purchaseExtraSkill(skill.rawValue, price: skill.price) {
                    showToast("已购买【\(skill.name)】")
                } else {
                    showToast("金币不足")
                }
            } label: {
                Text("购买")
                    .font(.caption.bold())
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(canAfford ? skill.schoolColor : Color.gray.opacity(0.5)))
                    .foregroundColor(.white)
            }
            .disabled(!canAfford)
        }
    }

    private func showToast(_ msg: String) {
        withAnimation { toast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { toast = nil }
        }
    }
}
