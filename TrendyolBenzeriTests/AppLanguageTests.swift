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

    /// Para birimi dile bağlı: Türkçe TL, İngilizce dolar; "Sistem" çözümlendiği dile göre.
    @Test func currencyFollowsResolvedLanguage() {
        #expect(AppLanguage.turkish.currency(preferredLanguages: ["en-US"]) == .lira)
        #expect(AppLanguage.english.currency(preferredLanguages: ["tr-TR"]) == .dollar)
        #expect(AppLanguage.system.currency(preferredLanguages: ["en-GB"]) == .dollar)
        #expect(AppLanguage.system.currency(preferredLanguages: ["tr-TR"]) == .lira)
        #expect(AppLanguage.system.currency(preferredLanguages: ["de-DE"]) == .lira)
        #expect(Currency.lira.rawValue == "TRY")
        #expect(Currency.dollar.rawValue == "USD")
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
