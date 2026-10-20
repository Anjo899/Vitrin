//
//  TrendyolBenzeriApp.swift
//  TrendyolBenzeri
//
//  Created by skilic on 15.10.2026.
//

import SwiftUI

@main
struct TrendyolBenzeriApp: App {
    /// Ekranlar arası paylaşılan store'lar burada bir kez oluşturulur.
    @State private var favoritesStore = FavoritesStore()
    @State private var cartStore = CartStore()
    /// Seçilen tema UserDefaults'ta saklanır; uygulama yeniden açılınca korunur.
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    /// Seçilen dil; değişince bütün arayüz yeniden başlatmadan yeni dile geçer.
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .system

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(favoritesStore)
                .environment(cartStore)
                // Kökte uygulandığı için sheet'ler dahil bütün pencereyi etkiler.
                .preferredColorScheme(theme.colorScheme)
                // Metinler, fiyatlar, sayılar ve tarihler bu locale'e göre çözülür.
                .environment(\.locale, language.locale())
        }
    }
}
