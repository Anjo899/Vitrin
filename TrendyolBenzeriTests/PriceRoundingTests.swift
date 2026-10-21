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
    private let english = Locale(identifier: "en_US")

    @Test func discountedPriceIsRoundedToCents() {
        // 9.99 × (1 − 0.1048) = 8.943048 → $8.94
        #expect(abs(mascara.discountedPrice - 8.94) < 0.000_001)
    }

    @Test func liraPriceUsesFixedRateAfterRounding() {
        #expect(ExchangeRate.usdToTry == 45)
        // $8.94 × 45 = 402.30 TL
        #expect(abs(mascara.discountedPrice(in: .lira) - 402.30) < 0.000_001)
        // $9.99 × 45 = 449.55 TL
        #expect(abs(mascara.price(in: .lira) - 449.55) < 0.000_001)
        #expect(mascara.discountedPrice(in: .lira).formatted(Currency.lira.format.locale(turkish)) == "₺402,30")
    }

    /// İngilizcede kur uygulanmaz; gösterilen fiyat API'deki dolar değeriyle aynıdır.
    @Test(arguments: [9.99, 19.99, 0.5, 1299.9, 2499.99])
    func dollarPriceEqualsAPIValue(price: Double) {
        let product = Product.sample(id: 3, price: price, discountPercentage: 12.5)
        #expect(product.price(in: .dollar) == price)
        #expect(product.discountedPrice(in: .dollar) == product.discountedPrice)
    }

    @Test func lineTotalEqualsDisplayedUnitPriceTimesQuantity() {
        let item = CartItem(product: mascara, quantity: 2)
        // Dolar: 2 × $8.94 = $17.88 (yuvarlanmamış fiyatla $17.89 çıkıyordu)
        #expect(abs(item.lineTotal - 17.88) < 0.000_001)
        #expect(item.lineTotal(in: .dollar) == item.lineTotal)
        #expect(item.lineTotal(in: .dollar).formatted(Currency.dollar.format.locale(english)) == "$17.88")
        // TL: 2 × 402,30 = 804,60
        #expect(item.lineTotal(in: .lira).formatted(Currency.lira.format.locale(turkish)) == "₺804,60")
    }

    @MainActor
    @Test func cartTotalEqualsSumOfDisplayedLineTotals() throws {
        let cartStore = CartStore(storage: try .temporary())
        cartStore.add(mascara)
        cartStore.add(mascara)
        cartStore.add(eyeshadow)
        cartStore.add(eyeshadow)

        // Dolar: 2 × $8.94 + 2 × $16.35 = $17.88 + $32.70 = $50.58
        #expect(abs(cartStore.totalPrice - 50.58) < 0.000_001)
        #expect(cartStore.totalPrice(in: .dollar).formatted(Currency.dollar.format.locale(english)) == "$50.58")
        // TL: 2 × 402,30 + 2 × 735,75 = 804,60 + 1.471,50 = 2.276,10
        #expect(cartStore.totalPrice(in: .lira).formatted(Currency.lira.format.locale(turkish)) == "₺2.276,10")
    }

    /// Her iki para biriminde toplam, ekranda görünen satır toplamlarının toplamına kuruşu kuruşuna eşit.
    @MainActor
    @Test(arguments: Currency.allCases)
    func cartTotalMatchesDisplayedLines(currency: Currency) throws {
        let cartStore = CartStore(storage: try .temporary())
        let products = (1...6).map { Product.sample(id: $0, price: 4.99 + Double($0) * 3.33, discountPercentage: 7.77 * Double($0)) }
        for product in products {
            for _ in 0..<product.id { cartStore.add(product) }
        }

        let displayedCents = cartStore.items.values.reduce(0) { $0 + Int(($1.lineTotal(in: currency) * 100).rounded()) }
        #expect(Int((cartStore.totalPrice(in: currency) * 100).rounded()) == displayedCents)
    }
}
