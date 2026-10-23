# Vitrin (TrendyolBenzeri)

## Proje özeti
- Trendyol benzeri bir e-ticaret uygulaması; adı **Vitrin**. Trendyol'un adı, logosu ve görselleri kullanılmaz.
- Okul projesi ve SwiftUI öğrenme projesi: her adım Türkçe ve kısaca açıklanır.
- SwiftUI, minimum iOS 17. Yol haritası ve ilerleme `PLAN.md`'de.
- Veri kaynağı [dummyjson.com](https://dummyjson.com): `/products`, `/products/search?q=`, `/products/categories`, `/products/category/{slug}`. API'den gelen metinler İngilizce.
- Xcode projesi "synchronized folder" yapısında: `TrendyolBenzeri/` altına eklenen dosya target'a otomatik girer, `project.pbxproj` elle düzenlenmez.

## Mimari
**Kodda değişiklik yapmadan önce `ARCHITECTURE.md` okunur.** Katmanlar ve bağımlılık yönü, yeni dosyanın yeri, state, yükleme ve hata durumları, concurrency, yerelleştirme ve para birimi, kalıcılık, erişilebilirlik ve test kuralları doğru/yanlış örnekleriyle orada. Bu dosya ile çelişirse `ARCHITECTURE.md` geçerlidir. Kodun henüz uymadığı kurallar orada "Bugünkü durum: uyulmuyor" notuyla işaretli; yeni kod kurala uyar.

Özet:

| Klasör | Sorumluluk |
| --- | --- |
| `Models/` | `Codable` veri tipleri: `Product`, `Review`, `ProductsResponse`, `ProductCategory` (+ `+Display`: slug → çevrilen ad ve SF Symbol), `CartItem`, `AppTheme`, `AppLanguage` |
| `Networking/` | `APIClient` (generic `get`, tarih çözen `JSONDecoder.dummyJSON`), `APIError` (Türkçe hata mesajları), `ProductService` (endpoint'leri bilen tek yer) |
| `Persistence/` | `PlistStorage`: `Codable` değerleri Documents'a plist olarak yazar ve okur |
| `Stores/` | Paylaşılan state: `FavoritesStore`, `CartStore` |
| `Views/` (kök) | Uygulama iskeleti: `MainTabView` |
| `Views/<Ekran>/` | Ekran view'ları ve varsa ekranın `ViewModel`'i (`Home/`, `Categories/`, `ProductDetail/`, `Favorites/`, `Cart/`, `Settings/`) |
| `Views/Common/` | `LoadState`, `LoadingView`, `ErrorView`; önizleme yardımcısı `PreviewEnvironment` (henüz yok) |
| `Views/Components/` | Tekrar kullanılan bileşenler (aşağıda) |
| `Utilities/` | SwiftUI'sız yardımcılar; yalnızca Foundation import eder, Models'i kullanabilir (Models Utilities'i kullanamaz): `PriceFormatter` (`.discount` biçimi), `LocalizedStringResource+Locale` (`resolved(in:)`), `PreviewData` (önizleme verisi ve `PlistStorage.preview`; `#Preview` blokları Release'te de derlendiği için `#if DEBUG` içine alınmaz). Bugünkü durum: `PriceFormatter` SwiftUI import ediyor; `Currency`, `ExchangeRate`, `roundedToCents`, `Product`'ın fiyat hesapları (`price(in:)`, `discountedPrice(in:)`, `discountRate`) ve `\.currency` environment değerini de içeriyor. Hedef yerleri Models ve `Views/` (`ARCHITECTURE.md` 1. Katmanlar) |

- Akış: View → ViewModel → `ProductService` → `APIClient`. View'lar URL bilmez.
- Projede `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. View, ViewModel ve store'lar MainActor'da; modeller, ağ katmanı ve `PlistStorage` `nonisolated` + `Sendable`.
- `SWIFT_APPROACHABLE_CONCURRENCY` açık (`NonisolatedNonsendingByDefault`): `nonisolated async` bir fonksiyon çağıranın actor'ünde çalışır. Yani ViewModel'den çağrılan `APIClient.get` JSON'u şu an ana thread'de çözüyor; işi arka plana almak için `@concurrent` gerekir (`REVIEW.md` O4).

## State management
- **`@State`**: ekrana ait değerler ve ekranın ViewModel'i (`@State private var viewModel = HomeViewModel()`). ViewModel bir parametreye bağlıysa init'te `_viewModel = State(initialValue: …)`.
- **ViewModel**: `@Observable final class`, durum `private(set) var state: LoadState<T>`, bağımlılıklar `@ObservationIgnored`. Kalıp: `loadIfNeeded()` (`.task`), `load()` (ilk yükleme / Tekrar Dene), `refresh()` (`.refreshable`, `.loading`'e geçmez). Kural: yenileme başarısız olursa mevcut liste silinmez. Bugünkü durum: uyulmuyor, yenileme hatası `state = .failed` yazıyor (`REVIEW.md` O11). `CancellationError` hata sayılmaz; yükleme iptal olursa durum `.idle`'a döner.
- **`LoadState`** (`idle` / `loading` / `loaded` / `failed(LocalizedStringResource)`; ViewModel'ler `error.userMessage` verir): View `switch` ile `LoadingView`, `ErrorView(message:retry:)`, boşsa `ContentUnavailableView` ya da içeriği gösterir.
- **`.environment`**: `FavoritesStore` ve `CartStore`, `TrendyolBenzeriApp` içinde bir kez `@State` olarak oluşturulur ve `.environment(...)` ile verilir; view'lar `@Environment(CartStore.self)` ile okur. View içinde yeni store örneği oluşturulmaz. Yazılı istisna: `#Preview` blokları store'ları `.previewEnvironment` üzerinden alır ve yardımcı önizleme için store oluşturur (`ARCHITECTURE.md` 3. State management).
- **Store'lar**: ürün id'sine bağlı dictionary (`[Int: Product]`, `[Int: CartItem]`) tutar ve her değişiklikte `favorites.plist` / `cart.plist`'e kaydeder. Sepete stoktan fazla ürün eklenemez, adet 0'a inince satır silinir, toplamlar indirimli fiyatla hesaplanır.
- **`@AppStorage`**: tema (`AppTheme.storageKey` = `"appTheme"`) ve dil (`AppLanguage.storageKey` = `"appLanguage"`). `TrendyolBenzeriApp` kökte `.preferredColorScheme` ve `.environment(\.locale, language.locale())` uygular; `SettingsView` aynı anahtarları yazar. "Sistem" dili cihazın birinci dilini takip eder; o dil `tr` ya da `en` değilse Türkçe.
- **`@Binding`**: seçili sekme `MainTabView`'a ait; `FavoritesView` ve `CartView`'a binding olarak verilir (boş durum butonları Ana Sayfa'ya geçirir).
- **Navigasyon**: her sekmenin kendi `NavigationStack`'i var. Geçişler `NavigationLink(value:)` ile, hedefler sekmenin kök view'unda `.navigationDestination(for: Product.self)` (Kategoriler'de ayrıca `ProductCategory.self`) ile tanımlı.

## Kod kuralları
- Tip, değişken, fonksiyon ve dosya adları İngilizce. Kod yorumları Türkçe.
- Arayüz metinleri (hata ve erişilebilirlik metinleri dahil) kodda Türkçe yazılır ve `Localizable.xcstrings`'te anahtar olur; her anahtarın `en` ve `tr` karşılığı vardır. Yeni metin eklenince catalog'a da eklenir.
  - Metin `Text("…")`, `Label("…", …)`, `Button("…")` gibi `LocalizedStringKey` alan API'lerle ya da `LocalizedStringResource` olarak taşınır. Arayüz metni `String` olarak üretilmez: `String` cihaz dilinde çözülür, seçilen dile uymaz.
  - `String` gerekiyorsa (sıralama, test) `resource.resolved(in: locale)` kullanılır. `String(localized:locale:)` metni yine cihaz dilinde arar.
  - `switch` içindeki interpolasyonlu `LocalizedStringResource`'u derleyici catalog için bulamıyor; o durumda her dalda doğrudan `Text("…")` döndürülür.
  - API'den gelen ürün adı, açıklama, marka ve yorumlar çevrilmez.
- Fiyatlar: API dolar verir. Para birimi dile bağlı (`AppLanguage.currency()`): Türkçede sabit kurla (`ExchangeRate.usdToTry` = 45) TL, İngilizcede API'deki dolar değeri. Kök view `.environment(\.currency, …)` verir; fiyat gösteren view `@Environment(\.currency)` okur ve her zaman `price(in:)` / `discountedPrice(in:)` / `lineTotal(in:)` / `totalPrice(in:)` ile `Text(value, format: currency.format)` kullanır (Türkçe `₺1.299,90`, İngilizce `$1,299.90`). Satır toplamı görünen birim fiyat × adet, sepet toplamı görünen satırların toplamı; iki para biriminde de kuruşa yuvarlanır. İndirim rozeti `Text(product.discountRate, format: .discount)` (`%10` / `10%`). Biçimler ekrandaki locale'i kullanır; elle biçimlendirme, sabit para birimi ve sabit locale yapılmaz. Dolar cinsinden `discountedPrice`, para birimine göre tutarların kaynağıdır. Dolar cinsinden `CartItem.lineTotal` ve `CartStore.totalPrice` uygulamada kullanılmıyor, yalnızca testlerde geçiyor (`REVIEW.md` S13); yeni kodda kullanılmaz.
- Önce var olan bileşen kullanılır:
  - `ProductGridView`: her ürün grid'i. Bulunduğu stack'te `Product` hedefi tanımlı olmalı.
  - `ProductCardView`, `PriceView`, `RatingView`, `StarRatingView`: kart, fiyat ve puan gösterimi.
  - `ProductImageView`: her ürün görseli (kart, sepet satırı, detay galerisi). Doğrudan `AsyncImage` kullanılmaz. Boyutu dışarıdan verilir (`.aspectRatio(1, contentMode: .fit)` ya da `.frame(width:height:)`); yükleniyor, başarılı ve hata durumlarında alan aynı kalır. İptal edilen istek (`NSURLErrorCancelled`) hata sayılmaz, yeniden denenir; başarısız görsel view tekrar ekrana gelince yeniden istenir.
  - `FavoriteButton`: favori kalbi; arayüzde favori ekleyip çıkarmanın tek yolu.
  - `LoadingView`, `ErrorView`, `ContentUnavailableView`: yükleniyor, hata ve boş durumlar.
- Önizlemeler `PreviewData` örneklerini ve `PlistStorage.preview`'u kullanır; gerçek favori ve sepet dosyalarına yazılmaz. Environment değerlerini ortak `.previewEnvironment(theme:language:)` modifier'ından alır (varsayılan `theme: .system`, `language: .turkish`; `Views/Common/PreviewEnvironment.swift`, `#if DEBUG` içine alınmaz). Bugünkü durum: yardımcı henüz yok.
- Testler Swift Testing ile yazılır. `TestHelpers.swift` içindeki `Product.sample(...)` ve `PlistStorage.temporary()` kullanılır; store testleri `@MainActor`.

## Git çalışma şekli
- Branch adları: `feature/<ad>`, `fix/<ad>`, `chore/<ad>`, yalnızca belge değişikliği için `docs/<ad>`.
- Stacked PR: yeni branch bir önceki özellik branch'inden açılır, PR'ın base'i o branch olur.
- Push ve PR açmayı agent'lar onay beklemeden yapar (`pr-manager`). Merge'leri proje sahibi GitHub'da elle yapar; agent'lar merge etmez. Hoca yalnızca yönlendirir.
- Proje sahibi için merge notu: stacked PR'lar en alttan başlayarak sırayla "Create a merge commit" ile merge edilir (squash zinciri bozar). Her merge'den önce bir üstteki PR'ın base'i `main`'e çevrilir; böylece alttaki branch silinince üstteki PR kapanmaz. Repo'da "Automatically delete head branches" açık.
- Commit mesajları İngilizce Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`). Her commit tek bir anlamlı adım ve kendi başına derlenir.
- Her özellik ayrı PR. PR açıklaması Türkçe: Özet, Değişiklikler, Nasıl test edilir, Mimari kontrol.
- Özellik bitince: `PLAN.md`'de ✅ işaretlenir, test adımları verilir ve sonraki özelliğe geçmeden onay beklenir.
- Çakışma ya da başarısız kontrol olursa iş durur ve raporlanır. Force push, `reset --hard`, rebase ve squash yasaktır.
- Remote: `https://github.com/Anjo899/Vitrin`. PR'lar `gh` ile açılır.

## Build ve test
```sh
# Derleme (uygulama)
xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' \
  -skipPackagePluginValidation build

# Derleme (uygulama + testler; commit öncesi lint kontrolü)
xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' \
  -skipPackagePluginValidation build-for-testing

# Unit testler (sonuç satırı: "✔ Test run with N tests …")
xcodebuild -project TrendyolBenzeri.xcodeproj -scheme TrendyolBenzeri \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' \
  -skipPackagePluginValidation test
```
- `-skipPackagePluginValidation`: komut satırında SwiftLint plugin'inin onay sormadan çalışması için gerekir. Xcode'da plugin bir kez "Trust & Enable" ile onaylanır.
- Geliştirme makinesine özel: Xcode 26.2 `/Applications/Xcode_26.2.app` içinde ve `xcode-select` onu gösteriyor; `DEVELOPER_DIR` gerekmez. Simülatör: iPhone 17, iOS 26.3.1. `gh`, `/opt/homebrew/bin` içinde.
- Paylaşılan `TrendyolBenzeri` scheme'inin test aksiyonu yalnızca `TrendyolBenzeriTests`'i çalıştırır:
  - Paralel test kapalı (`parallelizable = "NO"`). Kopya simülatörlerde test çalıştırma takılmıştı.
  - Şablon UI testleri (`TrendyolBenzeriUITests`) scheme'den çıkarıldı; dosyaları duruyor. Geri eklenmez.
- Xcode'da çalıştırmak için ⌘R, testler için ⌘U.

## Lint
- SwiftLint, `SwiftLintPlugins` paketinin build tool plugin'i ile her derlemede `TrendyolBenzeri` ve `TrendyolBenzeriTests` target'larında çalışır (sürüm `Package.resolved`'da sabit). Ayrı kurulum ve Run Script yok; script sandbox'ı açık.
- Ayarlar kökteki `.swiftlint.yml`'de. Özel kurallar `ARCHITECTURE.md` kurallarını uygular; her kuralın üstünde ilgili bölüm yazılı.
- Error yeni ihlali engeller ve derlemeyi kırar. Warning, `ARCHITECTURE.md`'de "Bugünkü durum: uyulmuyor" notlu bilinen ihlallere takılan kurallar içindir; ihlal düzeltilince kural error'a çekilir.
- Error varsa commit atılmaz (`committer`).

## Agents
Tanımlar projede, `.claude/agents/` içinde. Kullanıcı seviyesinde (`~/.claude/agents/`) aynı adla kopya tutulmaz. Agent tanımlarıyla çelişirse bu dosya geçerlidir.

### `committer`
Commit işlerini yapar; push yapmaz, PR açmaz.
- Branch `main` ise commit atmaz; durur ve uygun branch (`feature/<ad>`, `fix/<ad>`, `chore/<ad>`, `docs/<ad>`) açılması gerektiğini bildirir.
- Önce `git status --short` ve `git diff` ile değişiklikleri inceler. Görevle ilgisi olmayan değişiklikleri commit'e katmaz, raporda belirtir.
- Dosyaları adıyla ekler (`git add <yol>`). `git add -A`, `git add .` ve `git commit -a` kullanılmaz.
- Asla eklenmeyenler: `xcuserdata/`, `*.xcuserstate`, `.DS_Store`, `DerivedData/`, `build/`, `.swiftpm/` kullanıcı dosyaları, sırlar (`.env`, token, sertifika). `project.pbxproj` yalnızca görevle ilgili bir değişiklik varsa eklenir; emin olunmazsa eklenmez ve raporlanır.
- Swift dosyası ya da `.swiftlint.yml` değiştiyse commit'ten önce "Build ve test" bölümündeki `xcodebuild … build-for-testing` komutuyla derler; SwiftLint bu derlemede çalışır ("Lint"). Derleme başarısızsa ya da SwiftLint error verdiyse commit atmaz, hatayı bildirir.
- Commit mesajının sonuna boş bir satır ve `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` eklenir.
- `--amend`, rebase, `reset --hard`, `--no-verify` ve `--force` kullanılmaz.
- Rapor: her commit'in hash'i ve mesajı, commit dışında kalan değişiklikler, derleme sonucu.

### `pr-manager`
Push ve PR açma işlerini `gh` (`/opt/homebrew/bin/gh`) ile onay beklemeden yapar. Merge etmez (`gh pr merge` çalıştırmaz); merge'leri proje sahibi GitHub'da yapar. Commit atmaz. Commit'lenmemiş değişiklik varsa bildirir.
- Push: `git push -u origin <branch>`. `main`'e push yapılmaz.
- Mimari kontrol: PR açmadan ya da güncellemeden önce ana oturum `architect`'i çalıştırır ve raporu `pr-manager`'a verir (subagent başka subagent çalıştıramaz). Rapor yoksa ya da Kritik bulgu varsa PR açılmaz, durum raporlanır. Diğer bulgular ya da "Mimariye uygun" sonucu PR açıklamasına `## Mimari kontrol` başlığıyla eklenir.
- PR açma: base, branch'in açıldığı önceki özellik branch'idir (`git log` ve `gh pr list` ile belirlenir). Base belirlenemezse ya da zincirin ilk PR'ı olmadığı hâlde `main` çıkıyorsa durur ve raporlar. PR bu branch için zaten varsa `gh pr edit` ile güncellenir.
  - Başlık İngilizce Conventional Commits biçiminde.
  - Açıklama Türkçe; bölümler `## Özet`, `## Değişiklikler`, `## Nasıl test edilir`, `## Mimari kontrol`. Sonuna `🤖 Generated with [Claude Code](https://claude.com/claude-code)` satırı eklenir.
  - Komut: `gh pr create --base <base> --head <branch> --title … --body-file <dosya>`.
- Base PR'ı kapanmışsa ya da push reddedilirse durur ve raporlar. Force push, `reset --hard`, rebase ve squash yapılmaz.
- Rapor: push edilen branch, PR linki, mimari kontrol sonucu ve merge sırası (hangi PR'ın önce merge edilmesi gerektiği) ya da durma nedeni.

### `architect`
Değişiklikleri (`git diff main...HEAD`) ya da istenirse tüm projeyi `ARCHITECTURE.md` kurallarına göre denetler. Salt okunur: hiçbir dosyayı değiştirmez.
- Araçlar: Read, Grep, Glob ve yalnızca okuma amaçlı Bash (`git diff`, `git log`, `git status`, `git show`, `grep`, `ls`).
- "Bugünkü durum: uyulmuyor" notlu bilinen ihlalleri yeni bulgu gibi raporlamaz; yalnızca değişiklik bu ihlali büyütüyorsa ya da yenisini ekliyorsa raporlar.
- Kural belirsizse kendi yorumunu kural gibi sunmaz; "ARCHITECTURE.md bu konuda net değil" der.
- Her bulgu: ihlal edilen kural (`ARCHITECTURE.md` bölüm adıyla), `dosya:satır`, neden ihlal, nasıl düzeltilir, önem (Kritik / Önemli / Küçük). İhlal yoksa "Mimariye uygun".
