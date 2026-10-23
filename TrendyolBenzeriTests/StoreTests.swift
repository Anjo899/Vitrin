//
//  StoreTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

struct PlistStorageTests {

    @Test func returnsNilWhenFileIsMissing() throws {
        let storage = try PlistStorage.temporary()
        let loaded = try storage.load([Int: Product].self, from: "missing.plist")
        #expect(loaded == nil)
    }

    @Test func savesAndLoadsDictionary() throws {
        let storage = try PlistStorage.temporary()
        let items: [Int: CartItem] = [
            1: CartItem(product: .sample(id: 1), quantity: 2),
            7: CartItem(product: .sample(id: 7), quantity: 1)
        ]

        try storage.save(items, to: "cart.plist")
        let loaded = try storage.load([Int: CartItem].self, from: "cart.plist")

        #expect(loaded == items)
    }

    @MainActor
    @Test func corruptFileIsMovedAsideInsteadOfOverwritten() throws {
        let storage = try PlistStorage.temporary()
        let corruptData = Data("bozuk veri".utf8)
        try corruptData.write(to: storage.directory.appending(path: "cart.plist"))

        let cartStore = CartStore(storage: storage)
        cartStore.add(.sample())

        #expect(cartStore.totalQuantity == 1)
        let movedAside = try storage.onlyBackupData(of: "cart.plist")
        #expect(movedAside == corruptData)
    }
}

@MainActor
struct FavoritesStoreTests {

    @Test func togglesFavorite() throws {
        let store = FavoritesStore(storage: try .temporary())
        let product = Product.sample()

        store.toggle(product)
        #expect(store.isFavorite(product))
        #expect(store.count == 1)

        store.toggle(product)
        #expect(!store.isFavorite(product))
        #expect(store.count == 0)
    }

    @Test func sortsProductsByTitle() throws {
        let store = FavoritesStore(storage: try .temporary())
        store.toggle(.sample(id: 1, title: "Zeytinyağı"))
        store.toggle(.sample(id: 2, title: "Ayran"))

        #expect(store.products.map(\.title) == ["Ayran", "Zeytinyağı"])
    }

    @Test func persistsAcrossInstances() throws {
        let storage = try PlistStorage.temporary()
        FavoritesStore(storage: storage).toggle(.sample(id: 3))

        let reloaded = FavoritesStore(storage: storage)
        #expect(reloaded.isFavorite(.sample(id: 3)))
    }
}

@MainActor
struct CartStoreTests {

    @Test func addingSameProductIncreasesQuantity() throws {
        let store = CartStore(storage: try .temporary())
        let product = Product.sample()

        store.add(product)
        store.add(product)

        #expect(store.quantity(of: product) == 2)
        #expect(store.items.count == 1)
        #expect(store.totalQuantity == 2)
    }

    @Test func doesNotExceedStock() throws {
        let store = CartStore(storage: try .temporary())
        let product = Product.sample(stock: 2)

        store.add(product)
        store.add(product)
        store.add(product)

        #expect(store.quantity(of: product) == 2)
        #expect(!store.canAdd(product))
    }

    @Test func doesNotAddOutOfStockProduct() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(stock: 0))
        #expect(store.isEmpty)
    }

    @Test func decrementRemovesItemAtZero() throws {
        let store = CartStore(storage: try .temporary())
        let product = Product.sample()
        store.add(product)
        store.add(product)
        let item = try #require(store.items[product.id])

        store.decrement(item)
        #expect(store.quantity(of: product) == 1)

        store.decrement(item)
        #expect(store.isEmpty)
    }

    @Test func removeDeletesWholeLine() throws {
        let store = CartStore(storage: try .temporary())
        let product = Product.sample()
        store.add(product)
        store.add(product)

        store.remove(try #require(store.items[product.id]))
        #expect(store.isEmpty)
        #expect(store.totalQuantity == 0)
    }

    @Test func totalPriceUsesDiscountedPrices() throws {
        let store = CartStore(storage: try .temporary())
        let discounted = Product.sample(id: 1, price: 100, discountPercentage: 10)
        let regular = Product.sample(id: 2, price: 50)

        store.add(discounted)
        store.add(discounted)
        store.add(regular)

        // 2 × 90 + 1 × 50
        #expect(abs(store.totalPrice - 230) < 0.0001)
        #expect(store.totalQuantity == 3)
    }

    @Test func persistsAcrossInstances() throws {
        let storage = try PlistStorage.temporary()
        let product = Product.sample(id: 5)
        let store = CartStore(storage: storage)
        store.add(product)
        store.add(product)

        let reloaded = CartStore(storage: storage)
        #expect(reloaded.quantity(of: product) == 2)
    }
}

@MainActor
struct StoreRecoveryTests {

    /// Bozuk dosya kenara alınır, store boş başlar ve ilk kayıt yedeği ezmez (ARCHITECTURE.md 7. Kalıcılık).
    @Test func favoritesCorruptFileIsMovedAside() throws {
        let storage = try PlistStorage.temporary()
        let corruptData = Data("bozuk veri".utf8)
        try corruptData.write(to: storage.directory.appending(path: "favorites.plist"))

        let store = FavoritesStore(storage: storage)
        #expect(store.count == 0)

        store.toggle(.sample(id: 4))
        let movedAside = try storage.onlyBackupData(of: "favorites.plist")
        #expect(movedAside == corruptData)
        #expect(FavoritesStore(storage: storage).isFavorite(.sample(id: 4)))
    }

    @Test func cartCorruptFileStartsEmpty() throws {
        let storage = try PlistStorage.temporary()
        try Data("bozuk veri".utf8).write(to: storage.directory.appending(path: "cart.plist"))

        let store = CartStore(storage: storage)

        #expect(store.isEmpty)
        #expect(storage.backupNames(of: "cart.plist").count == 1)
    }

    /// Başka tipte (eski biçim) kaydedilmiş dosya da bozuk sayılır.
    @Test func cartFileWithOldFormatIsMovedAside() throws {
        let storage = try PlistStorage.temporary()
        try storage.save(["eski": "biçim"], to: "cart.plist")

        let store = CartStore(storage: storage)

        #expect(store.isEmpty)
        #expect(storage.backupNames(of: "cart.plist").count == 1)
    }
}

@MainActor
struct CartStoreQuantityTests {

    @Test func incrementAddsOneUpToStock() throws {
        let store = CartStore(storage: try .temporary())
        let product = Product.sample(stock: 2)
        store.add(product)
        let item = try #require(store.items[product.id])

        store.increment(item)
        store.increment(item)

        #expect(store.quantity(of: product) == 2)
    }

    @Test func decrementOfMissingItemDoesNothing() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1))

        store.decrement(CartItem(product: .sample(id: 2), quantity: 1))

        #expect(store.totalQuantity == 1)
    }

    @Test func totalQuantitySumsAllLines() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1))
        store.add(.sample(id: 1))
        store.add(.sample(id: 2))

        #expect(store.totalQuantity == 3)
        #expect(store.items.count == 2)
    }

    @Test func sortedItemsAreOrderedByTitle() throws {
        let store = CartStore(storage: try .temporary())
        store.add(.sample(id: 1, title: "Zeytinyağı"))
        store.add(.sample(id: 2, title: "Ayran"))

        #expect(store.sortedItems.map(\.product.title) == ["Ayran", "Zeytinyağı"])
    }

    @Test func changesArePersistedImmediately() throws {
        let storage = try PlistStorage.temporary()
        let store = CartStore(storage: storage)
        let product = Product.sample(id: 9)
        store.add(product)
        store.add(product)

        store.decrement(try #require(store.items[product.id]))
        #expect(CartStore(storage: storage).quantity(of: product) == 1)

        store.remove(try #require(store.items[product.id]))
        #expect(CartStore(storage: storage).isEmpty)
    }

    @Test func favoriteRemovalIsPersisted() throws {
        let storage = try PlistStorage.temporary()
        let store = FavoritesStore(storage: storage)
        store.toggle(.sample(id: 3))
        store.toggle(.sample(id: 3))

        #expect(FavoritesStore(storage: storage).count == 0)
    }
}
