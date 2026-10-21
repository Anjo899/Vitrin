//
//  ProductDetailView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Ürün detayı: galeri, bilgiler, açıklama ve yorumlar.
/// Ürün listeden geldiği için tüm bilgiler elimizde; ayrıca istek atmaya gerek yok.
struct ProductDetailView: View {
    let product: Product
    /// Kökte seçilen dile göre verilir; dil değişince fiyatlar anında yeni para birimine geçer.
    @Environment(\.currency) private var currency

    /// Bazı ürünlerde `images` boş olabilir; o zaman küçük görseli galeride gösteririz.
    private var galleryImages: [URL] {
        product.images.isEmpty ? [product.thumbnail] : product.images
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProductImageGallery(images: galleryImages)

                VStack(alignment: .leading, spacing: 20) {
                    header
                    priceAndStock
                    Divider()
                    descriptionSection
                    Divider()
                    reviewsSection
                }
                .padding()
            }
        }
        // Çubuk içeriğin altına yerleşir; kaydırılan içerik çubuğun arkasında kalmaz.
        .safeAreaInset(edge: .bottom) {
            AddToCartBar(product: product)
        }
        .navigationTitle(product.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(product: product)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let brand = product.brand {
                Text(brand)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            Text(product.title)
                .font(.title3.bold())

            HStack(spacing: 6) {
                StarRatingView(rating: product.rating, size: 14)
                Text(product.rating, format: .number.precision(.fractionLength(1)))
                    .font(.subheadline.weight(.semibold))
                Text("(\(product.reviews.count) değerlendirme)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var priceAndStock: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if product.hasDiscount {
                    HStack(spacing: 6) {
                        Text(product.discountRate, format: .discount)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.discountBadge, in: Capsule())
                        Text(product.price(in: currency), format: currency.format)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                }
                Text(product.discountedPrice(in: currency), format: currency.format)
                    .font(.title2.bold())
                    .foregroundStyle(product.hasDiscount ? Color.accentColor : .primary)
            }

            Spacer()

            stockLabel
        }
    }

    private var stockLabel: some View {
        Label {
            stockText
        } icon: {
            Image(systemName: product.isInStock ? "shippingbox.fill" : "xmark.circle.fill")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(stockColor)
    }

    /// Doğrudan `Text("…")` döndürülür; böylece derleyici metinleri String Catalog için bulabilir.
    private var stockText: Text {
        switch product.stock {
        case 0: Text("Tükendi")
        case 1...5: Text("Son \(product.stock) ürün!")
        default: Text("Stokta \(product.stock) adet")
        }
    }

    /// Sistem kırmızı/turuncu/yeşili beyaz zeminde okunaklı değil (2,2–3,5:1); Assets'teki
    /// renkler açık ve koyu temada en az 4,5:1 kontrast verir.
    private var stockColor: Color {
        switch product.stock {
        case 0: .stockOut
        case 1...5: .stockLow
        default: .stockAvailable
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ürün Açıklaması")
                .font(.headline)
            Text(product.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Değerlendirmeler (\(product.reviews.count))")
                .font(.headline)

            if product.reviews.isEmpty {
                Text("Henüz değerlendirme yok.")
                    .foregroundStyle(.secondary)
            } else {
                // Review'un kendi id'si yok; listedeki sırasını kimlik olarak kullanıyoruz.
                ForEach(Array(product.reviews.enumerated()), id: \.offset) { index, review in
                    if index > 0 {
                        Divider()
                    }
                    ReviewRowView(review: review)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: .previewMascara)
    }
    .environment(FavoritesStore(storage: .preview))
    .environment(CartStore(storage: .preview))
}
