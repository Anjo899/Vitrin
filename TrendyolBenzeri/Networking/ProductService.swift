//
//  ProductService.swift
//  TrendyolBenzeri
//

import Foundation

/// Ürün ve kategori uçlarını saran servis. Ekranlar URL yerine bu fonksiyonları çağırır.
nonisolated struct ProductService: Sendable {
    static let shared = ProductService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchProducts(limit: Int = 30, skip: Int = 0) async throws -> [Product] {
        let response: ProductsResponse = try await client.get(
            "products",
            query: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
            ]
        )
        return response.products
    }

    func searchProducts(query: String) async throws -> [Product] {
        let response: ProductsResponse = try await client.get(
            "products/search",
            query: [URLQueryItem(name: "q", value: query)]
        )
        return response.products
    }

    func fetchCategories() async throws -> [ProductCategory] {
        try await client.get("products/categories")
    }

    func fetchProducts(in category: ProductCategory) async throws -> [Product] {
        let response: ProductsResponse = try await client.get("products/category/\(category.slug)")
        return response.products
    }

    func fetchProduct(id: Int) async throws -> Product {
        try await client.get("products/\(id)")
    }
}
