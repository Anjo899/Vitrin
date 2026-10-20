//
//  PriceRoundingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Ekranda görünen birim fiyat × adet, satır ve sepet toplamıyla birebir aynı olmalı.
/// Örnek değerler dummyjson'daki gerçek ürünlerden (maskara ve göz farı paleti).
struct PriceRoundingTests {

    private let mascara = Product.sample(id: 1, price: 9.99, discountPercentage: 10.48)
    private let eyeshadow = Product.sample(id: 2, price: 19.99, discountPercentage: 18.19)

    @Test func discountedPriceIsRoundedToCents() {
        // 9.99 × (1 − 0.1048) = 8.943048 → $8.94
        #expect(abs(mascara.discountedPrice - 8.94) < 0.000_001)
        #expect(mascara.discountedPrice.formattedPrice == "$8.94")
    }

    @Test func lineTotalEqualsDisplayedUnitPriceTimesQuantity() {
        let item = CartItem(product: mascara, quantity: 2)
        // 2 × $8.94 = $17.88 (yuvarlanmamış fiyatla $17.89 çıkıyordu)
        #expect(item.lineTotal.formattedPrice == "$17.88")
    }

    @MainActor
    @Test func cartTotalEqualsSumOfDisplayedLineTotals() throws {
        let cartStore = CartStore(storage: try .temporary())
        cartStore.add(mascara)
        cartStore.add(mascara)
        cartStore.add(eyeshadow)
        cartStore.add(eyeshadow)

        // 2 × $8.94 + 2 × $16.35 = $17.88 + $32.70 = $50.58
        #expect(cartStore.totalPrice.formattedPrice == "$50.58")
    }
}
