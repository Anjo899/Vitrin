//
//  PriceFormatter.swift
//  TrendyolBenzeri
//

import SwiftUI

/// dummyjson fiyatları dolar; Türkçede sabit kurla TL'ye çevrilmiş halleri gösterilir.
nonisolated enum ExchangeRate {
    /// 1 $ = 45 TL. Sabit bir değer; güncel kuru takip etmez.
    static let usdToTry: Double = 45
}

/// Ekrandaki para birimi. Seçilen dilden türetilir (`AppLanguage.currency()`), `rawValue` ISO kodu.
nonisolated enum Currency: String, CaseIterable, Sendable {
    case lira = "TRY"
    case dollar = "USD"

    /// API'deki dolar tutarını bu para birimine çevirip kuruşa yuvarlar.
    /// Dolar API değeriyle aynı kalır; TL sabit kurla hesaplanır, ör. 8.94 → 402.30.
    func amount(fromDollars dollars: Double) -> Double {
        switch self {
        case .lira: (dollars * ExchangeRate.usdToTry).roundedToCents
        case .dollar: dollars.roundedToCents
        }
    }

    /// Fiyat biçimi. Ayraçlar ve simge ekrandaki locale'e göre değişir:
    /// Türkçe "₺1.299,90", İngilizce "$1,299.90".
    var format: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: rawValue)
    }
}

extension EnvironmentValues {
    /// Uygulama kökünde seçilen dile göre verilir; fiyat gösteren view'lar buradan okur.
    @Entry var currency: Currency = .lira
}

nonisolated extension Double {
    /// Kuruşa (2 ondalık) yuvarlar, ör. 8.943048 → 8.94.
    var roundedToCents: Double {
        (self * 100).rounded() / 100
    }
}

nonisolated extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
    /// İndirim rozeti biçimi: Türkçe "%10", İngilizce "10%".
    static var discount: Self {
        .percent.precision(.fractionLength(0))
    }
}

nonisolated extension Product {
    /// Liste fiyatı, verilen para biriminde.
    func price(in currency: Currency) -> Double {
        currency.amount(fromDollars: price)
    }

    /// İndirimli birim fiyat, verilen para biriminde. Sepet satırları ve toplam bundan hesaplanır.
    func discountedPrice(in currency: Currency) -> Double {
        currency.amount(fromDollars: discountedPrice)
    }

    /// Rozette gösterilen oran, tam yüzdeye yuvarlanmış: 10.48 → 0.10.
    var discountRate: Double {
        discountPercentage.rounded() / 100
    }
}
