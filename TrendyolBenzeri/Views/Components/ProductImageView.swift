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
                    case .failure:
                        placeholder
                    default:
                        ProgressView()
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
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
