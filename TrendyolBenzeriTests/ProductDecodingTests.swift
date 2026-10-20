//
//  ProductDecodingTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

struct ProductDecodingTests {

    /// dummyjson cevabından kısaltılmış örnek: ikinci üründe `brand` alanı yok.
    private let productsJSON = """
    {
      "products": [
        {
          "id": 1,
          "title": "Essence Mascara Lash Princess",
          "description": "Popular mascara.",
          "category": "beauty",
          "price": 10,
          "discountPercentage": 10.48,
          "rating": 2.56,
          "stock": 99,
          "brand": "Essence",
          "sku": "BEA-ESS-ESS-001",
          "reviews": [
            {
              "rating": 3,
              "comment": "Would not recommend!",
              "date": "2025-04-30T09:41:02.053Z",
              "reviewerName": "Eleanor Collins",
              "reviewerEmail": "eleanor.collins@x.dummyjson.com"
            }
          ],
          "images": ["https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/1.webp"],
          "thumbnail": "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp"
        },
        {
          "id": 16,
          "title": "Apple",
          "description": "Fresh apple.",
          "category": "groceries",
          "price": 1.99,
          "discountPercentage": 0,
          "rating": 4.19,
          "stock": 0,
          "reviews": [],
          "images": [],
          "thumbnail": "https://cdn.dummyjson.com/product-images/groceries/apple/thumbnail.webp"
        }
      ],
      "total": 194,
      "skip": 0,
      "limit": 2
    }
    """

    @Test func decodesProductsResponse() throws {
        let response = try JSONDecoder.dummyJSON.decode(ProductsResponse.self, from: Data(productsJSON.utf8))

        #expect(response.total == 194)
        #expect(response.products.count == 2)

        let mascara = try #require(response.products.first)
        #expect(mascara.id == 1)
        #expect(mascara.brand == "Essence")
        #expect(mascara.reviews.first?.reviewerName == "Eleanor Collins")
        #expect(mascara.reviews.first?.date == Date(timeIntervalSince1970: 1_746_006_062.053))
    }

    @Test func brandIsOptional() throws {
        let response = try JSONDecoder.dummyJSON.decode(ProductsResponse.self, from: Data(productsJSON.utf8))
        #expect(response.products[1].brand == nil)
    }

    @Test func calculatesDiscountAndStock() throws {
        let response = try JSONDecoder.dummyJSON.decode(ProductsResponse.self, from: Data(productsJSON.utf8))
        let mascara = response.products[0]
        let apple = response.products[1]

        #expect(mascara.hasDiscount)
        // 10 × (1 − 0.1048) = 8.952 → kuruşa yuvarlanınca 8.95
        #expect(abs(mascara.discountedPrice - 8.95) < 0.0001)
        // Rozet tam yüzde gösterir: 10.48 → %10.
        #expect(mascara.discountRate == 0.10)
        #expect(mascara.isInStock)

        #expect(!apple.hasDiscount)
        #expect(apple.discountedPrice == apple.price)
        #expect(!apple.isInStock)
    }

    @Test func decodesCategories() throws {
        let json = """
        [
          {"slug": "beauty", "name": "Beauty", "url": "https://dummyjson.com/products/category/beauty"},
          {"slug": "mens-shirts", "name": "Mens Shirts", "url": "https://dummyjson.com/products/category/mens-shirts"}
        ]
        """
        let categories = try JSONDecoder.dummyJSON.decode([ProductCategory].self, from: Data(json.utf8))

        #expect(categories.map(\.id) == ["beauty", "mens-shirts"])
        #expect(categories[1].name == "Mens Shirts")
    }

    /// Fiyat ve indirim biçimi seçilen dile göre değişir. iOS sembolle tutar arasına bölünmez boşluk koyar.
    @Test func formatsPriceInLiraForSelectedLanguage() {
        #expect(1299.9.formatted(.lira.locale(Locale(identifier: "tr_TR"))) == "₺1.299,90")
        #expect(1299.9.formatted(.lira.locale(Locale(identifier: "en_US"))) == "TRY\u{00A0}1,299.90")
    }

    @Test func formatsDiscountForSelectedLanguage() {
        #expect(0.10.formatted(.discount.locale(Locale(identifier: "tr_TR"))) == "%10")
        #expect(0.10.formatted(.discount.locale(Locale(identifier: "en_US"))) == "10%")
    }
}
