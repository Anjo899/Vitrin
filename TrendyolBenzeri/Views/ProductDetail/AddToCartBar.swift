//
//  AddToCartBar.swift
//  TrendyolBenzeri
//

import SwiftUI

/// Detay ekranının altında sabit duran fiyat + "Sepete Ekle" çubuğu.
struct AddToCartBar: View {
    let product: Product

    @Environment(CartStore.self) private var cartStore
    /// Her eklemede artar; geri bildirim (titreşim + yeşil buton) bunu tetikler.
    @State private var addCount = 0
    @State private var showsAddedFeedback = false

    var body: some View {
        let quantityInCart = cartStore.quantity(of: product)

        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.discountedPrice.formattedPrice)
                    .font(.headline)
                if quantityInCart > 0 {
                    Text("Sepette \(quantityInCart) adet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                cartStore.add(product)
                addCount += 1
                showsAddedFeedback = true
            } label: {
                Label {
                    Text(buttonTitle)
                } icon: {
                    Image(systemName: buttonIcon)
                }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(showsAddedFeedback ? .green : .accentColor)
            .disabled(!cartStore.canAdd(product))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
        .sensoryFeedback(.success, trigger: addCount)
        // Son eklemeden 1,5 sn sonra buton normale döner. Bu sürede tekrar eklenirse
        // görev iptal edilip yeniden başlar, böylece süre baştan sayılır.
        .task(id: addCount) {
            guard addCount > 0 else { return }
            do {
                try await Task.sleep(for: .seconds(1.5))
                showsAddedFeedback = false
            } catch {
                // İptal edildi: yeni bir ekleme oldu.
            }
        }
    }

    private var buttonTitle: LocalizedStringResource {
        if !product.isInStock {
            "Tükendi"
        } else if showsAddedFeedback {
            "Sepete Eklendi"
        } else if !cartStore.canAdd(product) {
            "Stok sınırına ulaşıldı"
        } else {
            "Sepete Ekle"
        }
    }

    private var buttonIcon: String {
        showsAddedFeedback ? "checkmark" : "cart.badge.plus"
    }
}

#Preview {
    VStack {
        Spacer()
        AddToCartBar(product: .previewMascara)
        AddToCartBar(product: .previewApple)
    }
    .environment(CartStore(storage: .preview))
}
