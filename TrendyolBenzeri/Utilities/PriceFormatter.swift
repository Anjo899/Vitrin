//
//  PriceFormatter.swift
//  TrendyolBenzeri
//

import Foundation

/// dummyjson fiyatları dolar; ekranda sabit kurla TL'ye çevrilmiş halleri gösterilir.
nonisolated enum ExchangeRate {
    /// 1 $ = 45 TL. Sabit bir değer; güncel kuru takip etmez.
    static let usdToTry: Double = 45
}

nonisolated extension Double {
    /// Kuruşa (2 ondalık) yuvarlar, ör. 8.943048 → 8.94.
    var roundedToCents: Double {
        (self * 100).rounded() / 100
    }

    /// Dolar tutarını sabit kurla TL'ye çevirip kuruşa yuvarlar, ör. 8.94 → 402.30.
    var convertedToLira: Double {
        (self * ExchangeRate.usdToTry).roundedToCents
    }
}

nonisolated extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    /// Fiyat biçimi. Ayraçlar ve simge ekrandaki locale'e göre değişir:
    /// Türkçe "₺1.299,90", İngilizce "TRY 1,299.90".
    static var lira: Self {
        .currency(code: "TRY")
    }
}

nonisolated extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
    /// İndirim rozeti biçimi: Türkçe "%10", İngilizce "10%".
    static var discount: Self {
        .percent.precision(.fractionLength(0))
    }
}

nonisolated extension Product {
    /// Liste fiyatı, TL.
    var priceInLira: Double {
        price.convertedToLira
    }

    /// İndirimli birim fiyat, TL. Sepet satırları ve toplam bundan hesaplanır.
    var discountedPriceInLira: Double {
        discountedPrice.convertedToLira
    }

    /// Rozette gösterilen oran, tam yüzdeye yuvarlanmış: 10.48 → 0.10.
    var discountRate: Double {
        discountPercentage.rounded() / 100
    }
}
