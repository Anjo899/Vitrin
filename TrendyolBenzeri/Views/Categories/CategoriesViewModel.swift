//
//  CategoriesViewModel.swift
//  TrendyolBenzeri
//

import Foundation
import Observation

@Observable
final class CategoriesViewModel {
    private(set) var state: LoadState<[ProductCategory]> = .idle

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
        await fetchCategories()
    }

    func refresh() async {
        await fetchCategories()
    }

    private func fetchCategories() async {
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
}
