//
//  CartView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct CartView: View {
    var body: some View {
        ContentUnavailableView(
            "Sepet",
            systemImage: "cart",
            description: Text("Sepetindeki ürünler yakında burada görünecek.")
        )
        .navigationTitle("Sepetim")
    }
}

#Preview {
    NavigationStack {
        CartView()
    }
}
