//
//  Product.swift
//  TrendyolBenzeri
//

import Foundation

/// dummyjson.com'daki bir ürün. Sadece uygulamada kullandığımız alanları tanımlıyoruz;
/// JSON'daki diğer alanlar (sku, weight, meta ...) decode sırasında yok sayılır.
nonisolated struct Product: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    /// Bazı ürünlerde (ör. market ürünleri) marka yok, bu yüzden opsiyonel.
    let brand: String?
    let thumbnail: URL
    let images: [URL]
    let reviews: [Review]

    var hasDiscount: Bool {
        discountPercentage > 0
    }

    /// `price` indirimsiz fiyat; indirimli fiyatı yüzdeden hesaplıyoruz.
    var discountedPrice: Double {
        price * (1 - discountPercentage / 100)
    }

    var isInStock: Bool {
        stock > 0
    }
}

nonisolated struct Review: Codable, Hashable, Sendable {
    let rating: Int
    let comment: String
    let date: Date
    let reviewerName: String
}

/// `/products`, `/products/search` ve `/products/category/{slug}` uçlarının ortak cevabı.
nonisolated struct ProductsResponse: Codable, Sendable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}
