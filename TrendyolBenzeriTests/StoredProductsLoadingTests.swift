//
//  StoredProductsLoadingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Saklanan id'lerin ürünlerini API'den alma.
@MainActor
struct StoredProductsLoadingTests {

    @Test func fetchProductsByIDSkipsRemovedProducts() async throws {
        // 2 numaralı ürün API'de artık yok (404).
        let server = StubServer { request in
            guard let id = request.url?.lastPathComponent, id != "2" else { return .body("{}", status: 404) }
            return .product(id: Int(id) ?? 0)
        }

        let products = try await server.service.fetchProducts(ids: [1, 2, 3])

        #expect(Set(products.map(\.id)) == [1, 3])
        #expect(Set(server.requests.compactMap { $0.url?.path() }) == ["/products/1", "/products/2", "/products/3"])
    }

    @Test func fetchProductsByIDThrowsOnOtherErrors() async {
        let server = StubServer(.body("", status: 500))

        await #expect(throws: APIError.self) {
            _ = try await server.service.fetchProducts(ids: [1])
        }
    }

    @Test func cartViewModelLoadsProducts() async {
        let server = StubServer { request in .product(id: Int(request.url?.lastPathComponent ?? "") ?? 0) }
        let viewModel = CartViewModel(service: server.service)

        await viewModel.loadProducts(ids: [4])

        #expect(viewModel.state.loadedValue?.map(\.id) == [4])
    }

    @Test func cartViewModelShowsErrorWhenOffline() async {
        let server = StubServer(.failure(.notConnectedToInternet))
        let viewModel = CartViewModel(service: server.service)

        await viewModel.loadProducts(ids: [4])

        #expect(viewModel.state.isFailed)
    }

    @Test func emptyIDsDoNotRequest() async {
        let server = StubServer(.products([]))
        let viewModel = FavoritesViewModel(service: server.service)

        await viewModel.loadProducts(ids: [])

        #expect(viewModel.state.isIdle)
        #expect(server.requests.isEmpty)
    }

    @Test func favoritesViewModelLoadsProducts() async {
        let server = StubServer { request in .product(id: Int(request.url?.lastPathComponent ?? "") ?? 0) }
        let viewModel = FavoritesViewModel(service: server.service)

        await viewModel.loadProducts(ids: [6])

        #expect(viewModel.state.loadedValue?.map(\.id) == [6])
    }
}
