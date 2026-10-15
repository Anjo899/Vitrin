//
//  HomeView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ContentUnavailableView(
            "Ana Sayfa",
            systemImage: "house",
            description: Text("Ürünler yakında burada listelenecek.")
        )
        .navigationTitle("Vitrin")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
