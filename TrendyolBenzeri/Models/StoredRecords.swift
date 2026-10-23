//
//  StoredRecords.swift
//  TrendyolBenzeri
//

import Foundation

/// `cart.plist`'e yazılan kayıt: yalnızca ürün id'si ve adet. Ürün bilgisi (fiyat, stok, ad)
/// dosyada tutulmaz, API'den gelir; böylece `Product`'a alan eklemek kayıtlı sepeti bozmaz.
nonisolated struct StoredCart: Codable, Equatable, Sendable {
    /// Biçim değişince artırılır; yeni sürümün okuyamadığı dosya yedeklenir.
    static let currentVersion = 1

    var version = StoredCart.currentVersion
    /// Ürün id'si → adet.
    var quantities: [Int: Int]
}

/// `favorites.plist`'e yazılan kayıt: yalnızca favori ürünlerin id'leri.
nonisolated struct StoredFavorites: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = StoredFavorites.currentVersion
    var ids: Set<Int>
}

/// Kayıt dosyası okunabildi ama bu sürümün bilmediği bir biçimde.
nonisolated enum StoredRecordError: Error {
    case unsupportedVersion(Int)
}
