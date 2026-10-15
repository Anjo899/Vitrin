//
//  ProductDetailView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Ürün detayı. Galeri, açıklama ve yorumlar `feature/product-detail`'de eklenecek.
struct ProductDetailView: View {
    let product: Product

    var body: some View {
        ContentUnavailableView(
            product.title,
            systemImage: "shippingbox",
            description: Text("Ürün detayı yakında burada olacak.")
        )
        .navigationTitle(product.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: .previewMascara)
    }
}
