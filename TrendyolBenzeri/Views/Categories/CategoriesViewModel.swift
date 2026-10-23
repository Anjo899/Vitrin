//
//  CategoriesViewModel.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

@Observable
final class CategoriesViewModel {
    private(set) var state: LoadState<[ProductCategory]> = .idle
    /// Aşağı çekip yenileme başarısız olursa gösterilen geçici uyarı; liste ekranda kalır.
    private(set) var refreshError: LocalizedStringResource?

    @ObservationIgnored private let service: ProductService

    init(service: ProductService = .shared) {
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
            // Sıralama seçilen dile bağlı olduğu için view'da yapılır.
            state = .loaded(try await service.fetchCategories())
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
            state = .loaded(try await service.fetchCategories())
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
