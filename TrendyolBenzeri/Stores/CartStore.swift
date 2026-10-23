//
//  CartStore.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Sepeti tutan paylaşılan store. Sepet sekmesindeki badge `totalQuantity`'yi gösterir.
///
/// Dosyaya yalnızca id ve adet yazılır (`StoredCart`). Ürün bilgisi bellekte tutulur: sepete
/// eklenen ürün hemen bilinir, açılışta bilinmeyenler (`missingProductIDs`) sepet ekranında
/// API'den alınıp `update(with:requestedIDs:)` ile verilir.
@Observable
final class CartStore {
    /// Ürün id'si → adet. Kaydedilen tek bilgi bu.
    private(set) var quantities: [Int: Int] = [:]
    /// Ürün id'si → ürün. Kaydedilmez; eklenen ya da API'den gelen ürünler.
    private var products: [Int: Product] = [:]

    @ObservationIgnored private let storage: PlistStorage
    @ObservationIgnored private let fileName = "cart.plist"

    init(storage: PlistStorage = PlistStorage()) {
        self.storage = storage
        load()
    }

    /// Ürün bilgisi bilinen satırlar.
    var items: [Int: CartItem] {
        quantities.reduce(into: [:]) { items, entry in
            if let product = products[entry.key] {
                items[entry.key] = CartItem(product: product, quantity: entry.value)
            }
        }
    }

    /// Sepette olup ürün bilgisi henüz gelmemiş id'ler (açılıştan sonra API'den istenir).
    var missingProductIDs: Set<Int> {
        Set(quantities.keys).subtracting(products.keys)
    }

    /// Sepet ekranında göstermek için ada göre sıralı satırlar.
    var sortedItems: [CartItem] {
        items.values.sorted { $0.product.title.localizedStandardCompare($1.product.title) == .orderedAscending }
    }

    var isEmpty: Bool {
        quantities.isEmpty
    }

    /// Tüm satırlardaki adetlerin toplamı (badge için). Ürün bilgisi gelmeden de doğrudur.
    var totalQuantity: Int {
        quantities.values.reduce(0, +)
    }

    var totalPrice: Double {
        items.values.reduce(0) { $0 + $1.lineTotal }
    }

    /// Ekranda gösterilen toplam; görünen satır toplamlarının toplamı olduğu için kuruşu kuruşuna tutar.
    func totalPrice(in currency: Currency) -> Double {
        items.values.reduce(0) { $0 + $1.lineTotal(in: currency) }.roundedToCents
    }

    func quantity(of product: Product) -> Int {
        quantities[product.id] ?? 0
    }

    /// Stok sınırına gelinmediyse ürünün bir adet daha eklenip eklenemeyeceği.
    func canAdd(_ product: Product) -> Bool {
        quantity(of: product) < product.stock
    }

    /// Ürün sepette yoksa 1 adetle ekler, varsa adedini artırır. Stoktan fazla eklenmez.
    func add(_ product: Product) {
        guard canAdd(product) else { return }
        quantities[product.id, default: 0] += 1
        if products[product.id] == nil {
            products[product.id] = product
        }
        save()
    }

    func increment(_ item: CartItem) {
        add(item.product)
    }

    /// Adedi bir azaltır; adet 0'a inerse satır sepetten çıkar.
    func decrement(_ item: CartItem) {
        guard let current = quantities[item.id] else { return }
        quantities[item.id] = current > 1 ? current - 1 : nil
        save()
    }

    func remove(_ item: CartItem) {
        quantities[item.id] = nil
        save()
    }

    /// API'den gelen ürünleri sepete işler. İstenip gelmeyen id'ler (API'de artık olmayan ürünler) sepetten çıkar.
    func update(with fetchedProducts: [Product], requestedIDs: Set<Int>) {
        for product in fetchedProducts where quantities[product.id] != nil {
            products[product.id] = product
        }
        let removedIDs = requestedIDs.subtracting(fetchedProducts.map(\.id))
        guard !removedIDs.isEmpty else { return }
        for id in removedIDs {
            quantities[id] = nil
        }
        save()
    }

    // MARK: - Kalıcılık

    private func load() {
        do {
            guard let stored = try storage.load(StoredCart.self, from: fileName) else { return }
            // Uygulamanın daha yeni bir sürümünün yazdığı dosya okunamaz; bozuk dosya gibi kenara alınır.
            guard stored.version <= StoredCart.currentVersion else {
                throw StoredRecordError.unsupportedVersion(stored.version)
            }
            quantities = stored.quantities.filter { $0.value > 0 }
        } catch {
            migrateLegacyFile(after: error)
        }
    }

    /// Eski biçim (`[Int: CartItem]`, ürünün tamamı) okunursa id ve adede çevrilip yeni biçimde kaydedilir;
    /// ürünler bu açılışta bellekte kalır. O da okunamazsa dosya kenara alınır, sepet boş başlar.
    private func migrateLegacyFile(after error: Error) {
        guard let legacy = try? storage.load([Int: CartItem].self, from: fileName) else {
            // Bozuk ya da bilinmeyen biçimdeki dosya, boş sepet kaydedilirken ezilmesin.
            print("Sepet yüklenemedi, dosya kenara alınıyor: \(error)")
            storage.moveAsideCorruptFile(fileName)
            return
        }
        quantities = legacy.mapValues(\.quantity).filter { $0.value > 0 }
        products = legacy.mapValues(\.product)
        save()
    }

    private func save() {
        do {
            try storage.save(StoredCart(quantities: quantities), to: fileName)
        } catch {
            print("Sepet kaydedilemedi: \(error)")
        }
    }
}
