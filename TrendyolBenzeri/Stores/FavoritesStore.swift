//
//  FavoritesStore.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Favori ürünleri tutan paylaşılan store. Uygulamanın giriş noktasında oluşturulur
/// ve `.environment` ile tüm ekranlara verilir; böylece kalp ikonu her yerde senkron kalır.
///
/// Dosyaya yalnızca id'ler yazılır (`StoredFavorites`). Ürün bilgisi bellekte tutulur; açılışta
/// bilinmeyenler (`missingProductIDs`) Favoriler ekranında API'den alınır.
@Observable
final class FavoritesStore {
    /// Favori ürünlerin id'leri. Kaydedilen tek bilgi bu; "favori mi?" sorusu hızlıca cevaplanır.
    private(set) var ids: Set<Int> = []
    /// Ürün id'si → ürün. Kaydedilmez; favorilenen ya da API'den gelen ürünler.
    private var knownProducts: [Int: Product] = [:]

    @ObservationIgnored private let storage: PlistStorage
    @ObservationIgnored private let fileName = "favorites.plist"

    init(storage: PlistStorage = PlistStorage()) {
        self.storage = storage
        load()
    }

    /// Favoriler sekmesinde göstermek için ada göre sıralı liste; ürün bilgisi bilinenler.
    var products: [Product] {
        ids.compactMap { knownProducts[$0] }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// Favori olup ürün bilgisi henüz gelmemiş id'ler (açılıştan sonra API'den istenir).
    var missingProductIDs: Set<Int> {
        ids.subtracting(knownProducts.keys)
    }

    var count: Int {
        ids.count
    }

    func isFavorite(_ product: Product) -> Bool {
        ids.contains(product.id)
    }

    func toggle(_ product: Product) {
        if isFavorite(product) {
            ids.remove(product.id)
        } else {
            ids.insert(product.id)
            knownProducts[product.id] = product
        }
        save()
    }

    /// API'den gelen ürünleri işler. İstenip gelmeyen id'ler (API'de artık olmayan ürünler) favorilerden çıkar.
    func update(with fetchedProducts: [Product], requestedIDs: Set<Int>) {
        for product in fetchedProducts where ids.contains(product.id) {
            knownProducts[product.id] = product
        }
        let removedIDs = requestedIDs.subtracting(fetchedProducts.map(\.id))
        guard !ids.isDisjoint(with: removedIDs) else { return }
        ids.subtract(removedIDs)
        save()
    }

    // MARK: - Kalıcılık

    private func load() {
        do {
            guard let stored = try storage.load(StoredFavorites.self, from: fileName) else { return }
            // Uygulamanın daha yeni bir sürümünün yazdığı dosya okunamaz; bozuk dosya gibi kenara alınır.
            guard stored.version <= StoredFavorites.currentVersion else {
                throw StoredRecordError.unsupportedVersion(stored.version)
            }
            ids = stored.ids
        } catch {
            migrateLegacyFile(after: error)
        }
    }

    /// Eski biçim (`[Int: Product]`) okunursa id'lere çevrilip yeni biçimde kaydedilir; ürünler bu açılışta
    /// bellekte kalır. O da okunamazsa dosya kenara alınır, favoriler boş başlar.
    private func migrateLegacyFile(after error: Error) {
        guard let legacy = try? storage.load([Int: Product].self, from: fileName) else {
            // Bozuk ya da bilinmeyen biçimdeki dosya, boş liste kaydedilirken ezilmesin.
            print("Favoriler yüklenemedi, dosya kenara alınıyor: \(error)")
            storage.moveAsideCorruptFile(fileName)
            return
        }
        ids = Set(legacy.keys)
        knownProducts = legacy
        save()
    }

    private func save() {
        do {
            try storage.save(StoredFavorites(ids: ids), to: fileName)
        } catch {
            print("Favoriler kaydedilemedi: \(error)")
        }
    }
}
