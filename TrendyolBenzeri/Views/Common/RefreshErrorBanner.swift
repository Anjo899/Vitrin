//
//  RefreshErrorBanner.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Aşağı çekip yenileme başarısız olunca listenin üstünde birkaç saniye görünen uyarı.
/// Liste ekranda kalır; tam ekran hata yalnızca ilk yüklemede gösterilir (ARCHITECTURE.md 4).
private struct RefreshErrorBanner: ViewModifier {
    let message: LocalizedStringResource?
    let dismiss: () -> Void

    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    Label {
                        Text(message)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture(perform: dismiss)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(Text("Uyarıyı kapatır"))
                }
            }
            .animation(.default, value: message != nil)
            // Yeni hata geldiğinde süre baştan sayılır; ekran kapanınca görev iptal olur.
            .task(id: message.map { $0.resolved(in: locale) }) {
                guard let message else { return }
                AccessibilityNotification.Announcement(message.resolved(in: locale)).post()
                do {
                    try await Task.sleep(for: .seconds(4))
                    dismiss()
                } catch {
                    // İptal edildi: uyarı değişti ya da ekran kapandı.
                }
            }
    }
}

extension View {
    /// Yenileme hatasını geçici bir uyarı olarak gösterir; süre dolunca ya da dokununca `dismiss` çağrılır.
    func refreshErrorBanner(_ message: LocalizedStringResource?, dismiss: @escaping () -> Void) -> some View {
        modifier(RefreshErrorBanner(message: message, dismiss: dismiss))
    }
}

#Preview {
    List(1..<20) { Text(verbatim: "Ürün \($0)") }
        .refreshErrorBanner("Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.") {}
}
