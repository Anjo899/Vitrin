//
//  PreviewData.swift
//  TrendyolBenzeri
//

import Foundation

/// Xcode önizlemelerinde (#Preview) kullanılan örnek veriler.
/// `#Preview` blokları Release dahil her yapılandırmada derlendiği için bu dosya `#if DEBUG` içinde değil.
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
            Review(rating: 5, comment: "Highly impressed!", date: .now, reviewerName: "Eleanor Collins")
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
    /// Önizlemeler gerçek favori/sepet dosyalarına yazmasın diye her çağrıda yeni, boş bir geçici klasör.
    /// Böylece önizlemeler birbirinin kaydını görmez; dosyada kalan bir id yüzünden ürün API'den istenmez.
    static var preview: PlistStorage {
        let directory = FileManager.default.temporaryDirectory.appending(path: "Preview-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return PlistStorage(directory: directory)
    }
}
