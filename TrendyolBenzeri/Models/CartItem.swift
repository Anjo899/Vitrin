//
//  CartItem.swift
//  TrendyolBenzeri
//

import Foundation

/// Sepetteki bir satır: ürün ve adedi.
nonisolated struct CartItem: Codable, Identifiable, Hashable, Sendable {
    let product: Product
    var quantity: Int

    var id: Int { product.id }

    /// Satır toplamı indirimli fiyat üzerinden hesaplanır.
    var lineTotal: Double {
        product.discountedPrice * Double(quantity)
    }
}
