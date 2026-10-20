//
//  ProductCategoryDisplayTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
import UIKit
@testable import TrendyolBenzeri

struct ProductCategoryDisplayTests {

    private func category(_ slug: String, name: String = "Name") -> ProductCategory {
        ProductCategory(slug: slug, name: name, url: URL(string: "https://dummyjson.com/products/category/\(slug)")!)
    }

    @Test func usesTranslatedNameForKnownSlug() {
        let shirts = category("mens-shirts", name: "Mens Shirts")
        #expect(shirts.displayName.resolved(in: Locale(identifier: "tr_TR")) == "Erkek Gömlek")
        #expect(shirts.displayName.resolved(in: Locale(identifier: "en_US")) == "Men's Shirts")
    }

    @Test func fallsBackToApiNameForUnknownSlug() {
        let unknown = category("garden-tools", name: "Garden Tools")
        #expect(unknown.displayName.resolved(in: Locale(identifier: "tr_TR")) == "Garden Tools")
        #expect(unknown.displayName.resolved(in: Locale(identifier: "en_US")) == "Garden Tools")
        #expect(unknown.iconName == "tag.fill")
    }

    /// Yanlış yazılmış bir SF Symbol adı ekranda boş görünür; hepsinin var olduğunu kontrol ediyoruz.
    @Test(arguments: ProductCategory.knownSlugs.sorted())
    func iconExists(slug: String) {
        let iconName = category(slug).iconName
        #expect(UIImage(systemName: iconName) != nil, "SF Symbol bulunamadı: \(iconName)")
    }
}
