# Vitrin – Proje Planı

Trendyol benzeri bir e-ticaret uygulaması (okul projesi, SwiftUI öğrenme amaçlı). Uygulamanın adı **Vitrin**.

## Kurallar
Bu dosya yalnızca yol haritasını ve ilerlemeyi tutar. Kurallar başka dosyalarda:
- Mimari, state, concurrency, yerelleştirme, kalıcılık, erişilebilirlik ve test kuralları: `ARCHITECTURE.md`.
- Proje özeti, kod stili, git çalışma şekli (stacked PR, push/PR/merge), build ve agent'lar: `CLAUDE.md`.
- Açık bulgular ve önerilen sıra: `REVIEW.md`.

Aşağıdaki adım açıklamaları, adımın tamamlandığı günkü hali anlatır. Sonradan değişen yerlerde "Bugün:" notu var.

## Adımlar

Merge'ler `main`'e, alttan başlayarak merge commit ile yapıldı.

| # | Branch | Base | PR | Durum |
|---|--------|------|----|-------|
| 0 | `chore/project-setup` | `main` | #1 | ✅ Merge edildi |
| 1 | `feature/core-networking` | `chore/project-setup` | #2 | ✅ Merge edildi |
| 2 | `feature/stores-persistence` | `feature/core-networking` | #3 | ✅ Merge edildi |
| 3 | `feature/app-shell` | `feature/stores-persistence` | #4 | ✅ Merge edildi |
| 4 | `feature/home-grid` | `feature/app-shell` | #5 | ✅ Merge edildi |
| 5 | `feature/home-search` | `feature/home-grid` | #6 | ✅ Merge edildi |
| 6 | `feature/product-detail` | `feature/home-search` | #7 | ✅ Merge edildi |
| 7 | `feature/categories` | `feature/product-detail` | #8 | ✅ Merge edildi |
| 8 | `feature/favorites-screen` | `feature/categories` | #9 | ✅ Merge edildi |
| 9 | `feature/cart-screen` | `feature/favorites-screen` | #10 | ✅ Merge edildi |
| 10 | `chore/claude-md` | `feature/cart-screen` | #11 | ✅ Merge edildi |
| 11 | `fix/code-review-findings` | `chore/claude-md` | #12 | ✅ Merge edildi |
| 12 | `feature/theme-selection` | `fix/code-review-findings` | #13 | ✅ Merge edildi |
| 13 | `feature/language-setting` | `feature/theme-selection` | #14 | ✅ Merge edildi |
| 14 | `fix/product-image-loading` | `feature/language-setting` | #15 | ✅ Merge edildi |
| 15 | `docs/full-review` | `fix/product-image-loading` | #16 | ✅ Merge edildi |
| 16 | `docs/architecture` | `main` | — | 🟡 PR açık |

### 0. chore/project-setup ✅
`.gitignore`, deployment target iOS 17.0, görünen ad Vitrin, `AccentColor` + `BrandAccent` renkleri, `PLAN.md`.

### 1. feature/core-networking ✅: veri katmanı (henüz UI yok)
- `Models/Product.swift`: `Product` (id, title, description, category, price, discountPercentage, rating, stock, brand?, thumbnail, images, reviews), `Review`, `ProductsResponse` (products, total, skip, limit). Hepsi `Codable, Identifiable, Hashable`. `brand` opsiyonel (bazı ürünlerde yok). Hesaplanan `discountedPrice`.
- `Models/ProductCategory.swift`: `/products/categories` `{slug, name, url}` nesneleri döndürüyor.
- `Networking/APIClient.swift`: generic `get<T: Decodable>(_ path:, query:) async throws -> T`, `APIError` (invalidURL, badStatus, decoding), Türkçe `errorDescription`.
- `Networking/ProductService.swift`: `fetchProducts()`, `searchProducts(query:)`, `fetchCategories()`, `fetchProducts(category:)` (`/products/category/{slug}`), `fetchProduct(id:)`.
- `Utilities/PriceFormatter.swift`: fiyat biçimlendirme (dummyjson fiyatları dolar: `$1,234.50`, en_US). Bugün: para birimi seçilen dile bağlı (Türkçe TL, İngilizce dolar), biçim ekrandaki locale'e göre; bkz. adım 13.
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
- `PreviewData.swift`: sadece DEBUG'da derlenen önizleme örnek ürünleri. Bugün: `#Preview` blokları Release'te de derlendiği için `#if DEBUG` kaldırıldı (adım 11).
- `LoadState<T>`: `idle`, `loading`, `loaded(T)`, `failed(String)`. Bugün: `failed(LocalizedStringResource)`, dil değişince mesaj da değişsin diye (adım 13).

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

### 9. feature/cart-screen ✅
Sepet satırları (görsel, ad, fiyat, `−` / adet / `+`; adet 1'deyken `−` çöp ikonuna döner ve ürünü çıkarır, stok sınırında `+` devre dışı), sola kaydırarak silme, toplam adet ve tutar, "Alışverişi Tamamla" (MVP'de sadece uyarı), boş sepet ekranı ("Sepetin boş" + `@Binding` ile Ana Sayfa'ya geçiren "Alışverişe Başla").

### 10. chore/claude-md ✅
- `CLAUDE.md`: proje kuralları (mimari, state, kod stili, git, build).
- `REVIEW.md`: ilk kod incelemesi (K1, O1–O10, S1–S10, T1–T2).

### 11. fix/code-review-findings ✅
İncelemedeki bulguların düzeltmesi:
- Release derlemesi (K1): önizleme verisi Release'te de derleniyor.
- Sepet toplamında kuruş farkı (O1): indirimli fiyat kuruşa yuvarlanıyor.
- Eski arama sonucu yenisini ezmiyor (O5), testli.
- Okunamayan plist `.corrupt` olarak kenara alınıyor (O3, kısmen).
- Stok ve indirim renkleri erişilebilir kontrastta (O7), kalp ve adet butonları 44 pt (O8).
- `committer` ve `pr-manager` agent'ları; `REVIEW.md`'de düzeltilen bulgular işaretlendi.

### 12. feature/theme-selection ✅
- `Models/AppTheme.swift`: `system` / `light` / `dark` (Sistem, Açık, Koyu), `colorScheme` (`system` için `nil`).
- Seçim `@AppStorage("appTheme")` ile kalıcı; `TrendyolBenzeriApp` kök view'a `.preferredColorScheme` uygular.
- `Views/Settings/SettingsView.swift`: Ana Sayfa'daki dişli butonuyla açılan sheet, "Görünüm" bölümünde segmented `Picker`.
- Renk denetimi: arka planlar zaten sistem renkleri, asset renklerinin koyu varyantları var; indirim rozetindeki beyaz yazı kırmızı zeminde iki modda da okunuyor.

### 13. feature/language-setting ✅
- `Models/AppLanguage.swift`: Sistem / Türkçe / English, `@AppStorage("appLanguage")`. "Sistem" cihazın birinci dilini takip eder, `tr` ya da `en` değilse Türkçe.
- `TrendyolBenzeriApp` kökte `.environment(\.locale, ...)` uygular; dil yeniden başlatmadan anında değişir (tab bar, arama kutusu, açık sheet dahil).
- `Localizable.xcstrings`: arayüzdeki tüm metinler, kategori adları ve hata mesajları; `en` ve `tr`, sayılı metinlerde İngilizce tekil/çoğul.
- `String` üreten metinler `LocalizedStringResource`'a çevrildi (`APIError`, `LoadState.failed`, `AppTheme.title`, kategori adları, sepet butonu, stok etiketi).
- Para birimi dile bağlı: Türkçede sabit kurla TL (1 $ = 45 TL), İngilizcede API'deki dolar fiyatı; fiyat, indirim, puan ve tarih biçimleri seçilen dile göre.
- Sınırlar: iOS'un kendi metinleri (geri butonu, aramadaki "Cancel") cihaz dilinde kalır; açık bir alert dil değişince güncellenmez, sonraki açılışta yeni dilde gelir.

### 14. fix/product-image-loading ✅
- Görsel yüklenemeyince ürün kartı küçülmüyor; yükleniyor, başarılı ve hata durumlarında alan aynı kalıyor.
- İptal edilen görsel isteği (`NSURLErrorCancelled`) hata sayılmıyor ve yeniden deneniyor; başarısız görsel, view tekrar ekrana gelince yeniden isteniyor.
- Kart, sepet satırı ve detay galerisi tek bir bileşeni kullanıyor: `ProductImageView`.
- Agent tanımları kullanıcı seviyesine taşındı, Vitrin kuralları `CLAUDE.md`'ye yazıldı. Bugün: tanımlar yeniden projede, `.claude/agents/` (adım 16).

### 15. docs/full-review ✅
`REVIEW.md` ikinci tur: ilk turdaki 23 bulgunun durumu (7 düzeltildi, 5 kısmen, 11 açık) ve 15 yeni bulgu (O11, O12, S11–S22, T3). Sonraki adımlar lint kuralları, testler ve mimari kurallar olarak ayrıldı.

### 16. docs/architecture 🟡
- `ARCHITECTURE.md`: katmanlar, klasörler, state, yükleme ve hata durumları, concurrency, yerelleştirme ve para birimi, kalıcılık, erişilebilirlik ve test kuralları; her kural için doğru/yanlış örnek. Kodun henüz uymadığı kurallar `REVIEW.md` bulgusuyla işaretli.
- `CLAUDE.md`: `ARCHITECTURE.md`'yi okuma şartı; push ve PR'ı agent'lar yapar, merge'ü proje sahibi GitHub'da yapar; `REVIEW.md` S21'deki eskimiş satırlar düzeltildi.
- `PLAN.md`: bu tablo ve adımlar bugünkü duruma getirildi.
- `.claude/agents/`: `committer` ve `pr-manager` yeniden projede.

## Sonraki adımlar
`REVIEW.md`'deki önerilen sıra: yenileme hatasında listeyi korumak ve ViewModel testleri (O11, T1), sepet ve favoriler için sürümlü kayıt (O2, O3), ağ işini arka plana almak (O4; düzeltildi, 27 Ekim 2026), erişilebilirlik turu (O12, O9, O10), Swift 6 dil modu (S11).

## Her branch için iş akışı
Ayrıntılar `CLAUDE.md`'deki "Git çalışma şekli" bölümünde. Kısaca:
1. Bir önceki branch'ten (zincir yoksa `main`'den) yeni branch aç.
2. Kodda değişiklik yapmadan önce `ARCHITECTURE.md`'yi oku.
3. Küçük, anlamlı commit'ler (`committer`); her adımın Türkçe kısa açıklaması.
4. Derle ve testleri çalıştır:
   `xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' build test`
5. Simülatörde test adımlarını ver, bu dosyada durumu ✅ yap.
6. Push ve PR'ı `pr-manager` onay beklemeden yapar (PR base'i = önceki branch). Merge'ü proje sahibi GitHub'da yapar.

## Genel doğrulama
- Unit testler: model decoding, store mantığı, plist kaydet/yükle, fiyat ve para birimi, dil ve tema, arama. Hangi katmanın testinin zorunlu olduğu `ARCHITECTURE.md`'de.
- Simülatör: grid yükleniyor, internet yokken hata ekranı + "Tekrar Dene", aşağı çekip yenileme, arama, kategori → ürünler, detay galerisi, kalp her yerde senkron, sepet badge'i, adet/silme/toplam, uygulama kapatılıp açılınca favori ve sepet duruyor.
