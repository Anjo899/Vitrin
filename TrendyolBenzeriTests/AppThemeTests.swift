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
        #expect(turkish == ["Sistem", "Açık", "Koyu"])
    }

    /// `@AppStorage`'a yazılan değerler değişirse kayıtlı seçim kaybolur.
    @Test func rawValuesAreStable() {
        #expect(AppTheme.allCases.map(\.rawValue) == ["system", "light", "dark"])
        #expect(AppTheme(rawValue: "dark") == .dark)
    }
}
