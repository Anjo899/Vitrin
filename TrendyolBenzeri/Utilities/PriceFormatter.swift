//
//  PriceFormatter.swift
//  TrendyolBenzeri
//

import Foundation

nonisolated extension Double {
    /// Türk lirası biçiminde fiyat, ör. 1234.5 → "₺1.234,50".
    var formattedPrice: String {
        formatted(.currency(code: "TRY").locale(Locale(identifier: "tr_TR")))
    }
}

nonisolated extension Product {
    /// İndirim rozeti metni, ör. 10.48 → "%10". Türkçede yüzde işareti sayının önüne yazılır.
    var discountLabel: String {
        "%\(Int(discountPercentage.rounded()))"
    }
}
