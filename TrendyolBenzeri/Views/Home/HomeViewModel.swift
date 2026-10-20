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
    /// Arama sonuçları; arama metni boşken `idle` kalır ve tüm ürünler gösterilir.
    private(set) var searchState: LoadState<[Product]> = .idle

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

    /// Arama metni her değiştiğinde `.task(id:)` tarafından çağrılır. Metin değişince
    /// önceki görev iptal edildiği için bekleme sırasında gelen harfler istek attırmaz (debounce).
    func search(_ query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchState = .idle
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(400))
            searchState = .loading
            let products = try await service.searchProducts(query: trimmedQuery)
            searchState = .loaded(products)
        } catch is CancellationError {
            // Kullanıcı yazmaya devam etti; yeni arama zaten başladı.
        } catch {
            searchState = .failed(error.localizedDescription)
        }
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
