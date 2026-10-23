//
//  CategoryProductsViewModel.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

/// Seçilen kategorinin ürünlerini yükler.
@Observable
final class CategoryProductsViewModel {
    let category: ProductCategory
    private(set) var state: LoadState<[Product]> = .idle
    /// Aşağı çekip yenileme başarısız olursa gösterilen geçici uyarı; liste ekranda kalır.
    private(set) var refreshError: LocalizedStringResource?

    @ObservationIgnored private let service: ProductService

    init(category: ProductCategory, service: ProductService = .shared) {
        self.category = category
        self.service = service
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        state = .loading
        refreshError = nil
        do {
            state = .loaded(try await service.fetchProducts(in: category))
        } catch is CancellationError {
            if case .loading = state {
                state = .idle
            }
        } catch {
            state = .failed(error.userMessage)
        }
    }

    /// Hata olursa `state`'e dokunulmaz; liste kalır, hata `refreshError` ile geçici olarak gösterilir.
    func refresh() async {
        do {
            state = .loaded(try await service.fetchProducts(in: category))
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
}
