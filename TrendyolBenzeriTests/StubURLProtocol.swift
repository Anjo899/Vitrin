//
//  StubURLProtocol.swift
//  TrendyolBenzeriTests
//

import Foundation
@testable import TrendyolBenzeri

/// Sahte sunucunun bir isteğe vereceği cevap.
enum StubResponse: Sendable {
    /// Durum kodu ve gövde.
    case body(String, status: Int = 200)
    /// Bağlantı hatası, ör. `.notConnectedToInternet` ya da `.cancelled`.
    case failure(URLError.Code)

    /// `/products` uçlarının cevabı; her başlık için bir ürün.
    static func products(_ titles: [String]) -> StubResponse {
        let products = titles.enumerated().map { index, title in
            """
            {"id":\(index + 1),"title":"\(title)","description":"","category":"beauty",
            "price":10,"discountPercentage":0,"rating":4,"stock":5,
            "thumbnail":"https://example.com/t.webp","images":[],"reviews":[]}
            """
        }
        return .body("""
        {"products":[\(products.joined(separator: ","))],"total":\(titles.count),"skip":0,"limit":\(titles.count)}
        """)
    }

    /// `/products/categories` cevabı; her slug için bir kategori.
    static func categories(_ slugs: [String]) -> StubResponse {
        let categories = slugs.map { slug in
            #"{"slug":"\#(slug)","name":"\#(slug)","url":"https://example.com/\#(slug)"}"#
        }
        return .body("[\(categories.joined(separator: ","))]")
    }
}

/// Testlere özel sahte sunucu. Her örnek kendi host'unu (`<uuid>.stub`) kaydeder;
/// böylece paralel çalışan testlerin cevapları birbirine karışmaz.
/// Cevap `async` bir closure'dan gelir: test, bir `Gate` ile cevabı istediği ana kadar bekletebilir.
final class StubServer: @unchecked Sendable {
    let host = "\(UUID().uuidString.lowercased()).stub"

    private let respond: @Sendable (URLRequest) async -> StubResponse
    private let lock = NSLock()
    private var receivedRequests: [URLRequest] = []

    init(respond: @escaping @Sendable (URLRequest) async -> StubResponse) {
        self.respond = respond
        StubURLProtocol.register(self)
    }

    /// Her isteğe aynı cevabı veren sunucu.
    convenience init(_ response: StubResponse) {
        self.init { _ in response }
    }

    /// Bu sunucuya istek atan, gerçek ağa çıkamayan istemci.
    var client: APIClient {
        APIClient(baseURL: URL(string: "https://\(host)")!, session: StubURLProtocol.session)
    }

    var service: ProductService {
        ProductService(client: client)
    }

    /// Sunucuya gelen istekler, geliş sırasıyla.
    var requests: [URLRequest] {
        lock.withLock { receivedRequests }
    }

    fileprivate func handle(_ request: URLRequest) async -> StubResponse {
        lock.withLock { receivedRequests.append(request) }
        return await respond(request)
    }
}

/// Testin akışını sıraya koymak için tek seferlik kapı: `wait()` kapı açılana kadar bekler.
/// Testler zamanla değil bununla sıralanır (ARCHITECTURE.md 9. Testler).
actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}

/// `URLSession` isteklerini kayıtlı `StubServer`'lara yönlendirir. Kayıtlı olmayan
/// host'a giden istek hata alır; bu oturumla hiçbir istek gerçek ağa çıkamaz.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    nonisolated(unsafe) private static var servers: [String: StubServer] = [:]
    private static let lock = NSLock()

    fileprivate static func register(_ server: StubServer) {
        lock.withLock { servers[server.host] = server }
    }

    private static func server(for host: String?) -> StubServer? {
        lock.withLock { host.flatMap { servers[$0] } }
    }

    private var loadingTask: Task<Void, Never>?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let request = self.request
        loadingTask = Task { [weak self] in
            let response = await Self.server(for: request.url?.host())?.handle(request)
                ?? .failure(.cannotFindHost)
            guard !Task.isCancelled else { return }
            self?.deliver(response, for: request)
        }
    }

    override func stopLoading() {
        loadingTask?.cancel()
    }

    private func deliver(_ response: StubResponse, for request: URLRequest) {
        guard let client else { return }
        switch response {
        case .body(let body, let status):
            let httpResponse = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
            )!
            client.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: Data(body.utf8))
            client.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client.urlProtocol(self, didFailWithError: URLError(code))
        }
    }
}

extension URLRequest {
    /// Sorgudaki bir parametrenin değeri, ör. `q`.
    func queryValue(_ name: String) -> String? {
        url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?.first { $0.name == name }?.value
    }
}
