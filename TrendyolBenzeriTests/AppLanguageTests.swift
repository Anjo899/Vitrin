//
//  AppLanguageTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import SwiftUI
import Testing
@testable import TrendyolBenzeri

struct AppLanguageTests {

    // MARK: - "Sistem" seçeneğinin çözümü

    @Test(arguments: [
        (["tr-TR"], AppLanguage.turkish),
        (["tr"], .turkish),
        (["en-US"], .english),
        (["en-GB", "tr-TR"], .english),
        // Cihaz dili desteklenmiyorsa ikinci dile bakılmaz, Türkçe kullanılır.
        (["de-DE", "en-US"], .turkish),
        (["ja-JP"], .turkish),
        ([], .turkish),
    ])
    func systemResolvesToDeviceLanguage(preferredLanguages: [String], expected: AppLanguage) {
        #expect(AppLanguage.system.resolved(preferredLanguages: preferredLanguages) == expected)
    }

    @Test func explicitChoiceIgnoresDeviceLanguage() {
        #expect(AppLanguage.english.resolved(preferredLanguages: ["tr-TR"]) == .english)
        #expect(AppLanguage.turkish.resolved(preferredLanguages: ["en-US"]) == .turkish)
    }

    @Test func localeMatchesResolvedLanguage() {
        #expect(AppLanguage.system.locale(preferredLanguages: ["en-US"]).identifier == "en_US")
        #expect(AppLanguage.system.locale(preferredLanguages: ["de-DE"]).identifier == "tr_TR")
        #expect(AppLanguage.turkish.locale(preferredLanguages: ["en-US"]).identifier == "tr_TR")
    }

    // MARK: - Kalıcılık

    /// `@AppStorage`'a yazılan değerler değişirse kayıtlı seçim kaybolur.
    @Test func rawValuesAreStable() {
        #expect(AppLanguage.allCases.map(\.rawValue) == ["system", "tr", "en"])
    }

    @MainActor
    @Test func selectionPersistsInUserDefaults() throws {
        let suiteName = "AppLanguageTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Ayarlar ekranındakiyle aynı tanım: önce varsayılan "Sistem".
        let storage = AppStorage(wrappedValue: AppLanguage.system, AppLanguage.storageKey, store: defaults)
        #expect(storage.wrappedValue == .system)

        storage.wrappedValue = .english
        #expect(defaults.string(forKey: AppLanguage.storageKey) == "en")

        // Uygulama yeniden açılınca yeni bir `AppStorage` aynı değeri okur.
        let reopened = AppStorage(wrappedValue: AppLanguage.system, AppLanguage.storageKey, store: defaults)
        #expect(reopened.wrappedValue == .english)
    }
}
