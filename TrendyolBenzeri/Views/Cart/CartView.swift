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

    var body: some View {
        content
            .navigationTitle("Sepetim")
            .alert("Siparişin alındı (demo)", isPresented: $showsCheckoutAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Bu bir okul projesi; ödeme adımı henüz yok. Sepetindeki ürünler korunacak.")
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
    let cartStore = CartStore(storage: PlistStorage(directory: .temporaryDirectory.appending(path: UUID().uuidString)))
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
    .environment(CartStore(storage: PlistStorage(directory: .temporaryDirectory.appending(path: UUID().uuidString))))
}
