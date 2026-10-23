//
//  FavoritesStore+Refresh.swift
//  TrendyolBenzeri
//

import Foundation

extension FavoritesStore {
    /// Bütün favori ürünleri (yalnızca eksikleri değil) ViewModel ile API'den alır ve sonucu işler;
    /// API'de olmayan ürün çıkar. Favoriler ekranı her görünüşte çağırır.
    /// View katmanında durur; çünkü hem store'u hem ViewModel'i kullanır (ARCHITECTURE.md 1).
    func refreshProducts(using viewModel: FavoritesViewModel) async {
        let ids = self.ids
        guard !ids.isEmpty else { return }
        await viewModel.loadProducts(ids: ids)
        if case .loaded(let products) = viewModel.state {
            update(with: products, requestedIDs: ids)
        }
    }
}
