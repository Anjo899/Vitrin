//
//  APIClient.swift
//  TrendyolBenzeri
//

import Foundation

/// dummyjson.com'a GET isteği atıp cevabı istenen tipe çeviren küçük istemci.
nonisolated struct APIClient: Sendable {
    static let shared = APIClient()

    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = URL(string: "https://dummyjson.com")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError where error.code == .cancelled {
            // Ekran kapanınca veya arama metni değişince iptal edilen istekler hata ekranı göstermesin.
            throw CancellationError()
        } catch {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.badStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder.dummyJSON.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

extension JSONDecoder {
    /// Yorum tarihleri "2025-04-30T09:41:02.053Z" gibi salise içeren ISO 8601 metinleri.
    nonisolated static var dummyJSON: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) {
                return date
            }
            if let date = try? Date.ISO8601FormatStyle().parse(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Geçersiz tarih: \(string)")
        }
        return decoder
    }
}
