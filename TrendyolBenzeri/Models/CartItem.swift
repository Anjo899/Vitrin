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

    /// Satır toplamı (dolar), kuruşa yuvarlanmış indirimli fiyat × adet.
    var lineTotal: Double {
        (product.discountedPrice * Double(quantity)).roundedToCents
    }

    /// Ekranda gösterilen satır toplamı (TL): görünen TL birim fiyat × adet.
    var lineTotalInLira: Double {
        (product.discountedPriceInLira * Double(quantity)).roundedToCents
    }
}
