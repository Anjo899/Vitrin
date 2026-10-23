//
//  CartView.swift
//  TrendyolBenzeri
//

import SwiftUI

struct CartView: View {
    /// Seçili sekme `MainTabView`'a ait; boş sepetteki buton Ana Sayfa'ya geçirir.
    @Binding var selectedTab: MainTabView.Tab

    @Environment(CartStore.self) private var cartStore
    /// Kökte seçilen dile göre verilir; dil değişince fiyatlar anında yeni para birimine geçer.
    @Environment(\.currency) private var currency
    @State private var showsCheckoutAlert = false
    @State private var viewModel = CartViewModel()

    var body: some View {
        content
            .navigationTitle("Sepetim")
            .alert("Siparişin alındı (demo)", isPresented: $showsCheckoutAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Bu bir okul projesi; ödeme adımı henüz yok. Sepetindeki ürünler korunacak.")
            }
            // Dosyada yalnızca id var; ekran her açıldığında ürünler API'den alınır ve tazelenir.
            // Ürünler biliniyorsa istek arka planda olur, başarısız olursa liste olduğu gibi kalır.
            .task {
                await refreshProducts()
            }
    }

    private func refreshProducts() async {
        let ids = cartStore.productIDs
        guard !ids.isEmpty else { return }
        await viewModel.loadProducts(ids: ids)
        if case .loaded(let products) = viewModel.state {
            cartStore.update(with: products, requestedIDs: ids)
        }
    }

    @ViewBuilder
    private var content: some View {
        if cartStore.isEmpty {
            ContentUnavailableView {
                Label("Sepetin boş", systemImage: "cart")
            } description: {
                Text("Beğendiğin ürünleri sepete ekleyerek alışverişe başlayabilirsin.")
            } actions: {
                Button("Alışverişe Başla") {
                    selectedTab = .home
                }
                .buttonStyle(.borderedProminent)
            }
        } else if !cartStore.missingProductIDs.isEmpty {
            if case .failed(let message) = viewModel.state {
                ErrorView(message: message) {
                    await refreshProducts()
                }
            } else {
                LoadingView(message: "Sepet yükleniyor…")
            }
        } else {
            List {
                ForEach(cartStore.sortedItems) { item in
                    CartItemRow(item: item)
                        .swipeActions(edge: .trailing) {
                            Button("Sil", systemImage: "trash", role: .destructive) {
                                cartStore.remove(item)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .animation(.default, value: cartStore.sortedItems.map(\.id))
            // Özet çubuğu listenin altına yerleşir; son satır çubuğun arkasında kalmaz.
            .safeAreaInset(edge: .bottom) {
                summaryBar
            }
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Toplam (\(cartStore.totalQuantity) ürün)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(cartStore.totalPrice(in: currency), format: currency.format)
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                    .animation(.default, value: cartStore.totalPrice(in: currency))
                    // UI testi toplamı bu kimlikle bulur; VoiceOver'ı etkilemez.
                    .accessibilityIdentifier("cartTotal")
            }

            Button {
                showsCheckoutAlert = true
            } label: {
                Text("Alışverişi Tamamla")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview("Dolu") {
    let cartStore = CartStore(storage: .preview)
    cartStore.add(.previewMascara)
    cartStore.add(.previewMascara)

    return NavigationStack {
        CartView(selectedTab: .constant(.cart))
    }
    .environment(cartStore)
}

#Preview("Boş") {
    NavigationStack {
        CartView(selectedTab: .constant(.cart))
    }
    .environment(CartStore(storage: .preview))
}
