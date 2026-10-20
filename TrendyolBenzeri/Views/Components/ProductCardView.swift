//
//  ProductCardView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Grid'deki ürün kartı: görsel, marka, ad, puan ve fiyat.
/// Kalp butonu kartın içinde değil; grid'de karta `overlay` olarak eklenir,
/// böylece kalbe basmak detay sayfasını açmaz.
struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            productImage

            VStack(alignment: .leading, spacing: 2) {
                if let brand = product.brand {
                    Text(brand)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                Text(product.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    // Kısa adlarda da iki satırlık yer ayır ki kartların boyu eşit olsun.
                    .lineLimit(2, reservesSpace: true)
            }

            RatingView(rating: product.rating)

            PriceView(product: product)
        }
        .padding(8)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        }
    }

    private var productImage: some View {
        AsyncImage(url: product.thumbnail) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topLeading) {
            if product.hasDiscount {
                Text(product.discountLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    // Beyaz metin için yeterli kontrast (6:1); sistem kırmızısı 3,5:1 kalıyor.
                    .background(Color.discountBadge, in: Capsule())
                    .padding(6)
            }
        }
    }
}

/// Yıldız ikonu ve tek ondalıklı puan, ör. ★ 4.5
struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Puan \(rating, format: .number.precision(.fractionLength(1)))"))
    }
}

/// İndirim varsa üstü çizili eski fiyat ve indirimli fiyat, yoksa sadece fiyat.
struct PriceView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if product.hasDiscount {
                Text(product.price.formattedPrice)
                    .font(.caption2)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
            Text(product.discountedPrice.formattedPrice)
                .font(.subheadline.bold())
                .foregroundStyle(product.hasDiscount ? Color.accentColor : .primary)
        }
    }
}

#Preview {
    HStack(alignment: .top) {
        ProductCardView(product: .previewMascara)
        ProductCardView(product: .previewApple)
    }
    .padding()
}
