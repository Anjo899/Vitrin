//
//  MainTabView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Alt sekmeler. Her sekmenin kendi `NavigationStack`'i var; böylece bir sekmede
/// detaya gidip başka sekmeye geçince, geri dönüldüğünde kalınan yer korunur.
struct MainTabView: View {
    enum Tab: Hashable {
        case home, categories, favorites, cart
    }

    @Environment(CartStore.self) private var cartStore
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Ana Sayfa", systemImage: "house") }
            .tag(Tab.home)

            NavigationStack {
                CategoriesView()
            }
            .tabItem { Label("Kategoriler", systemImage: "square.grid.2x2") }
            .tag(Tab.categories)

            NavigationStack {
                FavoritesView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Favoriler", systemImage: "heart") }
            .tag(Tab.favorites)

            NavigationStack {
                CartView()
            }
            .tabItem { Label("Sepet", systemImage: "cart") }
            // Badge 0 olduğunda SwiftUI onu otomatik gizler.
            .badge(cartStore.totalQuantity)
            .tag(Tab.cart)
        }
    }
}

#Preview {
    let cartStore = CartStore(storage: .preview)
    cartStore.add(.previewMascara)
    cartStore.add(.previewMascara)

    return MainTabView()
        .environment(FavoritesStore(storage: .preview))
        .environment(cartStore)
}
