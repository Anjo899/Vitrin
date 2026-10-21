//
//  LoadState.swift
//  TrendyolBenzeri
//

import Foundation

/// Ağdan veri çeken her ekranın içinde bulunabileceği durumlar.
/// Ekran `switch` ile hangi görünümü çizeceğine bu değere bakarak karar verir.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    /// Mesaj `String` değil, dil değişince yeniden çözülebilen bir kaynak.
    case failed(LocalizedStringResource)
}
