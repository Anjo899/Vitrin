//
//  ProductDetailView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Ürün detayı: galeri, bilgiler, açıklama ve yorumlar.
/// Ürün listeden geldiği için tüm bilgiler elimizde; ayrıca istek atmaya gerek yok.
struct ProductDetailView: View {
    let product: Product

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
                        Text(product.discountLabel)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                        Text(product.price.formattedPrice)
                            .font(.subheadline)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                }
                Text(product.discountedPrice.formattedPrice)
                    .font(.title2.bold())
                    .foregroundStyle(product.hasDiscount ? Color.accentColor : .primary)
            }

            Spacer()

            stockLabel
        }
    }

    private var stockLabel: some View {
        let (text, color): (String, Color) = switch product.stock {
        case 0: ("Tükendi", .red)
        case 1...5: ("Son \(product.stock) ürün!", .orange)
        default: ("Stokta \(product.stock) adet", .green)
        }

        return Label(text, systemImage: product.isInStock ? "shippingbox.fill" : "xmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
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
}
