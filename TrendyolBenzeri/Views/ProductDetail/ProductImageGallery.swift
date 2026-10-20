//
//  ProductImageGallery.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Yana kaydırılabilen fotoğraf galerisi. `TabView`'un `.page` stili sayfa sayfa kaydırma
/// ve alttaki noktaları (sayfa göstergesi) hazır olarak verir.
struct ProductImageGallery: View {
    let images: [URL]

    @State private var selectedIndex = 0

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    default:
                        ProgressView()
                    }
                }
                .padding(.bottom, 32) // noktalar görselin üstüne binmesin
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
        // Açık arka planda noktalar görünsün diye arkalarına yarı saydam bir zemin koyar.
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 340)
        .background(Color(.secondarySystemBackground))
    }
}

#Preview {
    ProductImageGallery(images: Product.previewMascara.images + [Product.previewMascara.thumbnail])
}
