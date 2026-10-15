//
//  FavoriteButton.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Ürünü favorilere ekleyip çıkaran kalp butonu. Durumu `FavoritesStore`'dan okuduğu için
/// bir ekranda basılınca, aynı ürünü gösteren diğer ekranlardaki kalpler de güncellenir.
struct FavoriteButton: View {
    let product: Product

    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        let isFavorite = favoritesStore.isFavorite(product)

        Button {
            favoritesStore.toggle(product)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFavorite ? .red : .secondary)
                .frame(width: 34, height: 34)
                .background(.regularMaterial, in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(isFavorite ? "Favorilerden çıkar" : "Favorilere ekle")
    }
}

#Preview {
    FavoriteButton(product: .previewMascara)
        .environment(FavoritesStore(storage: .preview))
}
