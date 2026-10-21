//
//  AppLanguage.swift
//  TrendyolBenzeri
//

import Foundation

/// Kullanıcının seçtiği arayüz dili. `rawValue`, `@AppStorage("appLanguage")` ile UserDefaults'a yazılır.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case turkish = "tr"
    case english = "en"

    /// `@AppStorage` anahtarı; uygulama kökü ve Ayarlar ekranı aynı değeri okur.
    static let storageKey = "appLanguage"

    var id: Self { self }

    /// Picker'daki ad. Dil adları her dilde kendi yazılışıyla gösterilir; yalnızca "Sistem" çevrilir.
    var title: LocalizedStringResource {
        switch self {
        case .system: "Sistem"
        case .turkish: "Türkçe"
        case .english: "English"
        }
    }

    /// Seçimin karşılık geldiği gerçek dil. "Sistem", cihazın birinci dilini takip eder;
    /// o dil Türkçe ya da İngilizce değilse Türkçe kullanılır.
    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard self == .system else { return self }
        let deviceLanguage = preferredLanguages.first.map { Locale(identifier: $0).language.languageCode?.identifier }
        return deviceLanguage == "en" ? .english : .turkish
    }

    /// Arayüze `.environment(\.locale, ...)` ile verilen locale. Metinler, sayılar ve tarihler buna göre çözülür.
    func locale(preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        switch resolved(preferredLanguages: preferredLanguages) {
        case .english: Locale(identifier: "en_US")
        default: Locale(identifier: "tr_TR")
        }
    }

    /// Fiyatların para birimi: İngilizcede API'deki dolar, Türkçede sabit kurla TL.
    func currency(preferredLanguages: [String] = Locale.preferredLanguages) -> Currency {
        switch resolved(preferredLanguages: preferredLanguages) {
        case .english: .dollar
        default: .lira
        }
    }
}
