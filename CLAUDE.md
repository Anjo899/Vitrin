# Vitrin (TrendyolBenzeri)

## Proje özeti
- Trendyol benzeri bir e-ticaret uygulaması; adı **Vitrin**. Trendyol'un adı, logosu ve görselleri kullanılmaz.
- Okul projesi ve SwiftUI öğrenme projesi: her adım Türkçe ve kısaca açıklanır.
- SwiftUI, minimum iOS 17. Yol haritası ve ilerleme `PLAN.md`'de.
- Veri kaynağı [dummyjson.com](https://dummyjson.com): `/products`, `/products/search?q=`, `/products/categories`, `/products/category/{slug}`. API'den gelen metinler İngilizce.
- Xcode projesi "synchronized folder" yapısında: `TrendyolBenzeri/` altına eklenen dosya target'a otomatik girer, `project.pbxproj` elle düzenlenmez.

## Mimari
| Klasör | Sorumluluk |
| --- | --- |
| `Models/` | `Codable` veri tipleri: `Product`, `Review`, `ProductsResponse`, `ProductCategory` (+ `+Display`: slug → Türkçe ad ve SF Symbol), `CartItem` |
| `Networking/` | `APIClient` (generic `get`, tarih çözen `JSONDecoder.dummyJSON`), `APIError` (Türkçe hata mesajları), `ProductService` (endpoint'leri bilen tek yer) |
| `Persistence/` | `PlistStorage`: `Codable` değerleri Documents'a plist olarak yazar ve okur |
| `Stores/` | Paylaşılan state: `FavoritesStore`, `CartStore` |
| `Views/<Ekran>/` | Ekran view'ları ve varsa ekranın `ViewModel`'i (`Home/`, `Categories/`, `ProductDetail/`, `Favorites/`, `Cart/`) |
| `Views/Common/` | `LoadState`, `LoadingView`, `ErrorView` |
| `Views/Components/` | Tekrar kullanılan bileşenler (aşağıda) |
| `Utilities/` | `PriceFormatter`, `PreviewData` (önizleme verisi; `#Preview` blokları Release'te de derlendiği için `#if DEBUG` içine alınmaz) |

- Akış: View → ViewModel → `ProductService` → `APIClient`. View'lar URL bilmez.
- Projede `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. View, ViewModel ve store'lar MainActor'da; modeller, ağ katmanı ve `PlistStorage` `nonisolated` + `Sendable`.
- `SWIFT_APPROACHABLE_CONCURRENCY` açık (`NonisolatedNonsendingByDefault`): `nonisolated async` bir fonksiyon çağıranın actor'ünde çalışır. Yani ViewModel'den çağrılan `APIClient.get` JSON'u şu an ana thread'de çözüyor; işi arka plana almak için `@concurrent` gerekir (`REVIEW.md` O4).

## State management
- **`@State`**: ekrana ait değerler ve ekranın ViewModel'i (`@State private var viewModel = HomeViewModel()`). ViewModel bir parametreye bağlıysa init'te `_viewModel = State(initialValue: …)`.
- **ViewModel**: `@Observable final class`, durum `private(set) var state: LoadState<T>`, bağımlılıklar `@ObservationIgnored`. Kalıp: `loadIfNeeded()` (`.task`), `load()` (ilk yükleme / Tekrar Dene), `refresh()` (`.refreshable`, eski liste ekranda kalır). `CancellationError` hata sayılmaz; yükleme iptal olursa durum `.idle`'a döner.
- **`LoadState`** (`idle` / `loading` / `loaded` / `failed(String)`): View `switch` ile `LoadingView`, `ErrorView(message:retry:)`, boşsa `ContentUnavailableView` ya da içeriği gösterir.
- **`.environment`**: `FavoritesStore` ve `CartStore`, `TrendyolBenzeriApp` içinde bir kez `@State` olarak oluşturulur ve `.environment(...)` ile verilir; view'lar `@Environment(CartStore.self)` ile okur. View içinde yeni store örneği oluşturulmaz.
- **Store'lar**: ürün id'sine bağlı dictionary (`[Int: Product]`, `[Int: CartItem]`) tutar ve her değişiklikte `favorites.plist` / `cart.plist`'e kaydeder. Sepete stoktan fazla ürün eklenemez, adet 0'a inince satır silinir, toplamlar indirimli fiyatla hesaplanır.
- **`@Binding`**: seçili sekme `MainTabView`'a ait; `FavoritesView` ve `CartView`'a binding olarak verilir (boş durum butonları Ana Sayfa'ya geçirir).
- **Navigasyon**: her sekmenin kendi `NavigationStack`'i var. Geçişler `NavigationLink(value:)` ile, hedefler sekmenin kök view'unda `.navigationDestination(for: Product.self)` (Kategoriler'de ayrıca `ProductCategory.self`) ile tanımlı.

## Kod kuralları
- Tip, değişken, fonksiyon ve dosya adları İngilizce; arayüz metinleri (hata ve erişilebilirlik metinleri dahil) Türkçe. Kod yorumları Türkçe.
- Fiyatlar dolar cinsinden: her zaman `Double.formattedPrice` (`$1,234.50`); indirim rozeti `product.discountLabel` (`%10`). Elle biçimlendirme yapılmaz.
- Önce var olan bileşen kullanılır:
  - `ProductGridView`: her ürün grid'i. Bulunduğu stack'te `Product` hedefi tanımlı olmalı.
  - `ProductCardView`, `PriceView`, `RatingView`, `StarRatingView`: kart, fiyat ve puan gösterimi.
  - `FavoriteButton`: favori kalbi; arayüzde favori ekleyip çıkarmanın tek yolu.
  - `LoadingView`, `ErrorView`, `ContentUnavailableView`: yükleniyor, hata ve boş durumlar.
- Önizlemeler `PreviewData` örneklerini ve `PlistStorage.preview`'u kullanır; gerçek favori ve sepet dosyalarına yazılmaz.
- Testler Swift Testing ile yazılır. `TestHelpers.swift` içindeki `Product.sample(...)` ve `PlistStorage.temporary()` kullanılır; store testleri `@MainActor`.

## Git çalışma şekli
- Branch adları: `feature/<ad>`, `fix/<ad>`, `chore/<ad>`.
- Stacked PR: yeni branch bir önceki özellik branch'inden açılır, PR'ın base'i o branch olur.
- Push, PR ve merge işlerinin hepsini proje sahibi yapar; hoca yalnızca yönlendirir, merge yapmaz. `main`'e merge yapılabilir.
- Stacked PR'lar en alttan başlayarak sırayla `--merge` ile merge edilir (squash zinciri bozar). Her merge'den sonra bir üstteki PR'ın base'i `main`'e çevrilir. Repo'da "Automatically delete head branches" açık.
- Commit mesajları İngilizce Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`). Her commit tek bir anlamlı adım ve kendi başına derlenir.
- Her özellik ayrı PR. PR açıklaması Türkçe: Özet, Değişiklikler, Nasıl test edilir.
- Özellik bitince: `PLAN.md`'de ✅ işaretlenir, test adımları verilir ve sonraki özelliğe geçmeden onay beklenir.
- Her push ve her merge proje sahibinin açık onayıyla yapılır; bir onay yalnızca o işlem için geçerlidir.
- Remote: `https://github.com/Anjo899/Vitrin`. PR'lar `gh` ile açılır.

## Build ve test
```sh
# Derleme
xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' build

# Unit testler (sonuç satırı: "✔ Test run with N tests …")
xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' test
```
- Geliştirme makinesine özel: Xcode `~/Downloads/Xcode.app` içinde ve `xcode-select` Command Line Tools'u gösteriyor. Komutların başına `DEVELOPER_DIR=/Users/skilic/Downloads/Xcode.app/Contents/Developer` eklenir. `gh`, `/opt/homebrew/bin` içinde.
- Paylaşılan `TrendyolBenzeri` scheme'inin test aksiyonu yalnızca `TrendyolBenzeriTests`'i çalıştırır:
  - Paralel test kapalı (`parallelizable = "NO"`). Kopya simülatörlerde test çalıştırma takılmıştı.
  - Şablon UI testleri (`TrendyolBenzeriUITests`) scheme'den çıkarıldı; dosyaları duruyor. Geri eklenmez.
- Xcode'da çalıştırmak için ⌘R, testler için ⌘U.

## Agents
Tanımlar `.claude/agents/` içinde.
- Commit işleri `committer` agent'ı ile yapılır: `main`'de commit atmaz, dosyaları adıyla ekler (`xcuserdata`, `.DS_Store` gibi dosyaları eklemez), push yapmaz.
- Push, PR açma ve merge işleri `pr-manager` agent'ı ile yapılır: `gh` kullanır, push ve merge'den önce açık onay ister, stacked PR'ları alttan başlayarak `gh pr merge --merge --delete-branch` ile merge eder ve üstteki PR'ın base'ini `main`'e çevirir.
