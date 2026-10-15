//
//  HomeViewModelTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

@MainActor
struct HomeViewModelTests {

    @Test(arguments: ["", "   ", "\n"])
    func blankSearchStaysIdleWithoutRequest(query: String) async {
        // Geçersiz bir adres: istek atılırsa hata olur ve state `.failed`'a düşer.
        let client = APIClient(baseURL: URL(string: "https://invalid.example")!)
        let viewModel = HomeViewModel(service: ProductService(client: client))

        await viewModel.search(query)

        guard case .idle = viewModel.searchState else {
            Issue.record("Boş arama idle kalmalıydı, durum: \(viewModel.searchState)")
            return
        }
    }
}
