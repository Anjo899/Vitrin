//
//  AppThemeTests.swift
//  TrendyolBenzeriTests
//

import SwiftUI
import Testing
@testable import TrendyolBenzeri

struct AppThemeTests {

    @Test func systemFollowsDevice() {
        #expect(AppTheme.system.colorScheme == nil)
    }

    @Test func lightAndDarkForceColorScheme() {
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
    }

    @Test func titlesAreLocalized() {
        let turkish = AppTheme.allCases.map { $0.title.resolved(in: Locale(identifier: "tr_TR")) }
        let english = AppTheme.allCases.map { $0.title.resolved(in: Locale(identifier: "en_US")) }
        #expect(turkish == ["Sistem", "Açık", "Koyu"])
        #expect(english == ["System", "Light", "Dark"])
    }

    /// `@AppStorage`'a yazılan değerler değişirse kayıtlı seçim kaybolur.
    @Test func rawValuesAreStable() {
        #expect(AppTheme.allCases.map(\.rawValue) == ["system", "light", "dark"])
        #expect(AppTheme(rawValue: "dark") == .dark)
    }

    @MainActor
    @Test func selectionPersistsInUserDefaults() throws {
        let suiteName = "AppThemeTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Kökteki ve Ayarlar ekranındaki tanımla aynı: önce varsayılan "Sistem".
        let storage = AppStorage(wrappedValue: AppTheme.system, AppTheme.storageKey, store: defaults)
        #expect(storage.wrappedValue == .system)

        storage.wrappedValue = .dark
        #expect(defaults.string(forKey: AppTheme.storageKey) == "dark")

        // Uygulama yeniden açılınca yeni bir `AppStorage` aynı değeri okur.
        let reopened = AppStorage(wrappedValue: AppTheme.system, AppTheme.storageKey, store: defaults)
        #expect(reopened.wrappedValue == .dark)
    }

    /// Tema ve dil ayrı anahtarlarda saklanır; biri diğerini ezmez.
    @Test func storageKeyDiffersFromLanguage() {
        #expect(AppTheme.storageKey == "appTheme")
        #expect(AppTheme.storageKey != AppLanguage.storageKey)
    }
}
