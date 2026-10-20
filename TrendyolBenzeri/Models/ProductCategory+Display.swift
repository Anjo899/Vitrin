//
//  ProductCategory+Display.swift
//  TrendyolBenzeri
//

import Foundation

/// API kategori adlarını İngilizce döndürür ("Mens Shirts"); arayüzde Türkçe ad ve ikon gösteriyoruz.
nonisolated extension ProductCategory {
    private static let displayInfo: [String: (name: String, icon: String)] = [
        "beauty": ("Güzellik", "paintbrush.pointed.fill"),
        "fragrances": ("Parfüm", "sparkles"),
        "furniture": ("Mobilya", "sofa.fill"),
        "groceries": ("Market", "basket.fill"),
        "home-decoration": ("Ev Dekorasyonu", "lamp.table.fill"),
        "kitchen-accessories": ("Mutfak Gereçleri", "fork.knife"),
        "laptops": ("Dizüstü Bilgisayar", "laptopcomputer"),
        "mens-shirts": ("Erkek Gömlek", "tshirt.fill"),
        "mens-shoes": ("Erkek Ayakkabı", "shoeprints.fill"),
        "mens-watches": ("Erkek Saat", "watch.analog"),
        "mobile-accessories": ("Telefon Aksesuarları", "headphones"),
        "motorcycle": ("Motosiklet", "bicycle"),
        "skin-care": ("Cilt Bakımı", "drop.fill"),
        "smartphones": ("Akıllı Telefon", "iphone"),
        "sports-accessories": ("Spor Aksesuarları", "sportscourt.fill"),
        "sunglasses": ("Güneş Gözlüğü", "sunglasses.fill"),
        "tablets": ("Tablet", "ipad"),
        "tops": ("Üst Giyim", "tshirt"),
        "vehicle": ("Araç", "car.fill"),
        "womens-bags": ("Kadın Çanta", "handbag.fill"),
        "womens-dresses": ("Kadın Elbise", "hanger"),
        "womens-jewellery": ("Kadın Takı", "diamond.fill"),
        "womens-shoes": ("Kadın Ayakkabı", "shoeprints.fill"),
        "womens-watches": ("Kadın Saat", "watch.analog"),
    ]

    static let knownSlugs = Set(displayInfo.keys)

    /// Türkçe ad; eşlemede yoksa API'deki ad.
    var displayName: String {
        Self.displayInfo[slug]?.name ?? name
    }

    /// SF Symbol adı; eşlemede yoksa genel bir etiket ikonu.
    var iconName: String {
        Self.displayInfo[slug]?.icon ?? "tag.fill"
    }
}
