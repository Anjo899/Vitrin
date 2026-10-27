//
//  ColorContrastTests.swift
//  TrendyolBenzeriTests
//

import Testing
import UIKit
@testable import TrendyolBenzeri

/// Üzerine beyaz yazı gelen Assets renklerinin kontrastı (ARCHITECTURE.md 8. Erişilebilirlik).
/// Açık ve koyu temada ayrı ayrı ölçülür; metin için en az 4,5:1.
struct ColorContrastTests {

    /// "Sepete Eklendi" butonu ve indirim rozeti beyaz yazı taşır (REVIEW.md O12).
    @Test(arguments: [
        ("SuccessFill", UIColor(resource: .successFill)),
        ("DiscountBadge", UIColor(resource: .discountBadge))
    ])
    func whiteTextHasEnoughContrast(name: String, fill: UIColor) {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let resolved = fill.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            let ratio = contrastRatio(resolved, .white)
            #expect(ratio >= 4.5, "\(name), \(style == .light ? "açık" : "koyu") tema: \(ratio):1")
        }
    }

    /// Ölçümün kendisi: sistem yeşili beyaz yazıyla eşiğin altında kalıyordu.
    @Test func systemGreenFailsWithWhiteText() {
        let systemGreen = UIColor(red: 0x34 / 255, green: 0xC7 / 255, blue: 0x59 / 255, alpha: 1)
        #expect(contrastRatio(systemGreen, .white) < 3)
    }

    // MARK: - WCAG 2 kontrast oranı

    private func contrastRatio(_ first: UIColor, _ second: UIColor) -> Double {
        let lighter = max(luminance(first), luminance(second))
        let darker = min(luminance(first), luminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func luminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.039_28 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
