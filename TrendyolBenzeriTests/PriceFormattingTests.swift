//
//  PriceFormattingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Fiyat biçimi, indirim rozeti ve kuruş yuvarlaması (ARCHITECTURE.md 6. Yerelleştirme ve para birimi).
/// Satır ve sepet toplamları `PriceRoundingTests`'te.
struct PriceFormattingTests {

    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")

    // MARK: - Biçim

    @Test(arguments: [
        (0.0, "₺0,00", "$0.00"),
        (8.5, "₺8,50", "$8.50"),
        (12_345.6, "₺12.345,60", "$12,345.60")
    ])
    func formatsCurrencyForLocale(amount: Double, lira: String, dollar: String) {
        #expect(amount.formatted(Currency.lira.format.locale(turkish)) == lira)
        #expect(amount.formatted(Currency.dollar.format.locale(english)) == dollar)
    }

    @Test func currencyCodesAreStable() {
        #expect(Currency.lira.rawValue == "TRY")
        #expect(Currency.dollar.rawValue == "USD")
    }

    // MARK: - Kur ve yuvarlama

    @Test func liraAmountUsesFixedRate() {
        #expect(Currency.lira.amount(fromDollars: 1) == 45)
        #expect(Currency.lira.amount(fromDollars: 0.01) == 0.45)
    }

    @Test func dollarAmountIsRoundedToCents() {
        #expect(Currency.dollar.amount(fromDollars: 1.234) == 1.23)
        #expect(Currency.dollar.amount(fromDollars: 1.236) == 1.24)
    }

    @Test(arguments: [
        (8.943048, 8.94),
        (0.125, 0.13),
        (2.0, 2.0),
        (0.004, 0.0)
    ])
    func roundsToCents(value: Double, expected: Double) {
        #expect(value.roundedToCents == expected)
    }

    // MARK: - İndirim

    @Test(arguments: [
        (10.48, 0.10),
        (10.5, 0.11),
        (0.0, 0.0),
        (99.6, 1.0)
    ])
    func discountRateIsRoundedToWholePercent(percentage: Double, expected: Double) {
        #expect(Product.sample(discountPercentage: percentage).discountRate == expected)
    }

    @Test func discountBadgeFormatFollowsLocale() {
        let rate = Product.sample(discountPercentage: 10.48).discountRate
        #expect(rate.formatted(.discount.locale(turkish)) == "%10")
        #expect(rate.formatted(.discount.locale(english)) == "10%")
    }

    @Test func hasDiscountOnlyWhenPercentageIsPositive() {
        #expect(!Product.sample(discountPercentage: 0).hasDiscount)
        #expect(Product.sample(discountPercentage: 5).hasDiscount)
    }

    @Test func discountedPriceAppliesPercentageInBothCurrencies() {
        let product = Product.sample(price: 100, discountPercentage: 25)

        #expect(product.discountedPrice(in: .dollar) == 75)
        #expect(product.discountedPrice(in: .lira) == 3375)
        #expect(product.price(in: .lira) == 4500)
    }

    // MARK: - Sepet toplamı

    @MainActor
    @Test func emptyCartTotalIsZero() throws {
        let cartStore = CartStore(storage: try .temporary())

        #expect(cartStore.totalPrice(in: .lira).formatted(Currency.lira.format.locale(turkish)) == "₺0,00")
        #expect(cartStore.totalPrice(in: .dollar).formatted(Currency.dollar.format.locale(english)) == "$0.00")
    }

    @MainActor
    @Test func cartTotalFollowsQuantityChanges() throws {
        let cartStore = CartStore(storage: try .temporary())
        let product = Product.sample(price: 10, discountPercentage: 10)

        cartStore.add(product)
        cartStore.add(product)
        #expect(cartStore.totalPrice(in: .lira) == 810)

        cartStore.decrement(try #require(cartStore.items[product.id]))
        #expect(cartStore.totalPrice(in: .lira) == 405)
        #expect(cartStore.totalPrice(in: .dollar) == 9)
    }
}
