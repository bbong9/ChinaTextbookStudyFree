import SwiftUI

/// 旧商店路由保留导航入口；商品集中在宠物店和小屋的装扮抽屉。
struct ShopView: View {
    @ObservedObject var progressStore: ProgressStore

    var body: some View {
        VStack(spacing: 20) {
            PetBalance(gems: progressStore.gems)
            HStack(spacing: 20) {
                entrance("宠物商店", subtitle: "领养新伙伴 · 护盾和红心", route: .petShop, id: "shop-open-pets")
                entrance("宠物小屋", subtitle: "照顾伙伴 · 挑选配饰", route: .petHome, id: "shop-open-home")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClayColor.petShop.ignoresSafeArea())
    }

    private func entrance(_ title: String, subtitle: String, route: AppRoute, id: String) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 10) {
                Text(title).font(ClayFont.title)
                Text(subtitle).font(ClayFont.body)
            }
            .foregroundStyle(ClayColor.statText).padding(24)
            .claySurface(.buttonCream, radius: ClayRadius.card, edge: ClayColor.creamEdge)
            .clayHitTarget()
        }
        .buttonStyle(ClayPressStyle()).accessibilityLabel("\(title)，\(subtitle)")
        .accessibilityIdentifier(id)
    }
}
