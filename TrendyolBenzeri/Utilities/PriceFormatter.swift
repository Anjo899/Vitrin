//
//  PriceFormatter.swift
//  TrendyolBenzeri
//

import Foundation

nonisolated extension Double {
    /// dummyjson fiyatları dolar cinsinden, ör. 1234.5 → "$1,234.50".
    var formattedPrice: String {
        formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
    }

    /// Kuruşa (2 ondalık) yuvarlar, ör. 8.943048 → 8.94.
    var roundedToCents: Double {
        (self * 100).rounded() / 100
    }
}

nonisolated extension Product {
    /// İndirim rozeti metni, ör. 10.48 → "%10". Türkçede yüzde işareti sayının önüne yazılır.
    var discountLabel: String {
        "%\(Int(discountPercentage.rounded()))"
    }
}
