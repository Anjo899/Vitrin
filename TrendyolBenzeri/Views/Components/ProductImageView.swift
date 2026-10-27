//
//  ProductImageView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Ürün görseli: yükleniyor, başarılı ve hata durumlarında aynı alanı kaplar.
/// Boyutu içerik değil, dışarıdan verilen çerçeve belirler (ör. `.aspectRatio(1, contentMode: .fit)`
/// ya da `.frame(width:height:)`); böylece görsel yüklenmese de kart küçülmez.
struct ProductImageView: View {
    let url: URL?
    var cornerRadius: CGFloat = 8

    /// Değişince `AsyncImage` baştan oluşturulur, yani görsel yeniden istenir.
    @State private var attempt = 0
    /// Son yükleme başarısız oldu; view tekrar ekrana gelince yeniden denenir.
    @State private var needsRetry = false
    /// Ekranda kalırken art arda yapılan iptal denemeleri; sonsuz döngüye girmemek için sınırlı.
    @State private var cancelledRetries = 0

    var body: some View {
        // Color.clear önerilen alanın tamamını kaplar; görsel bunun üstüne yerleşir.
        Color.clear
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            // Ürün görseli dekoratif; ad ve bilgiler yanındaki metinlerden okunur.
                            .accessibilityHidden(true)
                    case .failure(let error):
                        placeholder
                            .onAppear { handleFailure(error) }
                    default:
                        ProgressView()
                    }
                }
                .id(attempt)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Lazy grid'de kart ekrana her döndüğünde çağrılır.
            .onAppear {
                cancelledRetries = 0
                if needsRetry { reload() }
            }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }

    /// Kaydırırken ekrandan çıkan kartın isteği iptal edilir (`NSURLErrorCancelled`, -999).
    /// Bu kalıcı bir hata değil: kart görünüyorsa hemen, değilse ekrana döndüğünde yeniden denenir.
    private func handleFailure(_ error: Error) {
        if error.isCancellation, cancelledRetries < 2 {
            cancelledRetries += 1
            reload()
        } else {
            needsRetry = true
        }
    }

    private func reload() {
        needsRetry = false
        attempt += 1
    }
}

private extension Error {
    var isCancellation: Bool {
        (self as? URLError)?.code == .cancelled || self is CancellationError
    }
}

#Preview {
    HStack {
        ProductImageView(url: Product.previewMascara.thumbnail)
            .aspectRatio(1, contentMode: .fit)
        // Geçersiz adres: hata durumundaki yer tutucu.
        ProductImageView(url: URL(string: "https://invalid.example/x.png"))
            .aspectRatio(1, contentMode: .fit)
    }
    .padding()
}
