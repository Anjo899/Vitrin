//
//  APIClientTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// `APIClient`'ın cevapları ve hataları nasıl eşlediği (REVIEW.md T1).
struct APIClientTests {

    @Test func decodesSuccessfulResponse() async throws {
        let server = StubServer(.products(["Phone"]))

        let response: ProductsResponse = try await server.client.get("products")

        #expect(response.products.map(\.title) == ["Phone"])
    }

    @Test(arguments: [404, 500])
    func nonSuccessStatusThrowsBadStatus(status: Int) async {
        let server = StubServer(.body("{}", status: status))

        await #expect {
            let _: ProductsResponse = try await server.client.get("products")
        } throws: { error in
            guard case APIError.badStatus(let code) = error else { return false }
            return code == status
        }
    }

    @Test func malformedJSONThrowsDecoding() async {
        let server = StubServer(.body(#"{"products": "#))

        await #expect {
            let _: ProductsResponse = try await server.client.get("products")
        } throws: { error in
            guard case APIError.decoding = error else { return false }
            return true
        }
    }

    /// İptal edilen istek hata ekranı göstermesin diye `CancellationError`'a çevrilir.
    @Test func cancelledRequestThrowsCancellationError() async {
        let server = StubServer(.failure(.cancelled))

        await #expect(throws: CancellationError.self) {
            let _: ProductsResponse = try await server.client.get("products")
        }
    }

    @Test func connectionFailureThrowsNetwork() async {
        let server = StubServer(.failure(.notConnectedToInternet))

        await #expect {
            let _: ProductsResponse = try await server.client.get("products")
        } throws: { error in
            guard case APIError.network = error else { return false }
            return true
        }
    }

    @Test func sendsPathAndQuery() async throws {
        let server = StubServer(.products([]))

        let _: ProductsResponse = try await server.client.get(
            "products/search",
            query: [URLQueryItem(name: "q", value: "phone")]
        )

        let request = try #require(server.requests.first)
        #expect(request.url?.path() == "/products/search")
        #expect(request.queryValue("q") == "phone")
    }

    // MARK: - Hata mesajları

    @Test func userMessageMapsEachError() {
        let turkish = Locale(identifier: "tr_TR")
        let underlying = URLError(.timedOut)

        #expect(APIError.invalidURL.userMessage.resolved(in: turkish) == "İstek adresi geçersiz.")
        #expect(APIError.network(underlying).userMessage.resolved(in: turkish)
            == "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.")
        #expect(APIError.badStatus(500).userMessage.resolved(in: turkish)
            == "Sunucu beklenmedik bir cevap verdi (500).")
        #expect(APIError.decoding(underlying).userMessage.resolved(in: turkish) == "Gelen veri okunamadı.")
        #expect(underlying.userMessage.resolved(in: turkish) == "Beklenmeyen bir hata oluştu.")
    }

    @Test func userMessageIsTranslated() {
        let english = Locale(identifier: "en_US")

        #expect(APIError.decoding(URLError(.timedOut)).userMessage.resolved(in: english)
            == "The received data could not be read.")
        #expect(APIError.badStatus(404).userMessage.resolved(in: english)
            == "The server returned an unexpected response (404).")
    }
}

/// `ProductService`'in hangi uca hangi parametrelerle gittiği.
struct ProductServiceTests {

    @Test func fetchProductsSendsLimitAndSkip() async throws {
        let server = StubServer(.products(["A", "B"]))

        let products = try await server.service.fetchProducts(limit: 0, skip: 5)

        #expect(products.map(\.title) == ["A", "B"])
        let request = try #require(server.requests.first)
        #expect(request.url?.path() == "/products")
        #expect(request.queryValue("limit") == "0")
        #expect(request.queryValue("skip") == "5")
    }

    @Test func searchProductsSendsQuery() async throws {
        let server = StubServer(.products([]))

        _ = try await server.service.searchProducts(query: "red shoes")

        let request = try #require(server.requests.first)
        #expect(request.url?.path() == "/products/search")
        #expect(request.queryValue("q") == "red shoes")
    }

    @Test func fetchCategoriesDecodesList() async throws {
        let server = StubServer(.categories(["beauty", "laptops"]))

        let categories = try await server.service.fetchCategories()

        #expect(categories.map(\.slug) == ["beauty", "laptops"])
        #expect(server.requests.first?.url?.path() == "/products/categories")
    }

    @Test func fetchProductsInCategoryUsesSlug() async throws {
        let server = StubServer(.products(["Lipstick"]))
        let category = ProductCategory(slug: "beauty", name: "Beauty", url: URL(string: "https://example.com")!)

        let products = try await server.service.fetchProducts(in: category)

        #expect(products.map(\.title) == ["Lipstick"])
        #expect(server.requests.first?.url?.path() == "/products/category/beauty")
    }
}
