//
//  AddToCartUITests.swift
//  TrendyolBenzeriUITests
//

import XCTest

/// Kritik akış: ürünü sepete ekle → Sepet badge'i artar → sepetteki toplam detaydaki fiyata eşit.
/// Ürünler gerçek dummyjson'dan gelir; `-uiTesting` ile sepet ve favoriler geçici klasörde boş başlar.
final class AddToCartUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAddingProductUpdatesBadgeAndTotal() {
        runAddToCartFlow(extraArguments: [])
    }

    /// En büyük erişilebilirlik yazı boyutunda da akış çalışır: alt çubuklar alt alta dizilir,
    /// buton ekranda kalır ve basılabilir (ARCHITECTURE.md 8 Dynamic Type, REVIEW.md O10).
    @MainActor
    func testAddingProductWorksAtLargestTextSize() {
        runAddToCartFlow(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
    }

    @MainActor
    private func runAddToCartFlow(extraArguments: [String]) {
        let app = XCUIApplication()
        // Türkçe arayüz ve TL; sepet gerçek dosya yerine geçici klasörde.
        app.launchArguments = ["-uiTesting", "-appLanguage", "tr", "-appTheme", "light"] + extraArguments
        app.launch()

        let cartTab = app.tabBars.buttons["Sepet"]
        XCTAssertTrue(cartTab.waitForExistence(timeout: 5))
        XCTAssertEqual(cartTab.value as? String ?? "", "", "Sepet boş başlamalı")

        // Ana sayfadaki ilk ürün kartı (ürünler ağdan gelir).
        let firstCard = app.buttons.matching(identifier: "productCard").firstMatch
        XCTAssertTrue(firstCard.waitForExistence(timeout: 30), "Ürünler yüklenemedi")
        firstCard.tap()

        let addButton = app.buttons["addToCartButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertTrue(addButton.isHittable, "Sepete Ekle butonu ekranda ve basılabilir olmalı")
        let price = app.staticTexts["addToCartPrice"].label
        addButton.tap()

        XCTAssertTrue(app.staticTexts["Sepette 1 adet"].waitForExistence(timeout: 5))
        XCTAssertEqual(cartTab.value as? String, "1")

        cartTab.tap()
        let total = app.staticTexts["cartTotal"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertEqual(total.label, price, "Tek ürünün toplamı detaydaki fiyata eşit olmalı")
        XCTAssertTrue(app.staticTexts["Toplam (1 ürün)"].exists)
    }
}
