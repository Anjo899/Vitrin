//
//  ViewModelLoadingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// ViewModel'lerin yükleme, yenileme ve iptal geçişleri (ARCHITECTURE.md 4, REVIEW.md T1, O11).
///
/// O11 için iki test var: biri bugünkü davranışı belgeler, diğeri `ARCHITECTURE.md`'deki doğru
/// davranışı test eder ve şimdilik kapalıdır. Düzeltme Adım 6'da yapılacak; o zaman kapalı test
/// açılır, bugünkü davranışı belgeleyen test silinir.
private let o11Reason: Comment = """
    O11: yenileme hatası bugün listeyi `.failed` ile değiştiriyor. Düzeltme Adım 6'da yapılacak; \
    o zaman bu test açılır ve "bugünkü davranış" testi silinir.
    """

@MainActor
struct HomeViewModelLoadingTests {

    @Test func loadShowsAllProducts() async throws {
        let server = StubServer(.products(["A", "B"]))
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["A", "B"])
        // `limit=0` dummyjson'da tüm ürünler demek.
        let request = try #require(server.requests.first)
        #expect(request.url?.path() == "/products")
        #expect(request.queryValue("limit") == "0")
    }

    @Test func loadFailureShowsErrorMessage() async {
        let server = StubServer(.body("", status: 500))
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.failureMessage == "Sunucu beklenmedik bir cevap verdi (500).")
    }

    @Test func loadIfNeededDoesNotRequestAgain() async {
        let server = StubServer(.products(["A"]))
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(viewModel.state.loadedValue?.count == 1)
        #expect(server.requests.count == 1)
    }

    /// İptal hata sayılmaz; ekran bir sonraki açılışta yeniden yüklesin diye `.idle`'a döner.
    @Test func cancelledLoadReturnsToIdle() async {
        let server = StubServer(.failure(.cancelled))
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.isIdle)
    }

    @Test func cancelledRefreshKeepsList() async {
        let server = StubServer(sequence: [.products(["A"]), .failure(.cancelled)])
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["A"])
    }

    /// Yenileme sırasında `.loading`'e geçilmez; mevcut liste cevap gelene kadar ekranda kalır.
    @Test func refreshKeepsListWhileWaiting() async {
        let refreshArrived = Gate()
        let releaseRefresh = Gate()
        let server = StubServer(sequence: [.products(["A"])])
        let viewModel = HomeViewModel(service: server.service)
        await viewModel.load()
        server.onRequest = {
            await refreshArrived.open()
            await releaseRefresh.wait()
        }

        async let refresh: Void = viewModel.refresh()
        await refreshArrived.wait()
        #expect(viewModel.state.loadedValue?.map(\.title) == ["A"])
        await releaseRefresh.open()
        await refresh
    }

    @Test func refreshReplacesListOnSuccess() async {
        let server = StubServer(sequence: [.products(["A"]), .products(["A", "B"])])
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["A", "B"])
    }

    @Test("O11 bugünkü davranış: yenileme hatası listeyi hata ekranıyla değiştirir")
    func refreshFailureReplacesListCurrentBehavior() async {
        let server = StubServer(sequence: [.products(["A"]), .body("", status: 500)])
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.isFailed)
    }

    @Test("Yenileme hatası mevcut listeyi silmez", .disabled(o11Reason))
    func refreshFailureKeepsList() async {
        let server = StubServer(sequence: [.products(["A"]), .body("", status: 500)])
        let viewModel = HomeViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["A"])
    }
}

@MainActor
struct CategoriesViewModelTests {

    @Test func loadShowsCategories() async {
        let server = StubServer(.categories(["beauty", "laptops"]))
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.loadedValue?.map(\.slug) == ["beauty", "laptops"])
    }

    @Test func loadFailureShowsErrorMessage() async {
        let server = StubServer(.failure(.notConnectedToInternet))
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.failureMessage
            == "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.")
    }

    @Test func loadIfNeededDoesNotRequestAgain() async {
        let server = StubServer(.categories(["beauty"]))
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(server.requests.count == 1)
    }

    @Test func cancelledLoadReturnsToIdle() async {
        let server = StubServer(.failure(.cancelled))
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.load()

        #expect(viewModel.state.isIdle)
    }

    @Test("O11 bugünkü davranış: yenileme hatası listeyi hata ekranıyla değiştirir")
    func refreshFailureReplacesListCurrentBehavior() async {
        let server = StubServer(sequence: [.categories(["beauty"]), .body("", status: 500)])
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.isFailed)
    }

    @Test("Yenileme hatası mevcut listeyi silmez", .disabled(o11Reason))
    func refreshFailureKeepsList() async {
        let server = StubServer(sequence: [.categories(["beauty"]), .body("", status: 500)])
        let viewModel = CategoriesViewModel(service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.loadedValue?.map(\.slug) == ["beauty"])
    }
}

@MainActor
struct CategoryProductsViewModelTests {

    private let category = ProductCategory(slug: "beauty", name: "Beauty", url: URL(string: "https://example.com")!)

    @Test func loadShowsCategoryProducts() async {
        let server = StubServer(.products(["Lipstick"]))
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.load()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["Lipstick"])
        #expect(server.requests.first?.url?.path() == "/products/category/beauty")
    }

    @Test func loadFailureShowsErrorMessage() async {
        let server = StubServer(.body("not json"))
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.load()

        #expect(viewModel.state.failureMessage == "Gelen veri okunamadı.")
    }

    @Test func loadIfNeededDoesNotRequestAgain() async {
        let server = StubServer(.products(["Lipstick"]))
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(server.requests.count == 1)
    }

    @Test func cancelledLoadReturnsToIdle() async {
        let server = StubServer(.failure(.cancelled))
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.load()

        #expect(viewModel.state.isIdle)
    }

    @Test("O11 bugünkü davranış: yenileme hatası listeyi hata ekranıyla değiştirir")
    func refreshFailureReplacesListCurrentBehavior() async {
        let server = StubServer(sequence: [.products(["Lipstick"]), .body("", status: 500)])
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.isFailed)
    }

    @Test("Yenileme hatası mevcut listeyi silmez", .disabled(o11Reason))
    func refreshFailureKeepsList() async {
        let server = StubServer(sequence: [.products(["Lipstick"]), .body("", status: 500)])
        let viewModel = CategoryProductsViewModel(category: category, service: server.service)

        await viewModel.load()
        await viewModel.refresh()

        #expect(viewModel.state.loadedValue?.map(\.title) == ["Lipstick"])
    }
}

// MARK: - Yardımcılar

@MainActor
extension LoadState {
    var loadedValue: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    var isIdle: Bool {
        if case .idle = self { true } else { false }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    var isFailed: Bool {
        if case .failed = self { true } else { false }
    }

    /// Hata mesajı, Türkçe çözülmüş hali.
    var failureMessage: String? {
        if case .failed(let message) = self { message.resolved(in: Locale(identifier: "tr_TR")) } else { nil }
    }
}
