# Vitrin – Proje Planı

Trendyol benzeri bir e-ticaret uygulaması (okul projesi, SwiftUI öğrenme amaçlı). Uygulamanın adı **Vitrin**.

## Genel kurallar
- SwiftUI, iOS 17+, `@State` / `@Binding` / `@Observable` / `.environment`
- Paylaşılan veriler (favoriler, sepet) ayrı `@Observable` store'larda; `TrendyolBenzeriApp` içinde oluşturulup `.environment(...)` ile dağıtılır
- Ağ: `async/await` + `URLSession`, kaynak `https://dummyjson.com`
- Favoriler/sepet: ürün id'sine bağlı dictionary, plist ile kalıcı (`PropertyListEncoder`, Documents klasörü)
- Kod İngilizce, arayüz metinleri Türkçe; Trendyol adı/logosu kullanılmaz
- Conventional Commits (İngilizce), her commit tek anlamlı adım
- Stacked branch: her branch bir öncekinden açılır, PR base'i de bir önceki branch'tir. main'e merge yok (hoca merge edecek). Push öncesi her zaman sorulur.
- Her özellik sonunda: test adımları verilir, onay gelmeden sonrakine geçilmez.

## Adımlar

| # | Branch | Base | Durum |
|---|--------|------|-------|
| 0 | `chore/project-setup` | `main` | ✅ Tamamlandı |
| 1 | `feature/core-networking` | `chore/project-setup` | ✅ Tamamlandı |
| 2 | `feature/stores-persistence` | `feature/core-networking` | ✅ Tamamlandı |
| 3 | `feature/app-shell` | `feature/stores-persistence` | ✅ Tamamlandı |
| 4 | `feature/home-grid` | `feature/app-shell` | ✅ Tamamlandı |
| 5 | `feature/home-search` | `feature/home-grid` | ✅ Tamamlandı |
| 6 | `feature/product-detail` | `feature/home-search` | ✅ Tamamlandı |
| 7 | `feature/categories` | `feature/product-detail` | ✅ Tamamlandı |
| 8 | `feature/favorites-screen` | `feature/categories` | ✅ Tamamlandı |
| 9 | `feature/cart-screen` | `feature/favorites-screen` | ⬜ |

### 0. chore/project-setup ✅
`.gitignore`, deployment target iOS 17.0, görünen ad Vitrin, `AccentColor` + `BrandAccent` renkleri, `PLAN.md`.

### 1. feature/core-networking ✅: veri katmanı (henüz UI yok)
- `Models/Product.swift`: `Product` (id, title, description, category, price, discountPercentage, rating, stock, brand?, thumbnail, images, reviews), `Review`, `ProductsResponse` (products, total, skip, limit). Hepsi `Codable, Identifiable, Hashable`. `brand` opsiyonel (bazı ürünlerde yok). Hesaplanan `discountedPrice`.
- `Models/ProductCategory.swift`: `/products/categories` `{slug, name, url}` nesneleri döndürüyor.
- `Networking/APIClient.swift`: generic `get<T: Decodable>(_ path:, query:) async throws -> T`, `APIError` (invalidURL, badStatus, decoding), Türkçe `errorDescription`.
- `Networking/ProductService.swift`: `fetchProducts()`, `searchProducts(query:)`, `fetchCategories()`, `fetchProducts(category:)` (`/products/category/{slug}`), `fetchProduct(id:)`.
- `Utilities/PriceFormatter.swift`: fiyat biçimlendirme (dummyjson fiyatları dolar: `$1,234.50`, en_US).
- Testler: örnek JSON ile decode testleri.

### 2. feature/stores-persistence ✅: paylaşılan state
- Paylaşılan `TrendyolBenzeri` scheme'i: test aksiyonu sadece unit testleri çalıştırır (şablon UI testleri çıkarıldı, dosyaları duruyor).
- `Persistence/PlistStorage.swift`: generic `save` / `load`, Documents altında `favorites.plist`, `cart.plist`.
- `Stores/FavoritesStore.swift` (`@Observable`): `items: [Int: Product]`, `isFavorite(_:)`, `toggle(_:)`, sıralı `products`; her değişiklikte kaydet, açılışta yükle.
- `Stores/CartStore.swift` (`@Observable`): `items: [Int: CartItem]` (product + quantity), `add` (stoktan fazla eklenmez), `increment`, `decrement` (1'in altına inince sil), `remove`, `totalQuantity`, `totalPrice` (indirimli fiyatlarla).
- `TrendyolBenzeriApp`: store'lar `@State` ile oluşturulup `.environment(...)` ile verilir.
- Testler: store mantığı + plist kaydet/yükle.

### 3. feature/app-shell ✅: sekmeler + ortak durum ekranları
- `MainTabView`: Ana Sayfa, Kategoriler, Favoriler, Sepet; Sepet sekmesinde ürün sayısı badge'i (0 iken gizli).
- Her sekme için `NavigationStack` + geçici ekran. `ContentView.swift` kaldırılır.
- Ortak görünümler: `LoadingView`, `ErrorView` (mesaj + "Tekrar Dene"). Boş durumlar için ayrı bir view yerine iOS 17'nin hazır `ContentUnavailableView`'u kullanılır.
- `PreviewData.swift`: sadece DEBUG'da derlenen önizleme örnek ürünleri.
- `LoadState<T>`: `idle`, `loading`, `loaded(T)`, `failed(String)`.

### 4. feature/home-grid ✅: ana sayfa
- `HomeViewModel` (`@Observable`): `LoadState<[Product]>`, `load()`, `refresh()`.
- `HomeView`: 2 sütunlu `LazyVGrid`, `.task` ile yükleme, `.refreshable` ile aşağı çekip yenileme.
- `ProductCardView`: görsel, ad, marka, puan, indirim varsa üstü çizili eski fiyat + `%x` rozeti + indirimli fiyat, kalp ikonu.
- Detaya geçiş için `NavigationLink(value:)` + `.navigationDestination`.

### 5. feature/home-search ✅
`.searchable` ("Ürün, marka ara"), gecikmeli (debounce) `/products/search?q=` isteği, sonuç yoksa boş durum ekranı.

### 6. feature/product-detail ✅
- Kaydırmalı fotoğraf galerisi (`TabView` + `.page`), başlık, marka, fiyat/indirim, puan, stok ("Stokta 12 adet" / "Tükendi"), açıklama, yorumlar.
- Kalp butonu, altta sabit "Sepete Ekle" butonu (stok 0 ise devre dışı), eklenince kısa geri bildirim.

### 7. feature/categories ✅
Kategori listesi → seçilen kategorinin ürünleri. Ana sayfadaki grid ortak `ProductGridView`'e çıkarılır (`refactor:` commit). API kategori adları İngilizce olduğu için slug → Türkçe ad + SF Symbol ikonu eşlemesi (`ProductCategory+Display.swift`), bilinmeyen kategoride API adı kullanılır.

### 8. feature/favorites-screen ✅
Favori ürünlerin grid'i; boşken "Henüz favori ürünün yok" ekranı ve seçili sekmeyi `@Binding` ile Ana Sayfa'ya çeviren "Ürünleri Keşfet" butonu.

### 9. feature/cart-screen
Sepet satırları (görsel, ad, fiyat, `−` / adet / `+`), kaydırarak veya çöp butonuyla silme, toplam tutar, "Alışverişi Tamamla" (MVP'de sadece uyarı), boş sepet ekranı ("Sepetin boş").

## Her branch için iş akışı
1. Bir önceki branch'ten yeni branch aç
2. Küçük, anlamlı commit'ler; her adımın Türkçe kısa açıklaması
3. Derle ve testleri çalıştır:
   `DEVELOPER_DIR=/Users/skilic/Downloads/Xcode.app/Contents/Developer xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri -destination 'platform=iOS Simulator,name=iPhone 17' build test`
4. Simülatörde test adımlarını ver, bu dosyada durumu ✅ yap, onay bekle
5. Push/PR öncesi sor (PR base'i = önceki branch)

## Genel doğrulama
- Unit testler: model decoding, store mantığı, plist kaydet/yükle
- Simülatör: grid yükleniyor, internet yokken hata ekranı + "Tekrar Dene", aşağı çekip yenileme, arama, kategori → ürünler, detay galerisi, kalp her yerde senkron, sepet badge'i, adet/silme/toplam, uygulama kapatılıp açılınca favori ve sepet duruyor.
