//
//  PriceRoundingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

struct PriceRoundingTests {

    private let mascara = Product.sample(id: 1, price: 9.99, discountPercentage: 10.48)
    private let eyeshadow = Product.sample(id: 2, price: 19.99, discountPercentage: 18.19)
    private let turkish = Locale(identifier: "tr_TR")

    @Test func discountedPriceIsRoundedToCents() {
        // 9.99 × (1 − 0.1048) = 8.943048 → $8.94
        #expect(abs(mascara.discountedPrice - 8.94) < 0.000_001)
    }

    @Test func liraPriceUsesFixedRateAfterRounding() {
        #expect(ExchangeRate.usdToTry == 45)
        // $8.94 × 45 = 402.30 TL
        #expect(abs(mascara.discountedPriceInLira - 402.30) < 0.000_001)
        // $9.99 × 45 = 449.55 TL
        #expect(abs(mascara.priceInLira - 449.55) < 0.000_001)
        #expect(mascara.discountedPriceInLira.formatted(.lira.locale(turkish)) == "₺402,30")
    }

    @Test func lineTotalEqualsDisplayedUnitPriceTimesQuantity() {
        let item = CartItem(product: mascara, quantity: 2)
        // Dolar: 2 × $8.94 = $17.88 (yuvarlanmamış fiyatla $17.89 çıkıyordu)
        #expect(abs(item.lineTotal - 17.88) < 0.000_001)
        // TL: 2 × 402,30 = 804,60
        #expect(item.lineTotalInLira.formatted(.lira.locale(turkish)) == "₺804,60")
    }

    @MainActor
    @Test func cartTotalEqualsSumOfDisplayedLineTotals() throws {
        let cartStore = CartStore(storage: try .temporary())
        cartStore.add(mascara)
        cartStore.add(mascara)
        cartStore.add(eyeshadow)
        cartStore.add(eyeshadow)

        // Dolar: 2 × $8.94 + 2 × $16.35 = $50.58
        #expect(abs(cartStore.totalPrice - 50.58) < 0.000_001)
        // TL: 2 × 402,30 + 2 × 735,75 = 804,60 + 1.471,50 = 2.276,10
        #expect(cartStore.totalPriceInLira.formatted(.lira.locale(turkish)) == "₺2.276,10")
    }
}
