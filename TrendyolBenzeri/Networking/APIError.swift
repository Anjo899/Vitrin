//
//  APIError.swift
//  TrendyolBenzeri
//

import Foundation

nonisolated enum APIError: LocalizedError {
    case invalidURL
    case network(Error)
    case badStatus(Int)
    case decoding(Error)

    /// Ekranlarda kullanıcıya gösterilecek Türkçe mesajlar.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "İstek adresi geçersiz."
        case .network:
            "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene."
        case .badStatus(let code):
            "Sunucu beklenmedik bir cevap verdi (\(code))."
        case .decoding:
            "Gelen veri okunamadı."
        }
    }
}
