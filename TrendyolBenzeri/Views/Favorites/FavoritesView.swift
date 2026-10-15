//
//  FavoritesView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Favori ürünler. Veri ağdan değil `FavoritesStore`'dan geldiği için yükleniyor/hata durumu yok;
/// başka bir ekranda kalbe basıldığında bu liste kendiliğinden güncellenir.
struct FavoritesView: View {
    /// Seçili sekme `MainTabView`'a ait; `@Binding` ile buradan değiştirebiliyoruz.
    @Binding var selectedTab: MainTabView.Tab

    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        content
            .navigationTitle("Favoriler")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
    }

    @ViewBuilder
    private var content: some View {
        let products = favoritesStore.products

        if products.isEmpty {
            ContentUnavailableView {
                Label("Henüz favori ürünün yok", systemImage: "heart")
            } description: {
                Text("Beğendiğin ürünlerdeki kalbe basarak onları buraya ekleyebilirsin.")
            } actions: {
                Button("Ürünleri Keşfet") {
                    selectedTab = .home
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ScrollView {
                Text("\(products.count) ürün")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                ProductGridView(products: products)
            }
            // Kalbe basınca kart listeden kayarak çıksın.
            .animation(.default, value: products.map(\.id))
        }
    }
}

#Preview("Dolu") {
    let favoritesStore = FavoritesStore(storage: .preview)
    if !favoritesStore.isFavorite(.previewMascara) {
        favoritesStore.toggle(.previewMascara)
    }

    return NavigationStack {
        FavoritesView(selectedTab: .constant(.favorites))
    }
    .environment(favoritesStore)
}

#Preview("Boş") {
    NavigationStack {
        FavoritesView(selectedTab: .constant(.favorites))
    }
    .environment(FavoritesStore(storage: PlistStorage(directory: .temporaryDirectory.appending(path: UUID().uuidString))))
}
