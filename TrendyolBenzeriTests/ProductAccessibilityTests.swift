//
//  ProductAccessibilityTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// VoiceOver metinleri seçilen dilde ve bağlamıyla kurulur (ARCHITECTURE.md 8, REVIEW.md O9).
struct ProductAccessibilityTests {

    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")
    private let mascara = Product.sample(id: 1, title: "Mascara", price: 9.99, discountPercentage: 10.48)

    @Test func cardLabelReadsDiscountAndBothPricesInTurkish() {
        let label = ProductAccessibility.cardLabel(for: mascara, currency: .lira, locale: turkish)

        #expect(label == "Brand, Mascara, Puan 4,5, %10 indirim, Eski fiyat ₺449,55, Fiyat ₺402,30")
    }

    @Test func cardLabelReadsDiscountAndBothPricesInEnglish() {
        let label = ProductAccessibility.cardLabel(for: mascara, currency: .dollar, locale: english)

        #expect(label == "Brand, Mascara, Rating 4.5, 10% off, Original price $9.99, Price $8.94")
    }

    @Test func cardLabelWithoutDiscountHasSinglePrice() {
        let product = Product.sample(title: "Apple", price: 2)

        let label = ProductAccessibility.cardLabel(for: product, currency: .dollar, locale: english)

        #expect(label == "Brand, Apple, Rating 4.5, Price $2.00")
    }

    @Test func favoriteLabelNamesTheProduct() {
        #expect(ProductAccessibility.favoriteLabel(for: mascara, isFavorite: false).resolved(in: turkish)
            == "Mascara ürününü favorilere ekle")
        #expect(ProductAccessibility.favoriteLabel(for: mascara, isFavorite: true).resolved(in: english)
            == "Remove Mascara from favorites")
    }

    @Test func quantityLabelNamesTheProduct() {
        #expect(ProductAccessibility.quantityLabel(for: mascara).resolved(in: turkish) == "Mascara adedi")
        #expect(ProductAccessibility.quantityLabel(for: mascara).resolved(in: english) == "Quantity of Mascara")
    }
}
