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
            let categories = try await service.fetchCategories()
            // Türkçe adlara göre, Türkçe alfabe sırasıyla (Ç, Ö, Ü doğru yerde).
            let turkish = Locale(identifier: "tr_TR")
            state = .loaded(categories.sorted {
                $0.displayName.compare($1.displayName, locale: turkish) == .orderedAscending
            })
        } catch is CancellationError {
            if case .loading = state {
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
