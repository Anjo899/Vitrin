//
//  CategoriesView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct CategoriesView: View {
    @State private var viewModel = CategoriesViewModel()
    @Environment(\.locale) private var locale

    var body: some View {
        content
            .navigationTitle("Kategoriler")
            .navigationDestination(for: ProductCategory.self) { category in
                CategoryProductsView(category: category)
            }
            // Kategori ürünlerinden detaya geçiş de bu sekmenin NavigationStack'inde olur.
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
            LoadingView(message: "Kategoriler yükleniyor…")
        case .failed(let message):
            ErrorView(message: message) {
                await viewModel.load()
            }
        case .loaded(let categories) where categories.isEmpty:
            ContentUnavailableView("Kategori bulunamadı", systemImage: "square.grid.2x2")
        case .loaded(let categories):
            List(sortedByName(categories)) { category in
                NavigationLink(value: category) {
                    Label {
                        Text(category.displayName)
                    } icon: {
                        Image(systemName: category.iconName)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            // Yenileme hatası listeyi silmez; birkaç saniyelik uyarı olarak görünür.
            .refreshErrorBanner(viewModel.refreshError) {
                viewModel.dismissRefreshError()
            }
        }
    }

    /// Ekrandaki adlara göre, seçilen dilin alfabe sırasıyla (Türkçe'de Ç, Ö, Ü doğru yerde).
    private func sortedByName(_ categories: [ProductCategory]) -> [ProductCategory] {
        categories.sorted {
            $0.displayName.resolved(in: locale).compare($1.displayName.resolved(in: locale), locale: locale) == .orderedAscending
        }
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
    .environment(FavoritesStore(storage: .preview))
    .environment(CartStore(storage: .preview))
}
