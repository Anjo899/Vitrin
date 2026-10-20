//
//  CartStore.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Sepeti tutan paylaşılan store. Sepet sekmesindeki badge `totalQuantity`'yi gösterir.
@Observable
final class CartStore {
    /// Ürün id'si → sepet satırı.
    private(set) var items: [Int: CartItem] = [:]

    @ObservationIgnored private let storage: PlistStorage
    @ObservationIgnored private let fileName = "cart.plist"

    init(storage: PlistStorage = PlistStorage()) {
        self.storage = storage
        do {
            items = try storage.load([Int: CartItem].self, from: fileName) ?? [:]
        } catch {
            // Bozuk ya da eski formattaki dosya, boş sepet kaydedilirken ezilmesin.
            print("Sepet yüklenemedi, dosya kenara alınıyor: \(error)")
            storage.moveAsideCorruptFile(fileName)
        }
    }

    /// Sepet ekranında göstermek için ada göre sıralı satırlar.
    var sortedItems: [CartItem] {
        items.values.sorted { $0.product.title.localizedStandardCompare($1.product.title) == .orderedAscending }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    /// Tüm satırlardaki adetlerin toplamı (badge için).
    var totalQuantity: Int {
        items.values.reduce(0) { $0 + $1.quantity }
    }

    var totalPrice: Double {
        items.values.reduce(0) { $0 + $1.lineTotal }
    }

    /// Ekranda gösterilen toplam (TL); görünen satır toplamlarının toplamı olduğu için kuruşu kuruşuna tutar.
    var totalPriceInLira: Double {
        items.values.reduce(0) { $0 + $1.lineTotalInLira }.roundedToCents
    }

    func quantity(of product: Product) -> Int {
        items[product.id]?.quantity ?? 0
    }

    /// Stok sınırına gelinmediyse ürünün bir adet daha eklenip eklenemeyeceği.
    func canAdd(_ product: Product) -> Bool {
        quantity(of: product) < product.stock
    }

    /// Ürün sepette yoksa 1 adetle ekler, varsa adedini artırır. Stoktan fazla eklenmez.
    func add(_ product: Product) {
        guard canAdd(product) else { return }
        if var item = items[product.id] {
            item.quantity += 1
            items[product.id] = item
        } else {
            items[product.id] = CartItem(product: product, quantity: 1)
        }
        save()
    }

    func increment(_ item: CartItem) {
        add(item.product)
    }

    /// Adedi bir azaltır; adet 0'a inerse satır sepetten çıkar.
    func decrement(_ item: CartItem) {
        guard var current = items[item.id] else { return }
        current.quantity -= 1
        items[item.id] = current.quantity > 0 ? current : nil
        save()
    }

    func remove(_ item: CartItem) {
        items[item.id] = nil
        save()
    }

    private func save() {
        do {
            try storage.save(items, to: fileName)
        } catch {
            print("Sepet kaydedilemedi: \(error)")
        }
    }
}
