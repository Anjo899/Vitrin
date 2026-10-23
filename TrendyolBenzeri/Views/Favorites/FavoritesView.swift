//
//  FavoritesView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Favori ürünler. Liste `FavoritesStore`'dan gelir; başka bir ekranda kalbe basıldığında kendiliğinden
/// güncellenir. Dosyada yalnızca id'ler olduğu için açılıştan sonra ürün bilgisi bir kez API'den istenir.
struct FavoritesView: View {
    /// Seçili sekme `MainTabView`'a ait; `@Binding` ile buradan değiştirebiliyoruz.
    @Binding var selectedTab: MainTabView.Tab

    @Environment(FavoritesStore.self) private var favoritesStore
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        content
            .navigationTitle("Favoriler")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            // Dosyada yalnızca id var; ekran her açıldığında ürünler API'den alınır ve tazelenir.
            // Ürünler biliniyorsa istek arka planda olur, başarısız olursa liste olduğu gibi kalır.
            .task {
                await refreshProducts()
            }
    }

    private func refreshProducts() async {
        let ids = favoritesStore.ids
        guard !ids.isEmpty else { return }
        await viewModel.loadProducts(ids: ids)
        if case .loaded(let products) = viewModel.state {
            favoritesStore.update(with: products, requestedIDs: ids)
        }
    }

    @ViewBuilder
    private var content: some View {
        let products = favoritesStore.products

        if favoritesStore.count == 0 {
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
        } else if !favoritesStore.missingProductIDs.isEmpty {
            if case .failed(let message) = viewModel.state {
                ErrorView(message: message) {
                    await refreshProducts()
                }
            } else {
                LoadingView(message: "Favoriler yükleniyor…")
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
    favoritesStore.toggle(.previewMascara)

    return NavigationStack {
        FavoritesView(selectedTab: .constant(.favorites))
    }
    .environment(favoritesStore)
}

#Preview("Boş") {
    NavigationStack {
        FavoritesView(selectedTab: .constant(.favorites))
    }
    .environment(FavoritesStore(storage: .preview))
}
