//
//  HomeView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        content
            .navigationTitle("Vitrin")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            .task {
                await viewModel.loadIfNeeded()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: "Ürünler yükleniyor…")
        case .failed(let message):
            ErrorView(message: message) {
                await viewModel.load()
            }
        case .loaded(let products) where products.isEmpty:
            ContentUnavailableView("Ürün bulunamadı", systemImage: "shippingbox")
        case .loaded(let products):
            ScrollView {
                productGrid(products)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func productGrid(_ products: [Product]) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(products) { product in
                NavigationLink(value: product) {
                    ProductCardView(product: product)
                }
                .buttonStyle(.plain)
                // Kalp, NavigationLink'in dışında; basınca detay açılmaz.
                .overlay(alignment: .topTrailing) {
                    FavoriteButton(product: product)
                        .padding(12)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(FavoritesStore(storage: .preview))
}
