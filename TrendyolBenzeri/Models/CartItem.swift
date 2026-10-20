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

    /// Satır toplamı, ekranda görünen (kuruşa yuvarlanmış) indirimli fiyat × adet.
    var lineTotal: Double {
        (product.discountedPrice * Double(quantity)).roundedToCents
    }
}
