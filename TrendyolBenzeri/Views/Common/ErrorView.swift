//
//  ErrorView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// İstek başarısız olduğunda hata mesajını ve "Tekrar Dene" butonunu gösterir.
/// Boş durumlar için ayrıca iOS 17'nin hazır `ContentUnavailableView`'u kullanılır.
struct ErrorView: View {
    let message: LocalizedStringResource
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Bir şeyler ters gitti", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Tekrar Dene") {
                Task { await retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorView(message: "Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.") {}
}
