//
//  StoredRecordsTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Sepet ve favorilerin dosya biçimi, eski biçimden göç ve yedekler (ARCHITECTURE.md 7. Kalıcılık, REVIEW.md O3).
@MainActor
struct StoredRecordsTests {

    // MARK: - Dosya biçimi

    @Test func cartWritesOnlyIDsAndQuantities() throws {
        let storage = try PlistStorage.temporary()
        let store = CartStore(storage: storage)
        store.add(.sample(id: 3))
        store.add(.sample(id: 3))

        let stored = try #require(try storage.load(StoredCart.self, from: "cart.plist"))
        #expect(stored == StoredCart(version: 1, quantities: [3: 2]))
    }

    @Test func favoritesWriteOnlyIDs() throws {
        let storage = try PlistStorage.temporary()
        FavoritesStore(storage: storage).toggle(.sample(id: 4))

        let stored = try #require(try storage.load(StoredFavorites.self, from: "favorites.plist"))
        #expect(stored == StoredFavorites(version: 1, ids: [4]))
    }

    /// Açılışta yalnızca id ve adet bilinir: badge doğru, ürünler API'den istenmek üzere eksik.
    @Test func reopenedCartKnowsQuantitiesButNotProducts() throws {
        let storage = try PlistStorage.temporary()
        let store = CartStore(storage: storage)
        store.add(.sample(id: 1))
        store.add(.sample(id: 2))
        store.add(.sample(id: 2))

        let reopened = CartStore(storage: storage)

        #expect(reopened.totalQuantity == 3)
        #expect(reopened.missingProductIDs == [1, 2])
        #expect(reopened.items.isEmpty)
    }

    @Test func reopenedFavoritesKnowIDsButNotProducts() throws {
        let storage = try PlistStorage.temporary()
        FavoritesStore(storage: storage).toggle(.sample(id: 7))

        let reopened = FavoritesStore(storage: storage)

        #expect(reopened.isFavorite(.sample(id: 7)))
        #expect(reopened.missingProductIDs == [7])
        #expect(reopened.products.isEmpty)
    }

    // MARK: - API'den gelen ürünler

    @Test func cartUpdateFillsProductsAndDropsRemovedOnes() throws {
        let storage = try PlistStorage.temporary()
        let store = CartStore(storage: storage)
        store.add(.sample(id: 1))
        store.add(.sample(id: 2))
        let reopened = CartStore(storage: storage)

        // 2 numaralı ürün API'de artık yok.
        reopened.update(with: [.sample(id: 1, title: "Fresh")], requestedIDs: [1, 2])

        #expect(reopened.missingProductIDs.isEmpty)
        #expect(reopened.sortedItems.map(\.product.title) == ["Fresh"])
        #expect(CartStore(storage: storage).totalQuantity == 1)
    }

    @Test func favoritesUpdateFillsProductsAndDropsRemovedOnes() throws {
        let storage = try PlistStorage.temporary()
        let store = FavoritesStore(storage: storage)
        store.toggle(.sample(id: 1))
        store.toggle(.sample(id: 2))
        let reopened = FavoritesStore(storage: storage)

        reopened.update(with: [.sample(id: 2, title: "Fresh")], requestedIDs: [1, 2])

        #expect(reopened.products.map(\.title) == ["Fresh"])
        #expect(FavoritesStore(storage: storage).count == 1)
    }

    /// İstek sürerken kullanıcı ürünü sepetten çıkardıysa gelen ürün sepete geri girmez.
    @Test func updateIgnoresProductsNoLongerInCart() throws {
        let store = CartStore(storage: try .temporary())

        store.update(with: [.sample(id: 5)], requestedIDs: [5])

        #expect(store.isEmpty)
        #expect(store.items.isEmpty)
    }

    // MARK: - Eski biçimden göç

    @Test func legacyCartFileIsMigrated() throws {
        let storage = try PlistStorage.temporary()
        let legacy: [Int: CartItem] = [8: CartItem(product: .sample(id: 8, title: "Eski"), quantity: 2)]
        try storage.save(legacy, to: "cart.plist")

        let store = CartStore(storage: storage)

        // Bu açılışta ürün eski dosyadan bilinir; dosya yeni biçimde yazılır, yedek alınmaz.
        #expect(store.sortedItems.map(\.product.title) == ["Eski"])
        #expect(store.totalQuantity == 2)
        #expect(try storage.load(StoredCart.self, from: "cart.plist") == StoredCart(version: 1, quantities: [8: 2]))
        #expect(storage.backupNames(of: "cart.plist").isEmpty)
    }

    @Test func legacyFavoritesFileIsMigrated() throws {
        let storage = try PlistStorage.temporary()
        let legacy: [Int: Product] = [9: .sample(id: 9, title: "Eski")]
        try storage.save(legacy, to: "favorites.plist")

        let store = FavoritesStore(storage: storage)

        #expect(store.products.map(\.title) == ["Eski"])
        let stored = try storage.load(StoredFavorites.self, from: "favorites.plist")
        #expect(stored == StoredFavorites(version: 1, ids: [9]))
        #expect(storage.backupNames(of: "favorites.plist").isEmpty)
    }

    @Test func newerFavoritesVersionIsMovedAside() throws {
        let storage = try PlistStorage.temporary()
        try storage.save(StoredFavorites(version: 99, ids: [1]), to: "favorites.plist")

        let store = FavoritesStore(storage: storage)

        #expect(store.count == 0)
        #expect(storage.backupNames(of: "favorites.plist").count == 1)
    }

    /// Uygulamanın daha yeni bir sürümünün yazdığı dosya okunmaz ve ezilmez; yedeklenir.
    @Test func newerVersionIsMovedAside() throws {
        let storage = try PlistStorage.temporary()
        try storage.save(StoredCart(version: 99, quantities: [1: 1]), to: "cart.plist")

        let store = CartStore(storage: storage)

        #expect(store.isEmpty)
        #expect(storage.backupNames(of: "cart.plist").count == 1)
    }
}
