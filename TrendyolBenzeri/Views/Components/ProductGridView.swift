//
//  ProductGridView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// 2 sütunlu ürün grid'i. Ana sayfa, arama, kategori ürünleri ve favoriler bunu kullanır.
/// Kartlar `NavigationLink(value:)` olduğu için, bulunduğu `NavigationStack`'te
/// `.navigationDestination(for: Product.self)` tanımlı olmalıdır.
struct ProductGridView: View {
    let products: [Product]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(products) { product in
                NavigationLink(value: product) {
                    ProductCardView(product: product)
                }
                .buttonStyle(.plain)
                // Kalp, NavigationLink'in dışında; basınca detay açılmaz.
                .overlay(alignment: .topTrailing) {
                    // Buton 44 pt dokunma alanına sahip; 7 pt boşlukla görünen kalp eski yerinde kalır.
                    FavoriteButton(product: product)
                        .padding(7)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ProductGridView(products: [.previewMascara, .previewApple])
        }
    }
    .environment(FavoritesStore(storage: .preview))
}
