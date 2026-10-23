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

/// Sepet ve Favoriler ViewModel'lerinin hata ve iptal geçişleri (ARCHITECTURE.md 9, ViewModel satırı).
@MainActor
struct StoredProductsViewModelStateTests {

    @Test func cartViewModelReturnsToIdleWhenCancelled() async {
        let server = StubServer(.failure(.cancelled))
        let viewModel = CartViewModel(service: server.service)

        await viewModel.loadProducts(ids: [1])

        #expect(viewModel.state.isIdle)
    }

    @Test func favoritesViewModelReturnsToIdleWhenCancelled() async {
        let server = StubServer(.failure(.cancelled))
        let viewModel = FavoritesViewModel(service: server.service)

        await viewModel.loadProducts(ids: [1])

        #expect(viewModel.state.isIdle)
    }

    @Test func favoritesViewModelShowsErrorWhenOffline() async {
        let server = StubServer(.failure(.notConnectedToInternet))
        let viewModel = FavoritesViewModel(service: server.service)

        await viewModel.loadProducts(ids: [1])

        #expect(viewModel.state.failureMessage
            == "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.")
    }

    /// Yükleme sürerken durum `.loading`; view bu sırada yükleniyor göstergesini çizer.
    @Test func cartViewModelIsLoadingWhileWaiting() async {
        let requestArrived = Gate()
        let release = Gate()
        let server = StubServer { _ in
            await requestArrived.open()
            await release.wait()
            return .product(id: 1)
        }
        let viewModel = CartViewModel(service: server.service)

        async let load: Void = viewModel.loadProducts(ids: [1])
        await requestArrived.wait()
        #expect(viewModel.state.isLoading)
        await release.open()
        await load

        #expect(viewModel.state.loadedValue?.map(\.id) == [1])
    }
}
