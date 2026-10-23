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
    @State private var favoritesStore = FavoritesStore(storage: Self.storage)
    @State private var cartStore = CartStore(storage: Self.storage)
    /// Seçilen tema UserDefaults'ta saklanır; uygulama yeniden açılınca korunur.
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    /// Seçilen dil; değişince bütün arayüz yeniden başlatmadan yeni dile geçer.
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .system

    var body: some Scene {
        WindowGroup {
            if Self.isHostingUnitTests {
                // Unit testler uygulamayı host olarak açar; ekranlar yüklenip ağa çıkmasın.
                Color.clear
            } else {
                MainTabView()
                    .environment(favoritesStore)
                    .environment(cartStore)
                    // Kökte uygulandığı için sheet'ler dahil bütün pencereyi etkiler.
                    .preferredColorScheme(theme.colorScheme)
                    // Metinler, fiyatlar, sayılar ve tarihler bu locale'e göre çözülür.
                    .environment(\.locale, language.locale())
                    // Fiyatlar dile bağlı para biriminde gösterilir: Türkçe TL, İngilizce dolar.
                    .environment(\.currency, language.currency())
            }
        }
    }

    /// Unit testler çalışırken uygulama test host'u olarak açılır.
    private static let isHostingUnitTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    /// UI testleri uygulamayı `-uiTesting` argümanıyla açar; sepet ve favoriler boş başlar.
    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    /// Normalde Documents. Testlerde gerçek favori ve sepet dosyalarına dokunulmasın diye geçici klasör.
    private static let storage: PlistStorage = isHostingUnitTests || isUITesting ? temporaryStorage() : PlistStorage()

    private static func temporaryStorage() -> PlistStorage {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return PlistStorage(directory: directory)
    }
}
