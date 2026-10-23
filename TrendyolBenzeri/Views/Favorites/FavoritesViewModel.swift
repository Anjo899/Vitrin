//
//  FavoritesViewModel.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Favorilerde saklanan id'lerin ürün bilgisini API'den alır. Dosyada yalnızca id'ler tutulduğu için
/// açılıştan sonra Favoriler ekranı ürünleri buradan ister; view sonucu `FavoritesStore`'a verir.
@Observable
final class FavoritesViewModel {
    private(set) var state: LoadState<[Product]> = .idle

    @ObservationIgnored private let service: ProductService

    init(service: ProductService = .shared) {
        self.service = service
    }

    /// Verilen id'lerin ürünlerini yükler. API'de artık olmayan ürünler sonuçta yer almaz.
    func loadProducts(ids: Set<Int>) async {
        guard !ids.isEmpty else { return }
        state = .loading
        do {
            state = .loaded(try await service.fetchProducts(ids: ids))
        } catch is CancellationError {
            if case .loading = state {
                state = .idle
            }
        } catch {
            state = .failed(error.userMessage)
        }
    }
}
