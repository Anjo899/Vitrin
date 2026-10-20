//
//  TestHelpers.swift
//  TrendyolBenzeriTests
//

import Foundation
@testable import TrendyolBenzeri

extension Product {
    static func sample(
        id: Int = 1,
        title: String = "Sample Product",
        price: Double = 100,
        discountPercentage: Double = 0,
        stock: Int = 10
    ) -> Product {
        Product(
            id: id,
            title: title,
            description: "Description",
            category: "beauty",
            price: price,
            discountPercentage: discountPercentage,
            rating: 4.5,
            stock: stock,
            brand: "Brand",
            thumbnail: URL(string: "https://example.com/thumb.webp")!,
            images: [],
            reviews: [Review(rating: 5, comment: "Great", date: Date(timeIntervalSince1970: 0), reviewerName: "Ali")]
        )
    }
}

extension PlistStorage {
    /// Her test için boş, benzersiz bir geçici klasör.
    static func temporary() throws -> PlistStorage {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return PlistStorage(directory: directory)
    }
}
