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
    /// Aşağı çekip yenileme başarısız olursa gösterilen geçici uyarı; liste ekranda kalır.
    private(set) var refreshError: LocalizedStringResource?

    @ObservationIgnored private let service: ProductService
    /// Arama isteği atılmadan önce beklenen süre (debounce). Testler beklememek için `.zero` verir.
    @ObservationIgnored private let searchDebounce: Duration
    /// En son istenen arama. Daha eski bir aramanın geç gelen sonucu bununla karşılaştırılıp atılır.
    @ObservationIgnored private var latestQuery = ""

    init(service: ProductService = .shared, searchDebounce: Duration = .milliseconds(400)) {
        self.service = service
        self.searchDebounce = searchDebounce
    }

    /// Ekran ilk açıldığında çağrılır; veri zaten yüklendiyse tekrar istek atmaz.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Tam ekran yükleme göstergesiyle yükler (ilk açılış ve "Tekrar Dene").
    func load() async {
        state = .loading
        refreshError = nil
        do {
            state = .loaded(try await fetchProducts())
        } catch is CancellationError {
            // Ekran yükleme sırasında kapandıysa bir sonraki açılışta yeniden denensin.
            if case .loading = state {
                state = .idle
            }
        } catch {
            state = .failed(error.userMessage)
        }
    }

    /// Aşağı çekip yenileme: mevcut liste yeni veri gelene kadar ekranda kalır.
    /// Hata olursa `state`'e dokunulmaz; hata `refreshError` ile geçici olarak gösterilir.
    func refresh() async {
        do {
            state = .loaded(try await fetchProducts())
            refreshError = nil
        } catch is CancellationError {
            // Yenileme iptal edildi; liste olduğu gibi kalır.
        } catch {
            refreshError = error.userMessage
        }
    }

    /// Banner süresi dolunca view çağırır.
    func dismissRefreshError() {
        refreshError = nil
    }

    /// Arama metni her değiştiğinde `.task(id:)` tarafından çağrılır. Metin değişince
    /// önceki görev iptal edildiği için bekleme sırasında gelen harfler istek attırmaz (debounce).
    func search(_ query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        latestQuery = trimmedQuery
        guard !trimmedQuery.isEmpty else {
            searchState = .idle
            return
        }

        // İptal edilmeyen eski bir arama ("Tekrar Dene" görevi gibi) veya iptalle aynı anda gelen
        // bir cevap, yenisinin sonucunu ezmesin.
        func isLatest() -> Bool {
            trimmedQuery == latestQuery && !Task.isCancelled
        }

        do {
            try await Task.sleep(for: searchDebounce)
            guard isLatest() else { return }
            searchState = .loading
            let products = try await service.searchProducts(query: trimmedQuery)
            guard isLatest() else { return }
            searchState = .loaded(products)
        } catch is CancellationError {
            // Kullanıcı yazmaya devam etti; yeni arama zaten başladı.
        } catch {
            guard isLatest() else { return }
            searchState = .failed(error.userMessage)
        }
    }

    private func fetchProducts() async throws -> [Product] {
        // limit=0 dummyjson'da "tüm ürünler" anlamına gelir (194 ürün).
        try await service.fetchProducts(limit: 0)
    }
}
