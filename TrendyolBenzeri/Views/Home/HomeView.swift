//
//  HomeView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var searchText = ""

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if isSearching {
                searchContent
            } else {
                content
            }
        }
        .navigationTitle("Vitrin")
        .searchable(text: $searchText, prompt: "Ürün, marka ara")
        // searchText her değiştiğinde önceki görev iptal edilip yenisi başlar.
        .task(id: searchText) {
            await viewModel.search(searchText)
        }
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

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.searchState {
        case .idle, .loading:
            LoadingView(message: "Aranıyor…")
        case .failed(let message):
            ErrorView(message: message) {
                await viewModel.search(searchText)
            }
        case .loaded(let products) where products.isEmpty:
            ContentUnavailableView(
                "Sonuç bulunamadı",
                systemImage: "magnifyingglass",
                description: Text("“\(searchText)” için ürün bulunamadı. Farklı bir kelime dene.")
            )
        case .loaded(let products):
            ScrollView {
                productGrid(products)
            }
            .scrollDismissesKeyboard(.immediately)
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
