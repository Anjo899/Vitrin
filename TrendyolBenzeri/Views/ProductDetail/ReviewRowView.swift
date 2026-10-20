//
//  ReviewRowView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Tek bir değerlendirme: kullanıcı adı, yıldızlar, tarih ve yorum.
struct ReviewRowView: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(review.reviewerName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(review.date, format: .dateTime.day().month(.wide).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            StarRatingView(rating: Double(review.rating), size: 11)
            Text(review.comment)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ReviewRowView(review: Product.previewMascara.reviews[0])
        .padding()
}
