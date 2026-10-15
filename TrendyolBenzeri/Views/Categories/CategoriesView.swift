//
//  CategoriesView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct CategoriesView: View {
    var body: some View {
        ContentUnavailableView(
            "Kategoriler",
            systemImage: "square.grid.2x2",
            description: Text("Kategoriler yakında burada listelenecek.")
        )
        .navigationTitle("Kategoriler")
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
}
