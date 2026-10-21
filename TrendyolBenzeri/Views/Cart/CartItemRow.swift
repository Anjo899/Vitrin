//
//  CartItemRow.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Sepetteki bir satır: görsel, ürün bilgisi, fiyat ve adet kontrolleri.
struct CartItemRow: View {
    let item: CartItem

    @Environment(CartStore.self) private var cartStore
    /// Kökte seçilen dile göre verilir; dil değişince fiyatlar anında yeni para birimine geçer.
    @Environment(\.currency) private var currency

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                if let brand = item.product.brand {
                    Text(brand)
                        .font(.caption.weight(.semibold))
                }
                Text(item.product.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(item.product.discountedPrice(in: currency), format: currency.format)
                    if item.product.hasDiscount {
                        Text(item.product.price(in: currency), format: currency.format)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)

                HStack {
                    quantityControls
                    Spacer()
                    Text(item.lineTotal(in: currency), format: currency.format)
                        .font(.subheadline.bold())
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        ProductImageView(url: item.product.thumbnail)
            .frame(width: 72, height: 72)
    }

    private var quantityControls: some View {
        HStack(spacing: 0) {
            Button {
                cartStore.decrement(item)
            } label: {
                // Adet 1'deyken azaltmak ürünü sepetten çıkarır; ikon bunu belli eder.
                Image(systemName: item.quantity == 1 ? "trash" : "minus")
                    .frame(width: 44, height: 44) // HIG: en az 44 pt dokunma alanı
            }
            .accessibilityLabel(item.quantity == 1 ? Text("Sepetten çıkar") : Text("Adedi azalt"))

            Text(item.quantity, format: .number)
                .font(.subheadline.monospacedDigit().bold())
                .frame(minWidth: 28)
                .contentTransition(.numericText())

            Button {
                cartStore.increment(item)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 44, height: 44)
            }
            .disabled(!cartStore.canAdd(item.product))
            .accessibilityLabel(Text("Adedi artır"))
        }
        .font(.subheadline.weight(.semibold))
        // List satırında butonların ayrı ayrı basılabilmesi için gerekli;
        // aksi halde satıra basmak her iki butonu da tetikler.
        .buttonStyle(.borderless)
        .overlay {
            Capsule()
                .stroke(Color(.separator))
        }
        .animation(.default, value: item.quantity)
    }
}

#Preview {
    let cartStore = CartStore(storage: .preview)
    cartStore.add(.previewMascara)

    return List {
        if let item = cartStore.sortedItems.first {
            CartItemRow(item: item)
        }
    }
    .environment(cartStore)
}
