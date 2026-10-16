//
//  FavoritesStore.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Favori ürünleri tutan paylaşılan store. Uygulamanın giriş noktasında oluşturulur
/// ve `.environment` ile tüm ekranlara verilir; böylece kalp ikonu her yerde senkron kalır.
@Observable
final class FavoritesStore {
    /// Ürün id'si → ürün. Dictionary sayesinde "favori mi?" sorusu hızlıca cevaplanır.
    private(set) var items: [Int: Product] = [:]

    @ObservationIgnored private let storage: PlistStorage
    @ObservationIgnored private let fileName = "favorites.plist"

    init(storage: PlistStorage = PlistStorage()) {
        self.storage = storage
        do {
            items = try storage.load([Int: Product].self, from: fileName) ?? [:]
        } catch {
            // Bozuk ya da eski formattaki dosya, boş liste kaydedilirken ezilmesin.
            print("Favoriler yüklenemedi, dosya kenara alınıyor: \(error)")
            storage.moveAsideCorruptFile(fileName)
        }
    }

    /// Favoriler sekmesinde göstermek için ada göre sıralı liste.
    var products: [Product] {
        items.values.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    var count: Int {
        items.count
    }

    func isFavorite(_ product: Product) -> Bool {
        items[product.id] != nil
    }

    func toggle(_ product: Product) {
        if isFavorite(product) {
            items[product.id] = nil
        } else {
            items[product.id] = product
        }
        save()
    }

    private func save() {
        do {
            try storage.save(items, to: fileName)
        } catch {
            print("Favoriler kaydedilemedi: \(error)")
        }
    }
}
