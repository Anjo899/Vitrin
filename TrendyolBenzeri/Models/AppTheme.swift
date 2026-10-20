//
//  AppTheme.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Kullanıcının seçtiği görünüm. `rawValue`, `@AppStorage("appTheme")` ile UserDefaults'a yazılır.
nonisolated enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    /// `@AppStorage` anahtarı; uygulama kökü ve Ayarlar ekranı aynı değeri okur.
    static let storageKey = "appTheme"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Sistem"
        case .light: "Açık"
        case .dark: "Koyu"
        }
    }

    /// `.preferredColorScheme` için değer. `nil`, cihazın ayarını takip etmek demek.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
