//
//  ProductAccessibility.swift
//  TrendyolBenzeri
//

import Foundation

/// Ürün kartı, kalp ve sepet adedi için VoiceOver metinleri (ARCHITECTURE.md 8, REVIEW.md O9).
/// Metinler view'dan ayrı tutulur ki seçilen dilde doğru kurulduğu test edilebilsin.
enum ProductAccessibility {

    /// Kartın tek etiketi: marka, ad, puan, indirim, eski ve yeni fiyat; ör.
    /// "Essence, Essence Mascara Lash Princess, Puan 2,6, %10 indirim, Eski fiyat ₺449,55, Fiyat ₺402,30".
    static func cardLabel(for product: Product, currency: Currency, locale: Locale) -> String {
        var parts: [String] = []
        if let brand = product.brand {
            parts.append(brand)
        }
        parts.append(product.title)
        let rating = product.rating.formatted(.number.precision(.fractionLength(1)).locale(locale))
        parts.append(LocalizedStringResource("Puan \(rating)").resolved(in: locale))
        if product.hasDiscount {
            let discount = product.discountRate.formatted(.discount.locale(locale))
            parts.append(LocalizedStringResource("\(discount) indirim").resolved(in: locale))
            parts.append(oldPriceLabel(for: product, currency: currency, locale: locale))
        }
        let price = product.discountedPrice(in: currency).formatted(currency.format.locale(locale))
        parts.append(LocalizedStringResource("Fiyat \(price)").resolved(in: locale))
        return parts.joined(separator: ", ")
    }

    /// Üstü çizili fiyat bağlamsız okunmasın: "Eski fiyat ₺449,55".
    static func oldPriceLabel(for product: Product, currency: Currency, locale: Locale) -> String {
        let price = product.price(in: currency).formatted(currency.format.locale(locale))
        return LocalizedStringResource("Eski fiyat \(price)").resolved(in: locale)
    }

    /// Kalp butonu, hangi ürün olduğunu söyler: "Essence Mascara ürününü favorilere ekle".
    static func favoriteLabel(for product: Product, isFavorite: Bool) -> LocalizedStringResource {
        isFavorite
            ? "\(product.title) ürününü favorilerden çıkar"
            : "\(product.title) ürününü favorilere ekle"
    }

    /// Sepet satırındaki adet kontrolünün etiketi: "Essence Mascara adedi".
    static func quantityLabel(for product: Product) -> LocalizedStringResource {
        "\(product.title) adedi"
    }
}
