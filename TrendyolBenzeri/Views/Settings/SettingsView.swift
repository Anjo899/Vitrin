//
//  SettingsView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Uygulama ayarları. Ana Sayfa'daki dişli butonuyla sheet olarak açılır.
struct SettingsView: View {
    /// Kök view da aynı anahtarı okuduğu için seçim anında tüm uygulamaya yansır.
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .system
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tema", selection: $theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Görünüm")
                } footer: {
                    Text("Sistem seçiliyken uygulama cihazın açık/koyu ayarını takip eder.")
                }

                Section {
                    Picker("Dil", selection: $language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Dil")
                } footer: {
                    Text("Sistem seçiliyken cihazın dili kullanılır; cihaz dili Türkçe ya da İngilizce değilse Türkçe.")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
