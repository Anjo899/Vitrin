//
//  TrendyolBenzeriApp.swift
//  TrendyolBenzeri
//
//  Created by skilic on 15.10.2026.
//

import SwiftUI

@main
struct TrendyolBenzeriApp: App {
    /// Ekranlar arası paylaşılan store'lar burada bir kez oluşturulur.
    @State private var favoritesStore = FavoritesStore()
    @State private var cartStore = CartStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(favoritesStore)
                .environment(cartStore)
        }
    }
}
