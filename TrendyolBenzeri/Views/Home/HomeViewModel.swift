//
//  HomeViewModel.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Ana sayfanın verisini yükler. Sadece bu ekrana ait olduğu için environment'a değil,
/// `HomeView` içinde `@State` olarak tutulur.
@Observable
final class HomeViewModel {
    private(set) var state: LoadState<[Product]> = .idle

    @ObservationIgnored private let service: ProductService

    init(service: ProductService = .shared) {
        self.service = service
    }

    /// Ekran ilk açıldığında çağrılır; veri zaten yüklendiyse tekrar istek atmaz.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Tam ekran yükleme göstergesiyle yükler (ilk açılış ve "Tekrar Dene").
    func load() async {
        state = .loading
        await fetchProducts()
    }

    /// Aşağı çekip yenileme: mevcut liste yeni veri gelene kadar ekranda kalır.
    func refresh() async {
        await fetchProducts()
    }

    private func fetchProducts() async {
        do {
            // limit=0 dummyjson'da "tüm ürünler" anlamına gelir (194 ürün).
            let products = try await service.fetchProducts(limit: 0)
            state = .loaded(products)
        } catch is CancellationError {
            // Ekran yükleme sırasında kapandıysa bir sonraki açılışta yeniden denensin.
            if case .loading = state {
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
