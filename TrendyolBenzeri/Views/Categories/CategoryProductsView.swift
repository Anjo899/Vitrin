//
//  CategoryProductsView.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Bir kategoriye ait ürünler; ana sayfadaki aynı `ProductGridView`'i kullanır.
struct CategoryProductsView: View {
    @State private var viewModel: CategoryProductsViewModel

    /// ViewModel kategoriye bağlı olduğu için `@State`'in ilk değerini init'te veriyoruz.
    init(category: ProductCategory) {
        _viewModel = State(initialValue: CategoryProductsViewModel(category: category))
    }

    var body: some View {
        content
            .navigationTitle(viewModel.category.displayName)
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
            ContentUnavailableView("Bu kategoride ürün yok", systemImage: "shippingbox")
        case .loaded(let products):
            ScrollView {
                Text("\(products.count) ürün")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                ProductGridView(products: products)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryProductsView(category: ProductCategory(
            slug: "beauty",
            name: "Beauty",
            url: URL(string: "https://dummyjson.com/products/category/beauty")!
        ))
    }
    .environment(FavoritesStore(storage: .preview))
}
