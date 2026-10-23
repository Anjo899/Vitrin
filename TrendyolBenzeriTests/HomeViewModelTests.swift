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
        let server = StubServer(.products(["unexpected"]))
        let viewModel = HomeViewModel(service: server.service, searchDebounce: .zero)

        await viewModel.search(query)

        guard case .idle = viewModel.searchState else {
            Issue.record("Boş arama idle kalmalıydı, durum: \(viewModel.searchState)")
            return
        }
        #expect(server.requests.isEmpty)
    }

    @Test func searchSendsQueryAndShowsResults() async {
        let server = StubServer { request in .products(["\(request.queryValue("q") ?? "") result"]) }
        let viewModel = HomeViewModel(service: server.service, searchDebounce: .zero)

        await viewModel.search("  phone ")

        guard case .loaded(let products) = viewModel.searchState else {
            Issue.record("Sonuç yüklenmiş olmalıydı, durum: \(viewModel.searchState)")
            return
        }
        #expect(products.map(\.title) == ["phone result"])
        #expect(server.requests.map { $0.url?.path() } == ["/products/search"])
    }

    @Test func failedSearchShowsError() async {
        let server = StubServer(.body("", status: 500))
        let viewModel = HomeViewModel(service: server.service, searchDebounce: .zero)

        await viewModel.search("phone")

        guard case .failed = viewModel.searchState else {
            Issue.record("Arama hatası gösterilmeliydi, durum: \(viewModel.searchState)")
            return
        }
    }

    /// "Tekrar Dene" gibi iptal edilmeyen eski bir arama, yeni aramadan sonra bitse bile
    /// sonucu ekrana yazılmamalı.
    @Test func staleSearchResultDoesNotOverwriteNewerQuery() async {
        let oldRequestArrived = Gate()
        let releaseOldResponse = Gate()
        let server = StubServer { request in
            let query = request.queryValue("q") ?? ""
            if query == "old" {
                // Eski aramanın cevabı, yeni arama bitene kadar bekletilir; böylece en son o gelir.
                await oldRequestArrived.open()
                await releaseOldResponse.wait()
            }
            return .products(["\(query) result"])
        }
        let viewModel = HomeViewModel(service: server.service, searchDebounce: .zero)

        async let oldSearch: Void = viewModel.search("old")
        await oldRequestArrived.wait()
        await viewModel.search("new")
        await releaseOldResponse.open()
        await oldSearch

        guard case .loaded(let products) = viewModel.searchState else {
            Issue.record("Sonuç yüklenmiş olmalıydı, durum: \(viewModel.searchState)")
            return
        }
        #expect(products.map(\.title) == ["new result"])
    }
}
