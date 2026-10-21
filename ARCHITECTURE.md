# Vitrin – Mimari

Bu belge, uygulamanın bugünkü yapısını ve yeni kodun uyması gereken kuralları anlatır. Yeni bir mimari önermez; var olan kalıpları yazıya döker.

- Kodda değişiklik yapmadan önce bu belge okunur.
- Kod henüz bir kurala uymuyorsa, kuralın altında **"Bugünkü durum: uyulmuyor, bkz. `REVIEW.md` …"** notu vardır. Not, kuralın geçersiz olduğu anlamına gelmez; yeni kod kurala uyar, eski kod ilgili bulgu düzeltilirken uyumlu hale gelir.
- Proje özeti, kod stili, git ve build kuralları `CLAUDE.md`'de; yol haritası `PLAN.md`'de; açık bulgular `REVIEW.md`'de.

Örneklerde ✅ doğru, ❌ yanlış kullanımı gösterir. Örnekler kısaltılmıştır.

## 1. Katmanlar ve bağımlılık yönü

```
Models  ←  Networking (APIClient)  ←  ProductService  ←  ViewModel  ←  View
   ↑                                                         ↑
   └──── Persistence (PlistStorage)  ←  Stores ──────────────┘ (environment ile)
```

Bağımlılık her zaman soldan sağa doğrudur: bir katman yalnızca kendinden önceki katmanları bilir. Store'lar ağ katmanını değil, kalıcılık katmanını kullanır.

| Katman | Klasör | Kullanabilir | Kullanamaz |
| --- | --- | --- | --- |
| Models | `Models/` | Foundation | Diğer bütün katmanlar, SwiftUI |
| API client | `Networking/APIClient.swift`, `APIError.swift` | Models | Servis, store, ViewModel, View |
| Service | `Networking/ProductService.swift` | `APIClient`, Models | Store, ViewModel, View |
| Persistence | `Persistence/` | Models | Ağ, store, ViewModel, View |
| Stores | `Stores/` | `PlistStorage`, Models | Ağ katmanı, View |
| ViewModel | `Views/<Ekran>/*ViewModel.swift` | `ProductService`, Models, `LoadState` | `APIClient`, URL, View, SwiftUI |
| View | `Views/` | ViewModel, store'lar (environment), bileşenler, Models, Utilities | `APIClient`, `ProductService`, `PlistStorage`, URL |
| Utilities | `Utilities/` | Foundation, Models | SwiftUI, environment, `AppLanguage`, store, ViewModel, View |

**Kurallar**
- View URL bilmez ve ağ isteği atmaz; veriyi ViewModel'den ya da store'dan alır.
- Endpoint'leri yalnızca `ProductService` bilir. Yeni bir endpoint `ProductService`'e fonksiyon olarak eklenir.
- ViewModel `APIClient`'ı değil `ProductService`'i kullanır; servis init'te parametre olarak alınır (testte sahte oturumla verilebilsin diye).
- Dosyaya yalnızca store'lar `PlistStorage` ile yazar.
- `Models/`, `Networking/`, `Persistence/`, `Stores/` ve `Utilities/` SwiftUI import etmez. SwiftUI'a ait şeyler (environment anahtarları, `ColorScheme`) `Views/` altında durur.
  - Bugünkü durum: uyulmuyor. `Models/AppTheme.swift` `ColorScheme` için SwiftUI import ediyor. `Utilities/PriceFormatter.swift` hem SwiftUI import ediyor hem de `Product`'ın fiyat hesaplarını içeriyor; bkz. `REVIEW.md` S12.
    - Notta geçmeyen yerler: `Models/CartItem.swift` ve `Models/Product.swift` `Utilities/`'teki `Currency` ve `roundedToCents`'e, `Stores/CartStore.swift` `Currency`'ye bağlı. Tabloya göre Models yalnızca Foundation'ı, Stores yalnızca `PlistStorage` ve Models'i kullanabilir.
- `Utilities/` yalnızca Foundation kullanır. Locale ve para birimini parametre olarak alır (`resolved(in: locale)`, `price(in: currency)`); `AppLanguage`'ı ya da environment'ı kendisi okumaz. Hangi dilin ve para biriminin geçerli olduğuna View karar verir ve parametreyle iletir.
  - Bugünkü durum: uyulmuyor. `Utilities/PriceFormatter.swift` SwiftUI import ediyor ve `\.currency` environment anahtarını (`@Entry`) tanımlıyor; anahtar `Views/` altına taşınmalı. Bkz. `REVIEW.md` S12, architect denetimi, 21 Ekim 2026.

```swift
// ✅ View, ViewModel üzerinden ister
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    var body: some View {
        content.task { await viewModel.loadIfNeeded() }
    }
}

// ❌ View doğrudan API client çağırır ve URL bilir
.task {
    let response: ProductsResponse = try await APIClient.shared.get("/products")
}
```

```swift
// ✅ Endpoint servistedir, ViewModel servisi parametre olarak alır
func fetchProducts(category slug: String) async throws -> [Product] {
    let response: ProductsResponse = try await client.get("/products/category/\(slug)")
    return response.products
}
init(service: ProductService = .shared) { self.service = service }

// ❌ ViewModel yol yazar ve istemciyi kendi oluşturur
let response: ProductsResponse = try await APIClient().get("/products/category/\(slug)")
```

## 2. Klasör yapısı

Xcode projesi "synchronized folder" yapısında: `TrendyolBenzeri/` altına eklenen dosya target'a kendiliğinden girer, `project.pbxproj` elle düzenlenmez.

| Klasör | İçerik |
| --- | --- |
| `Models/` | `Codable` veri tipleri ve onların saf hesapları: `Product`, `Review`, `ProductsResponse`, `ProductCategory` (+ `+Display`), `CartItem`, `AppTheme`, `AppLanguage` |
| `Networking/` | `APIClient`, `APIError`, `ProductService` |
| `Persistence/` | `PlistStorage` |
| `Stores/` | Ekranlar arası paylaşılan state: `FavoritesStore`, `CartStore` |
| `Views/` (kök) | Uygulama iskeleti: `MainTabView` (sekmeler ve her sekmenin `NavigationStack`'i) |
| `Views/<Ekran>/` | Bir ekranın view'ları ve ViewModel'i: `Home/`, `Categories/`, `ProductDetail/`, `Favorites/`, `Cart/`, `Settings/` |
| `Views/Common/` | Ekran durumları: `LoadState`, `LoadingView`, `ErrorView` |
| `Views/Components/` | Birden fazla ekranda kullanılan bileşenler: `ProductGridView`, `ProductCardView` (+ `PriceView`, `RatingView`), `ProductImageView`, `StarRatingView`, `FavoriteButton` |
| `Utilities/` | SwiftUI'sız biçimlendirme ve yardımcılar: `PriceFormatter`, `LocalizedStringResource+Locale`, `PreviewData` |
| `Localizable.xcstrings` | Bütün arayüz metinleri |
| `TrendyolBenzeriTests/` | Unit testler; `TestHelpers.swift` ortak örnekleri verir |

**Yeni dosya nereye konur?**

| Eklenen | Yer |
| --- | --- |
| API'den gelen yeni bir tip | `Models/<Tip>.swift` |
| Bir tipin arayüzde gösterim bilgisi (ad, ikon) | `Models/<Tip>+Display.swift` |
| Yeni endpoint | `ProductService` içine fonksiyon (yeni bir servis gerekiyorsa `Networking/<Ad>Service.swift`) |
| Yeni ekran | `Views/<Ekran>/<Ekran>View.swift`, veri yüklüyorsa yanına `<Ekran>ViewModel.swift` |
| Uygulama iskeleti (sekme yapısı, ekranları bir araya getiren kök view) | `Views/` kökü (ör. `Views/MainTabView.swift`) |
| Bir ekranın alt parçası | O ekranın klasörü (ör. `Views/ProductDetail/AddToCartBar.swift`) |
| İki ya da daha fazla ekranda kullanılan view | `Views/Components/` |
| Birden fazla ekranın paylaştığı, kalıcı state | `Stores/<Ad>Store.swift` |
| Kullanıcı ayarı (tema, dil gibi) | `Models/App<Ad>.swift` (enum) + `@AppStorage` |
| Test | `TrendyolBenzeriTests/<Konu>Tests.swift` |

`MainTabView` neden `Views/` kökünde? Tek bir ekran değil, bütün ekranları kapsar; bu yüzden `Views/<Ekran>/` klasörlerinden birine ait değil. Bir ekran durumu olmadığı için `Views/Common/`'a, yeniden kullanılan bir bileşen olmadığı için (yalnızca `TrendyolBenzeriApp` kullanır) `Views/Components/`'a da uymaz. `TrendyolBenzeriApp`'in uygulama kökünde durması gibi, `MainTabView` da view'ların kökünde durur. `MainTabView.Tab` aynı dosyada kalır.

```
// ✅ Sepet satırı yalnızca Sepet ekranında kullanılıyor
Views/Cart/CartItemRow.swift

// ❌ Tek ekranda kullanılan parça Components'te, ya da ViewModel Models'te
Views/Components/CartItemRow.swift
Models/HomeViewModel.swift
```

## 3. State management

| Durum | Araç | Örnek |
| --- | --- | --- |
| Yalnızca bir view'a ait değer | `@State private var` | `showsCheckoutAlert`, `searchText` |
| Bir ekranın ViewModel'i | `@State private var viewModel` | `HomeViewModel()` |
| Üst view'a ait değeri alt view'un değiştirmesi | `@Binding` | Seçili sekme: `MainTabView` → `FavoritesView`, `CartView` |
| Birden fazla ekranın paylaştığı state | `@Observable` store, kökte `@State` + `.environment(store)` | `FavoritesStore`, `CartStore` |
| Bütün ağaca verilen ayar | `.environment(\.key, değer)` | `\.locale`, `\.currency` |
| Uygulama kapanınca da kalan küçük ayar | `@AppStorage` | `AppTheme`, `AppLanguage` |

**Kurallar**
- Store'lar yalnızca `TrendyolBenzeriApp` içinde bir kez oluşturulur; view'lar `@Environment(CartStore.self)` ile okur. View içinde yeni store oluşturulmaz.
- ViewModel `@Observable final class`'tır; durumu `private(set) var` ile dışarıya salt okunur verir, bağımlılıkları `@ObservationIgnored` tutar.
- ViewModel bir parametreye bağlıysa init'te `_viewModel = State(initialValue: …)` ile kurulur. Init hafif tutulur; istek `.task`'ta başlar.
- Türetilmiş state saklanmaz, hesaplanır. Toplam adet, toplam tutar, sıralı liste, "favori mi" gibi değerler kaynak veriden (`items`) her seferinde hesaplanan özellik ya da fonksiyondur. Böylece kaynak değişince eski kalamazlar.
- Aynı `@AppStorage` anahtarı birden fazla yerde okunursa anahtar tipin `storageKey` sabitinden gelir.
  - Bugünkü durum: uyulmuyor. Varsayılan değer (`.system`) iki yerde ayrı yazılmış; bkz. `REVIEW.md` S19.
- **Önizlemeler:** Her önizleme, uygulamanın kökte verdiği bütün environment değerlerini (`FavoritesStore`, `CartStore`, `\.locale`, `\.currency`, tema) tek bir ortak önizleme yardımcısından alır. Kalıcılıkta `PlistStorage.preview` kullanılır (bkz. 7. Kalıcılık). Yardımcı bir SwiftUI modifier'ı olduğu için `Views/` altında durur.
  - Bugünkü durum: uyulmuyor. Ortak yardımcı yok; her önizleme environment'ı kendisi kuruyor. `HomeView`, `CategoryProductsView` ve `ProductGridView` önizlemeleri `CartStore` vermiyor, detaya geçince çöküyor; bkz. `REVIEW.md` S20. Kendi klasörünü kuran önizlemeler için bkz. `REVIEW.md` S8.

```swift
// ✅ Türetilmiş değer hesaplanır
var totalQuantity: Int {
    items.values.reduce(0) { $0 + $1.quantity }
}

// ❌ Türetilmiş değer saklanır; her değişiklikte elle güncellenmesi gerekir ve unutulunca yanlış kalır
private(set) var totalQuantity = 0
func add(_ product: Product) { …; totalQuantity += 1 }
```

```swift
// ✅ Paylaşılan store environment'tan okunur
@Environment(CartStore.self) private var cartStore

// ❌ View kendi store'unu oluşturur; diğer ekranlarla senkron kalmaz
@State private var cartStore = CartStore()
```

## 4. Yükleme ve hata durumları

Ağdan veri yükleyen her ekran `LoadState<Value>` kullanır:

```swift
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(LocalizedStringResource)
}
```

**ViewModel kalıbı**

| Fonksiyon | Nereden çağrılır | Davranış |
| --- | --- | --- |
| `loadIfNeeded()` | `.task` | Durum `.idle` ise `load()` çağırır; veri varsa istek atmaz |
| `load()` | İlk açılış, "Tekrar Dene" | `state = .loading`, sonra veriyi çeker |
| `refresh()` | `.refreshable` | `.loading`'e geçmez; mevcut veri ekranda kalır |

**Kurallar**
- View `switch viewModel.state` ile `LoadingView`, `ErrorView(message:retry:)`, boşsa `ContentUnavailableView`, doluysa içeriği gösterir.
- Hata mesajı `error.userMessage` ile verilir (`LocalizedStringResource`); `String` değil.
- `CancellationError` hata sayılmaz. Yükleme sırasında iptal olursa durum `.idle`'a döner ki ekran bir sonraki açılışta yeniden yüklesin.
- Yenileme başarısız olursa mevcut liste silinmez. `refresh()` hata aldığında `state`'e dokunmaz; hata ayrı ve geçici olarak gösterilir.
  - Bugünkü durum: uyulmuyor. Üç ViewModel'de de yenileme hatası `state = .failed(...)` yazıyor ve liste kayboluyor; bkz. `REVIEW.md` O11.
- Arama gibi art arda gelen isteklerde yalnızca en son isteğin sonucu yazılır (`HomeViewModel.search` içindeki `latestQuery` kontrolü).

```swift
// ✅ Yenileme hatası mevcut veriyi korur
func refresh() async {
    do {
        state = .loaded(try await service.fetchProducts(limit: 0))
    } catch is CancellationError {
    } catch {
        refreshError = error.userMessage   // geçici uyarı; liste ekranda kalır
    }
}

// ❌ Yenileme hatası listeyi tam ekran hatayla değiştirir (bugünkü kod)
func refresh() async {
    await fetchProducts()   // hata olursa state = .failed(...)
}
```

```swift
// ✅ İptal hata ekranı göstermez
} catch is CancellationError {
    if case .loading = state { state = .idle }
}

// ❌ İptal kullanıcıya hata olarak gösterilir
} catch {
    state = .failed(error.userMessage)
}
```

## 5. Concurrency

Proje ayarları:
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`: işaretlenmemiş her tip MainActor'dadır.
- `SWIFT_APPROACHABLE_CONCURRENCY` açık: `nonisolated async` bir fonksiyon, çağıranın actor'ünde çalışır.

| Kod | İzolasyon |
| --- | --- |
| View, ViewModel, store | MainActor (varsayılan). UI state'i yalnızca burada değişir |
| Models, `APIClient`, `APIError`, `ProductService`, `PlistStorage`, `Currency` | `nonisolated` + `Sendable` |
| Store ve ViewModel testleri | `@MainActor` |

**Kurallar**
- Asenkron iş `async`/`await` ile yapılır. Completion handler, `DispatchQueue` ve `Combine` kullanılmaz. Kural test kodunu da kapsar (bkz. 9. Testler).
- Görevler view'un yaşam döngüsüne bağlanır: `.task`, `.task(id:)`, `.refreshable`. View kapanınca görev iptal olur. Yapılandırılmamış `Task { }` yalnızca bir butondan iş başlatmak gerektiğinde kullanılır.
  - Bugünkü durum: `ErrorView`'daki "Tekrar Dene" `Task { }` ile başlıyor ve iptal edilmiyor; bkz. `REVIEW.md` S22.
- Actor sınırından geçen her tip `Sendable`'dır. Yeni model, servis ve kalıcılık tipleri `nonisolated` ve `Sendable` yazılır.
- Ağ ve JSON çözme işi ana thread'de yapılmaz; bu tür fonksiyonlar `@concurrent` ile işaretlenir.
  - Bugünkü durum: uyulmuyor. `APIClient.get` çağıranın actor'ünde, yani ana thread'de çalışıyor; bkz. `REVIEW.md` O4.
- Proje Swift 6 dil modunda tutulur; veri yarışı riskleri derleme hatası olur.
  - Bugünkü durum: uyulmuyor. `SWIFT_VERSION = 5.0`; kod Swift 6'da uyarısız derleniyor ama ayar değişmedi; bkz. `REVIEW.md` S11.

```swift
// ✅ Ağ katmanı nonisolated ve Sendable, ağır iş arka planda
nonisolated struct APIClient: Sendable {
    @concurrent
    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T { … }
}

// ❌ Ağ tipi MainActor'da kalır (işaretlenmemiş) ya da sonuç DispatchQueue ile ana thread'e taşınır
struct APIClient { … }
DispatchQueue.main.async { self.state = .loaded(products) }
```

```swift
// ✅ Görev view'a bağlı; arama metni değişince eskisi iptal olur
.task(id: searchText) { await viewModel.search(searchText) }

// ❌ Her değişiklikte iptal edilmeyen yeni bir görev başlar
.onChange(of: searchText) { Task { await viewModel.search(searchText) } }
```

## 6. Yerelleştirme ve para birimi

**Metinler**
- Arayüz metinleri (hata ve erişilebilirlik metinleri dahil) kodda Türkçe yazılır ve `Localizable.xcstrings`'te anahtar olur; her anahtarın `en` ve `tr` karşılığı vardır.
- Metin `Text("…")`, `Label`, `Button` gibi `LocalizedStringKey` alan API'lerle ya da `LocalizedStringResource` olarak taşınır. `String` cihaz dilinde çözüldüğü için arayüz metni `String` olarak üretilmez.
- `String` gerekiyorsa (sıralama, test) `resource.resolved(in: locale)` kullanılır.
  - Bugünkü durum: uyulmuyor. `APIError.errorDescription` `String(localized:)` ile cihaz dilinde çözülüyor; sepet ve favoriler cihaz locale'iyle sıralanıyor; bkz. `REVIEW.md` S16.
- API'den gelen ürün adı, açıklama, marka ve yorumlar çevrilmez.

**Dil, locale ve para birimi**
- Seçilen dil `@AppStorage(AppLanguage.storageKey)` ile saklanır. Locale ve para birimi aynı değerden birlikte türetilir: `language.locale()` ve `language.currency()`.
- İkisi de yalnızca `TrendyolBenzeriApp` kökünde, yan yana verilir: `.environment(\.locale, …)` ve `.environment(\.currency, …)`. Başka yerde locale ya da para birimi seçilmez.
  - Bugünkü durum: `\.currency`'nin varsayılanı (`.lira`) `\.locale`'in varsayılanından bağımsız; kök dışındaki önizlemelerde ikisi uyuşmayabiliyor; bkz. `REVIEW.md` S14. "Sistem" dili cihazın bölgesini kaybediyor; bkz. `REVIEW.md` S15.

**Fiyatlar**
- API dolar verir. Türkçede sabit kurla (`ExchangeRate.usdToTry` = 45) TL, İngilizcede dolar gösterilir.
- Fiyatlar tek bir yerden hesaplanır ve biçimlenir (`Utilities/PriceFormatter.swift`): view `@Environment(\.currency)` okur, tutarı `price(in:)` / `discountedPrice(in:)` / `lineTotal(in:)` / `totalPrice(in:)` ile alır ve `Text(tutar, format: currency.format)` ile gösterir.
- Satır toplamı görünen birim fiyat × adet, sepet toplamı görünen satırların toplamıdır; kuruşa yuvarlanır.
- İndirim rozeti `Text(product.discountRate, format: .discount)`.
- Elle biçimlendirme, sabit para birimi kodu ve sabit locale yazılmaz.

```swift
// ✅ Metin catalog'dan, fiyat ortak hesap ve biçimle
@Environment(\.currency) private var currency
Text("Sepete Ekle")
Text(product.discountedPrice(in: currency), format: currency.format)

// ❌ String metin, elle biçim, sabit para birimi
Text(String(localized: "Sepete Ekle"))
Text("₺" + String(format: "%.2f", product.price * 45))
Text(product.price, format: .currency(code: "USD"))
```

```swift
// ✅ Locale ve para birimi kökte, aynı dilden birlikte
.environment(\.locale, language.locale())
.environment(\.currency, language.currency())

// ❌ Bir ekran kendi locale'ini seçer
.environment(\.locale, Locale(identifier: "en_US"))
```

## 7. Kalıcılık

- Favoriler ve sepet, store'lar tarafından Documents altında plist olarak saklanır: `favorites.plist` (`[Int: Product]`), `cart.plist` (`[Int: CartItem]`). Anahtar ürün id'sidir.
- Yazma ve okuma yalnızca `PlistStorage` ile yapılır. Store her değişiklikten sonra kaydeder, açılışta yükler.
- Dosya yoksa (ilk açılış) store boş başlar.
- Dosya çözülemezse (bozuk ya da eski biçim) store boş başlar ve dosya `<ad>.plist.corrupt` olarak kenara alınır; böylece ilk kayıt eski veriyi ezmez.
- Testler ve önizlemeler gerçek dosyalara yazmaz: testler `PlistStorage.temporary()`, önizlemeler `PlistStorage.preview` kullanır.
  - Bugünkü durum: uyulmuyor. `PlistStorage.preview` her çağrıda aynı geçici klasörü veriyor, bu yüzden önizlemeler arasında veri birikiyor. `Views/Cart/CartView.swift` (iki önizleme) ve `Views/Favorites/FavoritesView.swift` `.preview` yerine `PlistStorage(directory:)` ile kendi klasörünü kuruyor; klasörü oluşturmadıkları için kayıt sessizce başarısız oluyor. Bkz. `REVIEW.md` S8.
- Plist'e API modeli (`Product`) değil, sürümlü ve küçük bir kayıt tipi (id, adet) yazılır; ürün bilgisi açılışta API'den tazelenir. Şema değişince göç ya da yedek zorunludur.
  - Bugünkü durum: uyulmuyor. Plist'te `Product`'ın tamamı saklanıyor ve tazelenmiyor; ikinci bozulmada eski `.corrupt` yedeği siliniyor; bkz. `REVIEW.md` O2, O3, S18.

```swift
// ✅ Çözülemeyen dosya kenara alınır, store boş başlar
do {
    items = try storage.load([Int: CartItem].self, from: fileName) ?? [:]
} catch {
    storage.moveAsideCorruptFile(fileName)
}

// ❌ Hata yutulur; boş sepet ilk kayıtta eski dosyanın üzerine yazılır
items = (try? storage.load([Int: CartItem].self, from: fileName)) ?? [:]
```

```swift
// ✅ Test geçici klasör kullanır
let store = CartStore(storage: try .temporary())

// ❌ Test kullanıcının gerçek sepet dosyasına yazar
let store = CartStore()
```

## 8. Erişilebilirlik

- **Kontrast:** Metin ile zemini arasında en az 4,5:1, büyük metin (≥ 18 pt ya da ≥ 14 pt kalın) ve ikonlarda en az 3:1. Bu oran açık ve koyu temada ayrı ayrı sağlanır.
  - Anlam taşıyan renkler Assets'ten, Xcode'un ürettiği adlarla gelir: `.discountBadge`, `.stockAvailable`, `.stockLow`, `.stockOut`, `.brandAccent`. Metin ya da dolgu için `.green`, `.red`, `.orange` gibi sistem renkleri kullanılmaz.
  - Anlam taşıyan her ikon (kalp, yıldız, rozet) zeminiyle en az 3:1 kontrast verir. İkonlarda da `.red` dahil sistem renkleri yerine Assets renkleri kullanılır.
  - Bugünkü durum: uyulmuyor. Kalp (`Views/Components/FavoriteButton.swift`) favorideyken `.red`, değilken `.secondary`, zemini `.regularMaterial`. Hesaplanan değerler (cihazda ölçülmedi; material yarı saydam olduğu için arkadaki görsele göre değişir): dolu kalp açık temada ≈3,2–3,5:1, koyu temada ≈4–5:1; boş kalp açık temada ≈3,1–3,5:1. Eşiği geçiyor ama payı küçük; sistem rengi (`.red`) kullandığı için kurala uymuyor. Bkz. architect denetimi, 21 Ekim 2026.
  - Bilgi yalnızca renkle verilmez; yanında metin ya da ikon olur.
  - Bugünkü durum: uyulmuyor. "Sepete Eklendi" butonu `.green` üzerinde beyaz yazı kullanıyor (≈2:1); bkz. `REVIEW.md` O12.
  - Bugünkü durum: uyulmuyor. Puan yıldızları `.orange` ile çiziliyor (`Views/Components/StarRatingView.swift`, `Views/Components/ProductCardView.swift`); sistem turuncusu açık temada beyaz zeminde ≈2,2:1. Değerlendirme satırlarında puanı gösteren tek şey bu yıldızlar. Bkz. architect denetimi, 21 Ekim 2026.
- **Dokunma alanı:** Her dokunulabilir öğe en az 44×44 pt'dir. Görünen şekil küçükse alan `.frame(width: 44, height: 44)` + `.contentShape(Rectangle())` ile büyütülür (`FavoriteButton`, sepet adet butonları).
- **VoiceOver:** Yalnızca ikondan oluşan butonların etiketi vardır; tekrar eden butonların (kalp, adet) etiketi ürün adını içerir; dekoratif görseller gizlenir.
  - Bugünkü durum: kısmen uyuluyor. Kalp etiketi ürün adını içermiyor, kart tek öğe değil; bkz. `REVIEW.md` O9.
    - Notta geçmeyen yerler: sepet adet butonlarının etiketi ürün adını içermiyor ve adet değeri bağlamsız okunuyor (`Views/Cart/CartItemRow.swift`); başarıyla yüklenen ürün görseli ne etiketli ne gizli (`Views/Components/ProductImageView.swift`).
- **Dynamic Type:** Yazılar metin stilleriyle (`.headline`, `.caption`) verilir; ikon ve sabit boyutlar `@ScaledMetric` ile büyür.
  - Bugünkü durum: uyulmuyor. `.system(size:)` ve sabit çerçeveler var; bkz. `REVIEW.md` O10.
    - Notta geçmeyen yerler: `.system(size:)` `FavoriteButton` ve `StarRatingView`'da; sabit boyutlar `StarRatingView`, `CartItemRow` ve `ProductImageGallery`'de; `StarRatingView`'a sabit `size:` veren çağrılar `ProductDetailView` ve `ReviewRowView`'da.

```swift
// ✅ 44 pt dokunma alanı, Assets rengi, etiket
Image(systemName: "heart")
    .frame(width: 34, height: 34)
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
    .accessibilityLabel(Text("\(product.title) ürününü favorilere ekle"))
Text("Tükendi").foregroundStyle(Color.stockOut)

// ❌ Küçük dokunma alanı, düşük kontrastlı sistem rengi, etiketsiz ikon
Image(systemName: "heart")
    .frame(width: 24, height: 24)
Text("Sepete Eklendi").foregroundStyle(.white).background(.green)
```

## 9. Testler

Testler Swift Testing ile yazılır ve ağa çıkmaz. Ortak örnekler `TestHelpers.swift` içindedir: `Product.sample(...)`, `PlistStorage.temporary()`.

| Katman | Test | Zorunlu mu |
| --- | --- | --- |
| Models | Decode (örnek JSON), hesaplar (indirim, fiyat, kategori adları, dil çözümleme) | Evet |
| Fiyat ve para birimi | Yuvarlama, TL ve dolar tutarları, sepet toplamı | Evet |
| Stores | Ekleme, çıkarma, stok sınırı, kaydet/yükle, bozuk dosya | Evet |
| ViewModel | `load` → `.loaded` / `.failed`, iptalde `.idle`, yenileme hatası listeyi korur, arama | Evet |
| API client | Durum kodu, decode ve iptal hatalarının eşlenmesi | Evet |
| View | — | Hayır; davranış ViewModel'e konup orada test edilir |

**Kurallar**
- Bir hata düzeltilince onu yakalayan bir test eklenir.
- Store ve ViewModel testleri `@MainActor`'dır.
- Ağ isteği gereken testler `URLProtocol` tabanlı sahte bir oturumla (`APIClient(session:)`) yazılır.
- Unit testler gerçek ağa çıkmaz. İstek atmaması beklenen testler de gerçek `URLSession` yerine `URLProtocol` stub'ı kullanır; böylece kod bozulsa bile test ağa çıkamaz.
- Testler ve test yardımcıları (stub'lar dahil) `DispatchQueue` ya da `sleep` / `Task.sleep` ile beklemez; `async`/`await` kullanır (bkz. 5. Concurrency).
  - Bugünkü durum: uyulmuyor. `TrendyolBenzeriTests/HomeViewModelTests.swift`:
    - Boş arama testi gerçek `URLSession`'lı bir `APIClient` (`https://invalid.example`) kullanıyor. Bugün istek atılmadığı için ağa çıkmıyor, ama kod bozulursa çıkar.
    - Eski arama testi `Task.sleep(for: .milliseconds(100))` ile bekliyor.
    - `SearchStubURLProtocol` yanıtı `DispatchQueue.global().asyncAfter` ile geciktiriyor.
    - Bkz. architect denetimi, 21 Ekim 2026.
- View içinde test edilmesi gereken bir kural varsa (sıralama, yeniden deneme) test edilebilir bir tipe ya da fonksiyona çıkarılır.
- Bugünkü durum: uyulmuyor. ViewModel'lerin yükleme, yenileme ve iptal geçişleri ile `APIClient` hata eşlemesi test edilmiyor; yalnızca aramanın testi var; bkz. `REVIEW.md` T1, T3.

```swift
// ✅ Store testi: MainActor, geçici klasör, örnek ürün
@MainActor
@Test func addDoesNotExceedStock() throws {
    let store = CartStore(storage: try .temporary())
    let product = Product.sample(stock: 1)
    store.add(product)
    store.add(product)
    #expect(store.quantity(of: product) == 1)
}

// ❌ Gerçek ağa çıkan ve gerçek dosyaya yazan test
@Test func loadsProducts() async {
    let viewModel = HomeViewModel()          // dummyjson.com'a istek atar
    await viewModel.load()
    #expect(CartStore().isEmpty)             // kullanıcının sepetini okur
}
```
