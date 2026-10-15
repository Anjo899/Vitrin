//
//  ProductCategory.swift
//  TrendyolBenzeri
//

import Foundation

/// `/products/categories` ucundan gelen kategori, ör. `{"slug": "beauty", "name": "Beauty", "url": "..."}`.
nonisolated struct ProductCategory: Codable, Identifiable, Hashable, Sendable {
    let slug: String
    let name: String
    let url: URL

    var id: String { slug }
}
