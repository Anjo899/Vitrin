//
//  StarRatingView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// 5 yıldızlık puan göstergesi; ör. 3.6 → ★★★½☆
struct StarRatingView: View {
    let rating: Double
    /// Yıldızların boyutu metin stiliyle verilir; yazı boyutu büyüyünce yıldızlar da büyür (Dynamic Type).
    var textStyle: Font.TextStyle = .caption

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: symbolName(for: index))
                    .font(.system(textStyle))
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("5 üzerinden \(rating, format: .number.precision(.fractionLength(1))) puan"))
    }

    private func symbolName(for index: Int) -> String {
        let value = rating - Double(index - 1)
        if value >= 0.75 {
            return "star.fill"
        } else if value >= 0.25 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        StarRatingView(rating: 4.8)
        StarRatingView(rating: 3.5)
        StarRatingView(rating: 1.2, textStyle: .title3)
    }
}
