//
//  PreviewData.swift
//  TrendyolBenzeri
//

#if DEBUG
import Foundation

/// Sadece Xcode önizlemelerinde (#Preview) kullanılan örnek veriler.
extension Product {
    static let previewMascara = Product(
        id: 1,
        title: "Essence Mascara Lash Princess",
        description: "Hacim ve uzunluk veren, uzun süre kalıcı maskara.",
        category: "beauty",
        price: 9.99,
        discountPercentage: 10.48,
        rating: 2.56,
        stock: 99,
        brand: "Essence",
        thumbnail: URL(string: "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp")!,
        images: [URL(string: "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/1.webp")!],
        reviews: [
            Review(rating: 5, comment: "Highly impressed!", date: .now, reviewerName: "Eleanor Collins"),
        ]
    )

    static let previewApple = Product(
        id: 16,
        title: "Apple",
        description: "Taze ve sulu elma.",
        category: "groceries",
        price: 1.99,
        discountPercentage: 0,
        rating: 4.19,
        stock: 0,
        brand: nil,
        thumbnail: URL(string: "https://cdn.dummyjson.com/product-images/groceries/apple/thumbnail.webp")!,
        images: [],
        reviews: []
    )
}

extension PlistStorage {
    /// Önizlemeler gerçek favori/sepet dosyalarına yazmasın diye geçici klasör.
    static var preview: PlistStorage {
        PlistStorage(directory: FileManager.default.temporaryDirectory)
    }
}
#endif
