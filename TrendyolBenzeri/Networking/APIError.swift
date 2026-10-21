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

    /// Ekranlarda gösterilen mesaj. `String` yerine kaynak tutulur ki dil değişince metin de değişsin.
    var message: LocalizedStringResource {
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

    var errorDescription: String? {
        String(localized: message)
    }
}

nonisolated extension Error {
    /// ViewModel'lerin `LoadState.failed` için kullandığı mesaj.
    var userMessage: LocalizedStringResource {
        (self as? APIError)?.message ?? "Beklenmeyen bir hata oluştu."
    }
}
