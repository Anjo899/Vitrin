//
//  CartStore+Refresh.swift
//  TrendyolBenzeri
//

import Foundation

extension CartStore {
    /// Sepetteki bütün ürünleri (yalnızca eksikleri değil) ViewModel ile API'den alır ve sonucu işler:
    /// fiyat ve stok güncellenir, adet stoğa iner, API'de olmayan ürün çıkar. Sepet ekranı her görünüşte çağırır.
    /// View katmanında durur; çünkü hem store'u hem ViewModel'i kullanır (ARCHITECTURE.md 1).
    func refreshProducts(using viewModel: CartViewModel) async {
        let ids = productIDs
        guard !ids.isEmpty else { return }
        await viewModel.loadProducts(ids: ids)
        if case .loaded(let products) = viewModel.state {
            update(with: products, requestedIDs: ids)
        }
    }
}
