//
//  ProductRefreshTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Sepet ve favorilerdeki ürünlerin güncel tutulması (ARCHITECTURE.md 7. Kalıcılık, REVIEW.md O2).
@MainActor
struct ProductRefreshTests {

    @Test func addReplacesProductWithNewerCopy() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, price: 100))

        store.add(.sample(id: 1, price: 80))

        #expect(store.items[1]?.product.price == 80)
        #expect(store.totalPrice(in: .dollar) == 160)
    }

    @Test func refreshUpdatesPriceOfKnownProducts() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, price: 100))
        store.add(.sample(id: 1, price: 100))

        store.update(with: [.sample(id: 1, price: 50)], requestedIDs: [1])

        #expect(store.totalPrice(in: .dollar) == 100)
    }

    /// Stok düşünce adet stoğa indirilir ve bu kaydedilir (REVIEW.md O2).
    @Test func refreshClampsQuantityToNewStock() throws {
        let storage = try PlistStorage.temporary()
        let store = CartStore(storage: storage)
        for _ in 0..<5 { store.add(.sample(id: 1, stock: 10)) }

        store.update(with: [.sample(id: 1, stock: 2)], requestedIDs: [1])

        #expect(store.quantity(of: .sample(id: 1)) == 2)
        #expect(!store.canAdd(.sample(id: 1, stock: 2)))
        #expect(CartStore(storage: storage).totalQuantity == 2)
    }

    @Test func refreshRemovesLineWhenOutOfStock() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, stock: 10))
        store.add(.sample(id: 2, stock: 10))

        store.update(with: [.sample(id: 1, stock: 0), .sample(id: 2, stock: 10)], requestedIDs: [1, 2])

        #expect(store.productIDs == [2])
        #expect(store.totalQuantity == 1)
    }

    @Test func refreshKeepsQuantityWithinStock() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, stock: 10))
        store.add(.sample(id: 1, stock: 10))

        store.update(with: [.sample(id: 1, stock: 3)], requestedIDs: [1])

        #expect(store.quantity(of: .sample(id: 1)) == 2)
    }

    @Test func favoritesRefreshUpdatesKnownProducts() throws {
        let store = FavoritesStore(storage: try .temporary())
        store.toggle(.sample(id: 1, title: "Eski ad"))

        store.update(with: [.sample(id: 1, title: "Yeni ad")], requestedIDs: [1])

        #expect(store.products.map(\.title) == ["Yeni ad"])
    }

    // MARK: - Ekranın her görünüşte yaptığı tazeleme (`refreshProducts(using:)`)

    /// Bilinen ürünler de tazelenir: eksik ürün yokken bile istek atılır, fiyat ve stok güncellenir (REVIEW.md O2).
    @Test func cartRefreshUpdatesKnownProductsFromAPI() async throws {
        let store = CartStore(storage: try .temporary())
        for _ in 0..<6 { store.add(.sample(id: 1, price: 100, stock: 10)) }
        #expect(store.missingProductIDs.isEmpty)
        // Stub ürünü: fiyat 10, stok 5.
        let server = StubServer { _ in .product(id: 1) }

        await store.refreshProducts(using: CartViewModel(service: server.service))

        #expect(server.requests.map { $0.url?.path() } == ["/products/1"])
        #expect(store.items[1]?.product.price == 10)
        #expect(store.quantity(of: .sample(id: 1)) == 5)
    }

    @Test func cartRefreshDropsProductsRemovedFromAPI() async throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1))
        store.add(.sample(id: 2))
        let server = StubServer { request in
            request.url?.lastPathComponent == "2" ? .body("{}", status: 404) : .product(id: 1)
        }

        await store.refreshProducts(using: CartViewModel(service: server.service))

        #expect(store.productIDs == [1])
    }

    /// Ürünler biliniyorken tazeleme başarısız olursa sepet olduğu gibi kalır.
    @Test func failedCartRefreshKeepsKnownProducts() async throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, price: 100))
        let server = StubServer(.failure(.notConnectedToInternet))

        await store.refreshProducts(using: CartViewModel(service: server.service))

        #expect(store.items[1]?.product.price == 100)
        #expect(store.totalQuantity == 1)
    }

    @Test func emptyCartRefreshDoesNotRequest() async throws {
        let store = CartStore(storage: try .temporary())
        let server = StubServer(.product(id: 1))

        await store.refreshProducts(using: CartViewModel(service: server.service))

        #expect(server.requests.isEmpty)
    }

    @Test func favoritesRefreshUpdatesKnownProductsFromAPI() async throws {
        let store = FavoritesStore(storage: try .temporary())
        store.toggle(.sample(id: 1, title: "Eski ad"))
        let server = StubServer { _ in .product(id: 1, title: "Yeni ad") }

        await store.refreshProducts(using: FavoritesViewModel(service: server.service))

        #expect(server.requests.count == 1)
        #expect(store.products.map(\.title) == ["Yeni ad"])
    }
}
