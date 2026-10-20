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
        await fetchProducts()
    }

    func refresh() async {
        await fetchProducts()
    }

    private func fetchProducts() async {
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
}
