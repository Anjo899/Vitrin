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
    /// Görünen daire yazı boyutuyla büyür; kartın üstünü kapatmasın diye 52 pt ile sınırlı.
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 34

    var body: some View {
        let isFavorite = favoritesStore.isFavorite(product)

        Button {
            favoritesStore.toggle(product)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(isFavorite ? .red : .secondary)
                .frame(width: min(circleSize, 52), height: min(circleSize, 52))
                .background(.regularMaterial, in: Circle())
                .contentTransition(.symbolEffect(.replace))
                // Dokunma alanı en az HIG'in önerdiği 44 pt; daire büyürse alan da büyür.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(isFavorite ? Text("Favorilerden çıkar") : Text("Favorilere ekle"))
    }
}

#Preview {
    FavoriteButton(product: .previewMascara)
        .environment(FavoritesStore(storage: .preview))
}
