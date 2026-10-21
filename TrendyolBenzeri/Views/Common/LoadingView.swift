//
//  LoadingView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Veri yüklenirken ekranın ortasında gösterilen gösterge.
struct LoadingView: View {
    var message: LocalizedStringKey = "Yükleniyor…"

    var body: some View {
        ProgressView(message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
