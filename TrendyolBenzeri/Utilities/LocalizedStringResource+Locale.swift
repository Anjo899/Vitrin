//
//  LocalizedStringResource+Locale.swift
//  TrendyolBenzeri
//

import Foundation

nonisolated extension LocalizedStringResource {
    /// Metni verilen dilde `String` olarak çözer (sıralama ve testler için).
    /// `String(localized:locale:)` metni yine cihaz dilinde aradığı için locale kaynağın kendisine verilir.
    func resolved(in locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
