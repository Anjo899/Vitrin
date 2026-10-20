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

    /// "Tekrar Dene" gibi iptal edilmeyen eski bir arama, yeni aramadan sonra bitse bile
    /// sonucu ekrana yazılmamalı.
    @Test func staleSearchResultDoesNotOverwriteNewerQuery() async throws {
        let client = APIClient(session: SearchStubURLProtocol.makeSession())
        let viewModel = HomeViewModel(service: ProductService(client: client))

        // "old" cevabı 0,8 sn gecikir; "new" hemen gelir. Böylece eski cevap en son ulaşır.
        async let oldSearch: Void = viewModel.search("old")
        try await Task.sleep(for: .milliseconds(100))
        await viewModel.search("new")
        await oldSearch

        guard case .loaded(let products) = viewModel.searchState else {
            Issue.record("Sonuç yüklenmiş olmalıydı, durum: \(viewModel.searchState)")
            return
        }
        #expect(products.map(\.title) == ["new result"])
    }
}

/// Arama ucunu taklit eder: `q=old` cevabını geciktirir, diğerlerini hemen döndürür.
final class SearchStubURLProtocol: URLProtocol {
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SearchStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "q" }?.value ?? ""
        let delay: TimeInterval = query == "old" ? 0.8 : 0
        let body = Data("""
        {"products":[{"id":1,"title":"\(query) result","description":"","category":"beauty",
        "price":1,"discountPercentage":0,"rating":4,"stock":1,
        "thumbnail":"https://example.com/t.webp","images":[],"reviews":[]}],
        "total":1,"skip":0,"limit":1}
        """.utf8)

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, let client = self.client else { return }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: body)
            client.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
