//
//  FavoritesView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        ContentUnavailableView(
            "Favoriler",
            systemImage: "heart",
            description: Text("Favori ürünlerin yakında burada görünecek.")
        )
        .navigationTitle("Favoriler")
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
}
