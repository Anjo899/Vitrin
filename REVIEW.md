# Vitrin – Kod İncelemesi

| Tur | Tarih | Kapsam |
| --- | --- | --- |
| 1 | 16.10.2026 | `main..chore/claude-md`: PR #1–#10'daki uygulama kodu ve testler |
| 2 | 21.10.2026 | Projenin tamamı, `401bb2d` (`fix/product-image-loading`) itibarıyla. Birinci turdan sonra eklenenler ayrıca incelendi: düzeltmeler (#12), tema (#13), dil ve para birimi (#14), görsel yükleme (#15) |

## Genel değerlendirme

Mimari hâlâ temiz ve tutarlı:
- View → ViewModel → `ProductService` → `APIClient` akışına her yerde uyuluyor. View'lar URL bilmiyor.
- Yeni özellikler mevcut kalıpları izliyor:
  - Tema ve dil, `@AppStorage` ile saklanıyor ve kökte bir kez uygulanıyor.
  - Para birimi tek bir environment değerinden geliyor.
  - Görseller tek bir bileşenden (`ProductImageView`) yükleniyor.
- Yerelleştirme eksiksiz:
  - Derleyicinin çıkardığı 90 anahtarın hepsi `Localizable.xcstrings`'te var ve her birinin `en` ve `tr` karşılığı mevcut.
  - Kodda catalog dışında kalan arayüz metni yok. Taramada kalan literal'ler yalnızca anahtar ve kod adları: `appLanguage`, `appTheme`, `en_US`, `tr_TR`, `TRY`, `USD`.
- Kod Swift 6 dil modunda da uyarısız derleniyor. Proje ise hâlâ Swift 5 modunda (S11).

Birinci turun 23 bulgusunun durumu:
- 7'si düzeltildi.
- 5'i kısmen düzeltildi.
- 11'i açık.

Bu turda 15 yeni bulgu var: 2 Önemli, 13 Küçük. Kritik bulgu yok. En önemli açık konular:
1. **O2:** Sepet ve favoriler ürünün eski kopyasını saklıyor.
2. **O11 (yeni):** Aşağı çekip yenileme başarısız olursa ekrandaki liste siliniyor. `CLAUDE.md` bunun tersini söylüyor.
3. **O4:** JSON çözümü ana thread'de yapılıyor.
4. **O9 ve O10:** VoiceOver ve Dynamic Type desteği eksik.

### Önem dereceleri
- **Kritik:** Uygulamayı dağıtmayı engelleyen ya da veriyi bozan sorun.
- **Önemli:** Kullanıcının fark edeceği hata ya da kalite sorunu.
- **Küçük:** İyileştirme.

### Doğrulama
Bu turda aşağıdakiler çalıştırılarak kontrol edildi:

| Kontrol | Sonuç |
| --- | --- |
| Unit testler (iPhone 17 Pro simülatörü, iOS 26.3) | ✔ 41 test, 10 suite |
| Release derlemesi | ✔ Başarılı |
| `SWIFT_STRICT_CONCURRENCY=complete` ile derleme | ✔ Uyarısız |
| `SWIFT_VERSION=6` ile derleme | ✔ Uyarısız |
| String Catalog taraması (derleyicinin çıkardığı anahtarlar ve koddaki literal'ler) | ✔ Eksik, fazla ya da çevrilmemiş anahtar yok |
| Derlenen uygulamada `tr.lproj` | ✔ Var |
| Simülatör | Görsel yükleme hatası (`NSURLErrorCancelled`, -999) önce yeniden üretildi, düzeltmeden sonra yeniden denendi. Ana sayfada "0%" rozeti görüldü (S1) |

- Strict concurrency ve Swift 6 derlemeleri yalnızca komut satırı ayarıyla yapıldı; proje ayarları değiştirilmedi.
- Kontrast oranları renk değerlerinden hesaplandı.
- VoiceOver ve Dynamic Type bulguları kod okumasına dayanıyor; simülatörde denenmedi.

## Önceki bulguların durumu

| # | Önem | Bulgu | Durum | Not |
| --- | --- | --- | --- | --- |
| K1 | Kritik | Release derlemesi başarısız | ✅ Düzeltildi | `83f4532`. Bu turda Release derlemesi yeniden alındı, başarılı |
| O1 | Önemli | Sepet toplamında kuruş farkı | ✅ Düzeltildi | `81b795c`, TL ve dolar için `27092ef`. Satır toplamı = görünen birim fiyat × adet; toplam = görünen satırların toplamı. Testli |
| O2 | Önemli | Sepet ve favoriler ürünün eski kopyasını saklıyor | ❌ Hâlâ açık | Ayrıntı aşağıda |
| O3 | Önemli | Plist çözülemezse veri kayboluyor | 🟡 Hâlâ açık (kısmen düzeltildi) | `.corrupt` yedeği var (`fbdf477`). Sürümlü kayıt tipi yok; ikinci bozulmada eski yedek siliniyor |
| O4 | Önemli | JSON çözümü ana thread'de | ❌ Hâlâ açık | Ayrıntı aşağıda |
| O5 | Önemli | Eski arama sonucu yenisinin üzerine yazılıyor | ✅ Düzeltildi | `57e680a`, testli. `ErrorView`'daki `Task {}` duruyor ama `latestQuery` kontrolü eski sonucu engelliyor |
| O6 | Önemli | Türkçe yerelleştirme yok | ✅ Düzeltildi | `40537db`: String Catalog ve `tr.lproj`. Türkçe cihazda sistem metinleri de Türkçe. Kalan sınırlar S16'da |
| O7 | Önemli | Stok ve indirim metinlerinde kontrast | ✅ Düzeltildi | `dfa4564`. Aynı türden yeni bir sorun: O12 |
| O8 | Önemli | Dokunma alanı 44 pt'den küçük | ✅ Düzeltildi | `74064b6` |
| O9 | Önemli | VoiceOver kartı bağlamsız okuyor | ❌ Hâlâ açık | Puan etiketleri var; kart, kalp, görsel ve adet sorunları duruyor |
| O10 | Önemli | Dynamic Type desteği eksik | ❌ Hâlâ açık | Sabit punto ve çerçeveler duruyor |
| T1 | Önemli | ViewModel, `APIClient` ve fiyat testleri eksik | 🟡 Hâlâ açık (kısmen düzeltildi) | Fiyat, para birimi ve arama testleri eklendi. Yükleme, yenileme ve iptal geçişleri ile `APIClient` hata eşlemesi test edilmiyor |
| S1 | Küçük | "%0" indirim rozeti | ❌ Hâlâ açık | Simülatörde Green Bell Pepper kartında "0%" görüldü |
| S2 | Küçük | Aramada `+` boşluk olarak gidiyor | ❌ Hâlâ açık | Kod değişmedi |
| S3 | Küçük | Hatalı veriye karşı koruma yok | ❌ Hâlâ açık | Kod değişmedi |
| S4 | Küçük | Gereksiz yeniden hesaplama | ❌ Hâlâ açık | `CartView` artık toplamı da her çizimde iki kez hesaplıyor |
| S5 | Küçük | Görsel önbelleği küçük, 194 ürün tek istekte | ❌ Hâlâ açık | Görsel yeniden deneme (#15) aynı görseli daha sık istiyor |
| S6 | Küçük | Tekrar eden kod | 🟡 Hâlâ açık (kısmen düzeltildi) | Görsel kodu `ProductImageView`'da birleşti (`01b213e`–`5678294`). ViewModel yükleme mantığı, fiyat ve rozet gösterimi, "n ürün" başlığı hâlâ tekrar ediyor |
| S7 | Küçük | İsimlendirme ve yerleşim | 🟡 Hâlâ açık (kısmen düzeltildi) | `discountLabel` kalktı (`97c1408`). `MainTabView.Tab`, kullanılmayan `fetchProduct(id:)`, boş `example()` testi ve `print` duruyor |
| S8 | Küçük | Önizlemeler aynı geçici klasörü kullanıyor | ❌ Hâlâ açık | Bazı önizlemeler kendi klasörünü oluşturuyor; ortak çözüm yok. Ayrıca bkz. S20 |
| S9 | Küçük | Yanıltıcı demo ödeme uyarısı | ❌ Hâlâ açık | Mesaj "ürünler korunacak" diyor, başlık hâlâ "Siparişin alındı (demo)" |
| S10 | Küçük | Karışık sayı biçimleri | ✅ Düzeltildi | `97c1408`: fiyat, indirim, puan ve tarih seçilen dile göre biçimleniyor |
| T2 | Küçük | Ek test ve kontroller | 🟡 Hâlâ açık (kısmen düzeltildi) | Eski arama ve bozuk plist testleri var. İndirim uç değerleri, yıldız eşikleri, tam API cevabı ve Release derlemesi kontrolü yok |

"Artık geçerli değil" durumuna düşen bulgu yok.

## Yeni bulgular (özet)

| # | Önem | Bulgu | Başlık |
| --- | --- | --- | --- |
| O11 | Önemli | Aşağı çekip yenileme hata verince liste siliniyor | Hata yönetimi |
| O12 | Önemli | "Sepete Eklendi" butonunda beyaz yazı yeşil zeminde okunmuyor (≈2,0–2,2:1) | Erişilebilirlik |
| S11 | Küçük | Proje Swift 5 dil modunda; kod Swift 6'ya hazır ama derleyici korumuyor | Concurrency |
| S12 | Küçük | `PriceFormatter.swift` adının ötesinde iş yapıyor; model dosyası SwiftUI'a bağlı | Mimari, isimlendirme |
| S13 | Küçük | Dolar cinsinden `lineTotal` ve `totalPrice` kullanılmıyor; `CLAUDE.md` tersini söylüyor | Kod tekrarı |
| S14 | Küçük | `\.currency` varsayılanı `\.locale` ile uyuşmuyor | State management |
| S15 | Küçük | "Sistem" dili bölgeyi kaybediyor (en-GB → en_US) | Yerelleştirme |
| S16 | Küçük | Seçilen dilin ulaşmadığı yerler: hata açıklaması, sıralama, sistem metinleri, VoiceOver | Yerelleştirme |
| S17 | Küçük | `ProductImageView`: sınırsız yeniden deneme, ayrı iptal kontrolü, testi yok | Hata yönetimi, performans |
| S18 | Küçük | Her sepet ve favori değişikliğinde tüm dosya ana thread'de yazılıyor | Performans |
| S19 | Küçük | `@AppStorage` tanımı iki yerde; `CategoryProductsView` her init'te ViewModel oluşturuyor | State management |
| S20 | Küçük | Bazı önizlemeler `CartStore` vermiyor; detaya geçince çöküyor | Kod kalitesi |
| S21 | Küçük | `PLAN.md` ve `CLAUDE.md` koddan ve yeni kurallardan geri kaldı | Belgeler |
| S22 | Küçük | `ErrorView` "Tekrar Dene" görevi yapılandırılmamış ve iptal edilmiyor | Concurrency |
| T3 | Küçük | Yeni kodun test edilmeyen kısımları | Test kapsamı |

## Bulgular

Her başlıkta önce açık kalan eski bulgular, sonra yeni bulgular var. Dosya yolları `TrendyolBenzeri/` altına göre; satır numaraları `401bb2d`'ye göre.

### Mimari ve katman ihlalleri

Katman sınırlarında bir ihlal yok:
- View'lar URL bilmiyor.
- ViewModel'ler yalnızca `ProductService`'i kullanıyor.
- Store'lar yalnızca `PlistStorage`'ı kullanıyor.

Tek pürüz, model hesaplarının SwiftUI içeren bir yardımcı dosyada durması.

#### S12 · Küçük · `PriceFormatter.swift` birden fazla iş yapıyor
- **Dosya:** `Utilities/PriceFormatter.swift:6–69`
- **Sorun:** Dosyanın adı biçimlendirici, ama içinde altı ayrı şey var:
  - `ExchangeRate` ve `Currency` modeli,
  - SwiftUI `EnvironmentValues` anahtarı (`@Entry var currency`),
  - `Double.roundedToCents`,
  - indirim biçimi,
  - `Product`'ın fiyat hesapları.

  Environment anahtarı yüzünden dosya `import SwiftUI` yapıyor. Böylece model hesapları (`Product.price(in:)`, `Product.discountedPrice` içindeki yuvarlama) SwiftUI'a bağlı bir dosyada duruyor. `Models/Product.swift:31–33` de bu dosyadaki `roundedToCents`'e bağlı.
- **Neden önemli:** Fiyat kuralı aranırken "biçimlendirici"ye bakılmaz. Ayrıca `Models` ve `Networking` SwiftUI'sız kalmalı; ileride bir widget ya da test hedefi model katmanını SwiftUI olmadan kullanamaz.
- **Öneri:** Dosyayı üçe böl:
  - `Models/Currency.swift`: `Currency` ve `ExchangeRate`, yalnızca Foundation.
  - `Models/Product+Price.swift`: fiyat hesapları ve `roundedToCents`.
  - `Views/Common/EnvironmentValues+Currency.swift`: `@Entry`.

  Biçimler (`currency.format`, `.discount`) Foundation'da kalabilir.

### State management

`@State`, `@Binding`, `@Observable` ve `.environment` kullanımı doğru:
- ViewModel'ler ekrana ait `@State`.
- Store'lar kökte bir kez oluşturulup environment'tan okunuyor.
- Seçili sekme `@Binding` ile aşağı veriliyor.
- Tema ve dil `@AppStorage` ile kalıcı; kök ve Ayarlar aynı anahtarı okuyor.

#### O2 · Önemli · Sepet ve favorilerde ürünün eski kopyası saklanıyor (birinci turdan, açık)
- **Dosya:** `Stores/CartStore.swift:62–71`, `Stores/FavoritesStore.swift:43–50`, `Networking/ProductService.swift:46–48`
- **Sorun:**
  - `add` ürün zaten sepetteyse yalnızca adedi artırıyor; satırdaki `product` eklendiği günkü haliyle kalıyor. Favoriler de aynı.
  - Plist'e `Product`'ın tamamı (yorumlarıyla) yazılıyor ve bir daha tazelenmiyor.
  - Fiyat ya da stok değişirse sepet eski fiyattan topluyor ve eski stokla `+` butonunu açık tutuyor. Favorilerden açılan detay da eski bilgiyi gösteriyor.
- **Neden önemli:** Kullanıcı, ana sayfada gördüğü fiyattan farklı bir sepet toplamı görebilir; stokta olmayan adet sepette kalabilir. Sorun, uygulama ne kadar uzun kullanılırsa o kadar büyür.
- **Öneri:**
  - `add` içinde satırın `product`'ını gelen yeni ürünle değiştir.
  - Sepet ekranı açılırken ürünleri id ile tazele (`fetchProduct(id:)` hazır).
  - Sepetteki adet yeni stoktan fazlaysa adedi stoğa indir.
  - Uzun vadede O3'teki sürümlü kayıt tipine geç.

#### S4 · Küçük · Gereksiz yeniden hesaplama (birinci turdan, açık)
- **Dosya:** `Stores/CartStore.swift:30–32`, `Stores/FavoritesStore.swift:31–33`, `Views/Cart/CartView.swift:42,52,66,69`, `Views/MainTabView.swift:43`
- **Sorun:**
  - `sortedItems` her erişimde sıralanıyor; `CartView` bunu her çizimde iki kez çağırıyor (`ForEach` ve `.animation`).
  - Yeni olarak `totalPrice(in:)` de iki kez hesaplanıyor (metin ve `.animation`).
  - `@Observable` sözlük düzeyinde izlendiği için tek bir değişiklik `MainTabView`'ı ve ekrandaki bütün `FavoriteButton`'ları yeniden hesaplatıyor.
- **Neden önemli:** Bu ölçekte fark edilmez, ama sepet ve favoriler büyüdükçe her dokunuşta yapılan iş artar.
- **Öneri:** `CartView`'da sıralı listeyi ve toplamı `body` içinde birer yerel `let`'e al. Sıralı listeyi store'da değişiklik anında hesaplayıp sakla.

#### S14 · Küçük · `\.currency` varsayılanı `\.locale` ile uyuşmuyor
- **Dosya:** `Utilities/PriceFormatter.swift:35–38`, `TrendyolBenzeriApp.swift:28–30`
- **Sorun:** Para birimi ve locale, kökte aynı dilden iki ayrı environment değeri olarak veriliyor. Kökün dışında, örneğin önizlemelerde ya da ileride kökü atlayan bir pencerede:
  - `\.locale` cihaz dilini alıyor,
  - `\.currency` ise sabit `.lira` kalıyor.

  İngilizce bir Mac'teki önizlemede fiyatlar "TRY 402.30" gibi, iki dilin karışımı görünüyor.
- **Neden önemli:** İki değerin her zaman birlikte ayarlanması gerekiyor ve bunu hiçbir şey zorlamıyor. Tek bir kaynak olunca tutarsızlık imkânsız olur.
- **Öneri:** Para birimini locale'den türet; ayrı bir environment anahtarına gerek kalmaz:
  - `Currency(locale:)`: dil `en` ise dolar, değilse TL.
  - `@Environment(\.locale)` okuyan küçük bir yardımcı.

  Ya da `@Entry` varsayılanını `AppLanguage.system.currency()` yap.

#### S19 · Küçük · `@AppStorage` tanımı iki yerde; ViewModel her init'te oluşuyor
- **Dosya:** `TrendyolBenzeriApp.swift:16,18`, `Views/Settings/SettingsView.swift:11–12`, `Views/Categories/CategoryProductsView.swift:13–15`
- **Sorun:**
  - Tema ve dilin `@AppStorage` tanımı varsayılan değeriyle (`.system`) birlikte iki dosyada tekrar ediyor. Biri değişip diğeri unutulursa, Ayarlar başka, kök başka bir varsayılan gösterir.
  - `CategoryProductsView.init` her çağrıldığında yeni bir `CategoryProductsViewModel` oluşturuyor. `State(initialValue:)` yalnızca ilkini saklıyor; diğerleri boşuna oluşturulup atılıyor. Üst view her yeniden çizildiğinde bu tekrar ediyor.
- **Neden önemli:** İlki sessiz bir tutarsızlık riski. İkincisi bugün ucuz, ama ViewModel init'ine iş eklenirse (ör. istek başlatmak) gizli bir hataya dönüşür.
- **Öneri:**
  - `AppTheme.default` ve `AppLanguage.default` tanımla, iki yerde de onu kullan.
  - ViewModel'i init'te değil `.task` içinde oluştur ya da init'i bilinçli olarak hafif tut. `CLAUDE.md`'deki `_viewModel = State(initialValue:)` kalıbına bu notu ekle.

### Concurrency ve MainActor

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ayarı doğru kullanılıyor:
- View, ViewModel ve store'lar MainActor'da.
- Modeller, ağ katmanı ve `PlistStorage` `nonisolated` + `Sendable`.
- Arama iptali ve eski sonuç kontrolü (O5) doğru.

#### O4 · Önemli · JSON çözümü ana thread'de yapılıyor (birinci turdan, açık)
- **Dosya:** `Networking/APIClient.swift:20,50,57–73`, `Views/Home/HomeViewModel.swift:76`
- **Sorun:**
  - `SWIFT_APPROACHABLE_CONCURRENCY` açık olduğu için `nonisolated async func get`, çağıranın actor'ünde, yani MainActor'da çalışıyor. Ana sayfa `limit=0` ile 194 ürünü yorumlarıyla tek istekte çekiyor ve yaklaşık 300 KB'lık JSON ana thread'de çözülüyor.
  - `JSONDecoder.dummyJSON` hesaplanan bir özellik; her istekte yeni bir decoder oluşturuyor.
  - Her yorum tarihi için bir, gerekirse iki yeni `ISO8601FormatStyle` oluşturuluyor.
- **Neden önemli:** Açılışta ve aşağı çekip yenilemede ana thread bloke oluyor. Eski cihazlarda takılma olarak hissedilir.
- **Öneri:**
  - `get`'i `@concurrent` yap.
  - Decoder'ı ve iki tarih biçimini `static let` olarak bir kez oluştur.

#### S11 · Küçük · Proje Swift 5 dil modunda
- **Dosya:** `TrendyolBenzeri.xcodeproj/project.pbxproj:418,450` (uygulama), `:470,491` (testler)
- **Sorun:** `SWIFT_VERSION = 5.0` ve `SWIFT_STRICT_CONCURRENCY` ayarlanmamış. Bu modda veri yarışı denetimi en düşük seviyede. Bu turda iki deneme yapıldı:
  - `SWIFT_STRICT_CONCURRENCY=complete` ile derleme: uyarısız.
  - `SWIFT_VERSION=6` ile derleme: uyarısız.

  Yani kod bugün Swift 6'ya hazır, ama bunu koruyan bir ayar yok.
- **Neden önemli:** Proje zaten Swift 6'nın varsayılanlarına dayanıyor (MainActor varsayılanı, `nonisolated` modeller). Bir sonraki değişiklik `Sendable` olmayan bir değeri actor sınırından geçirirse derleyici bunu sessizce kabul eder.
- **Öneri:** Uygulama ve test hedeflerinde `SWIFT_VERSION = 6` yap. Bu tek satırlık bir ayar değişikliği; Xcode'un Build Settings ekranından yapılmalı, `project.pbxproj` elle düzenlenmez.

#### S22 · Küçük · "Tekrar Dene" görevi iptal edilmiyor
- **Dosya:** `Views/Common/ErrorView.swift:20–22`
- **Sorun:** Buton `Task { await retry() }` ile yapılandırılmamış bir görev başlatıyor:
  - Ekran kapansa da görev iptal edilmiyor.
  - Art arda basılırsa aynı anda birden fazla `load()` çalışıyor.

  Arama tarafında `latestQuery` kontrolü yanlış sonucu engelliyor (O5). Ana sayfa ve kategori yüklemelerinde ise bu koruma yok.
- **Neden önemli:** Bugün sonuç aynı veriyle iki kez yazılmak; zararsız. Ama yükleme bir yan etki kazanırsa (ör. sayfalama) çift istek veri tekrarına yol açar.
- **Öneri:** Butonu yükleme sürerken devre dışı bırak. Ya da tekrar denemeyi `.task(id: retryCount)` ile view'un yaşam döngüsüne bağla.

### Hata yönetimi

#### O11 · Önemli · Aşağı çekip yenileme hata verince liste siliniyor
- **Dosya:** `Views/Home/HomeViewModel.swift:38–40,73–86`, `Views/Categories/CategoriesViewModel.swift:29–31,33–44`, `Views/Categories/CategoryProductsViewModel.swift:32–34,36–46`
- **Sorun:** `refresh()`, `load()` ile aynı `fetch…` fonksiyonunu çağırıyor; hata olursa `state = .failed(...)` yazılıyor. İnternet yokken aşağı çekilince:
  - ekrandaki 194 ürünlük liste kayboluyor,
  - yerine tam ekran hata görünümü geliyor.

  `CLAUDE.md:28` ise "`refresh()` (`.refreshable`, eski liste ekranda kalır)" diyor; bu yalnızca başarılı yenilemede doğru.
- **Neden önemli:** Kullanıcı az önce baktığı ürünleri, yalnızca listeyi yenilemek istediği için kaybediyor. Tekrar görmek için bağlantının gelmesini beklemesi gerekiyor. Belge ile kod da birbirini tutmuyor.
- **Öneri:**
  - Yenileme hatasında `state`'e dokunma; eski liste kalsın.
  - Hatayı ayrı bir `refreshError: LocalizedStringResource?` olarak tut ve kısa süreli bir uyarı ya da banner ile göster.
  - Bu davranışı üç ViewModel'de ortak bir yükleyiciye taşı (S6).
  - Bir testle koru (T3).

#### O3 · Önemli · Plist çözülemezse veri kayboluyor (birinci turdan, kısmen düzeltildi)
- **Dosya:** `Persistence/PlistStorage.swift:37–48`, `Stores/CartStore.swift:18–27`, `Stores/FavoritesStore.swift:19–28`
- **Sorun:**
  - **Düzeltilen kısım:** Çözülemeyen dosya artık `.corrupt` olarak kenara alınıyor.
  - **Kalan 1:** Plist'te hâlâ `Product`'ın tamamı saklanıyor. Modele zorunlu tek bir alan eklemek, bütün kullanıcıların sepetini ve favorilerini `.corrupt`'a taşır ve uygulama boş açılır.
  - **Kalan 2:** İkinci bir bozulmada `moveAsideCorruptFile` önceki `.corrupt` yedeğini siliyor (`:41–43`).
- **Neden önemli:** Yedek dosyayı uygulama hiçbir zaman geri okumuyor. Kullanıcı açısından sonuç, verinin kaybolması.
- **Öneri:**
  - Kalıcı veri için sürümlü ve küçük bir tip kullan: `struct StoredCart: Codable { var version = 1; var items: [Int: Int] }`, yani yalnızca id ve adet. Ürün bilgisini açılışta API'den tazele (O2 ile birlikte).
  - Yedeğe zaman damgası ekle.

#### S17 · Küçük · `ProductImageView`'da sınırsız yeniden deneme
- **Dosya:** `Views/Components/ProductImageView.swift:43–47,59–66,74–78`
- **Sorun:**
  - İptal dışındaki hatalarda (ör. bağlantı yok, 404) görsel, view ekrana her döndüğünde yeniden isteniyor. Bir sınır ya da bekleme süresi yok; bağlantı yokken grid'de her kaydırma yeni istekler başlatıyor.
  - İptalin hata sayılıp sayılmayacağı kararı, `APIClient.swift:35–37`'deki karardan ayrı bir `private extension Error` ile verilmiş.
  - Yeniden deneme kuralı view'un içinde olduğu için test edilemiyor.
- **Neden önemli:**
  - 404 veren bir görsel her görünmede boşuna istek atar.
  - İki ayrı iptal kontrolü zamanla birbirinden farklılaşabilir.
  - #15'teki düzeltmeyi koruyan bir test yok.
- **Öneri:**
  - Kuralı küçük bir değer tipine çıkar (ör. `ImageRetryPolicy`) ve test et. Bu tip ekranda kalırken en fazla 2 iptal denemesi ve kalıcı hatalarda artan bir bekleme uygulasın.
  - `isCancellation`'ı `Networking/` altında ortak bir extension yap; `APIClient` da onu kullansın.

### Performans

#### S5 · Küçük · Görsel önbelleği küçük; 194 ürün tek istekte (birinci turdan, açık)
- **Dosya:** `Views/Home/HomeViewModel.swift:75–76`, `Views/Components/ProductImageView.swift:26`
- **Sorun:**
  - `AsyncImage` varsayılan `URLCache`'i kullanıyor ve önbellek kapasitesi ayarlanmamış.
  - Ana sayfa bütün ürünleri ve yorumlarını `limit=0` ile tek istekte çekiyor.
  - #15'ten sonra iptal edilen görseller yeniden istendiği için önbellek daha da önemli.
- **Neden önemli:** Geri kaydırınca görseller yeniden iniyor ve yer tutucular yanıp sönüyor. Hücresel veride gereksiz trafik oluşuyor.
- **Öneri:**
  - Açılışta `URLCache.shared`'in bellek ve disk kapasitesini büyüt (ör. 50 MB / 200 MB).
  - Liste için `limit` ve `skip` ile sayfalı yüklemeye geç; yorumları detay ekranında `fetchProduct(id:)` ile al.

#### S18 · Küçük · Her değişiklikte tüm dosya ana thread'de yazılıyor
- **Dosya:** `Stores/CartStore.swift:90–96`, `Stores/FavoritesStore.swift:52–58`, `Persistence/PlistStorage.swift:18–23`
- **Sorun:** Sepette her `+`/`−` dokunuşu ve her kalp, bütün sözlüğü XML plist olarak kodlayıp diske atomik olarak yazıyor. Bu iş MainActor'da yapılıyor ve sözlükte her ürünün tamamı, yorumlarıyla birlikte var.
- **Neden önemli:** Bugün küçük, ama O3'teki şema riskiyle aynı kökten geliyor. Veri büyüdükçe dokunuş başına ana thread maliyeti artıyor.
- **Öneri:**
  - O3'teki küçük kayıt tipine geç (yalnızca id ve adet).
  - İstersen `.binary` plist biçimi kullan.
  - Art arda değişiklikleri kısa bir gecikmeyle tek bir yazmada birleştir.

### Erişilebilirlik

#### O9 · Önemli · VoiceOver ürün kartını bağlamsız okuyor (birinci turdan, açık)
- **Dosya:** `Views/Components/ProductGridView.swift:22–31`, `Views/Components/ProductCardView.swift:14–43`, `Views/Components/FavoriteButton.swift:33`, `Views/Components/ProductImageView.swift:28–31`, `Views/Cart/CartItemRow.swift:67–70`
- **Sorun:**
  - **Düzeltilen kısım:** Puan (`RatingView`, `StarRatingView`) ve hata yer tutucusu için etiketler var.
  - **Duranlar:**
    - Kart tek bir öğe değil.
    - Üstü çizili eski fiyat "eski fiyat" bağlamı olmadan okunuyor.
    - Kalp butonu her kartta yalnızca "Favorilere ekle" diyor.
    - Başarılı görselin etiketi yok.
    - Sepetteki adet yalnızca "2" diye okunuyor.
- **Neden önemli:** VoiceOver kullanıcısı hangi ürünü favorilediğini ya da hangi fiyatın geçerli olduğunu anlayamıyor.
- **Öneri:**
  - Kartı `.accessibilityElement(children: .combine)` yap ve marka, ad, puan, indirim, eski ve yeni fiyatı içeren bir etiket ver.
  - Kalp etiketine ürün adını ekle ("Essence Mascara'yı favorilere ekle").
  - Görseli `.accessibilityHidden(true)` yap.
  - Adet kontrolünü `accessibilityAdjustableAction` ile ayarlanabilir tek bir öğe yap.

#### O10 · Önemli · Dynamic Type desteği eksik (birinci turdan, açık)
- **Dosya:** `Views/Components/FavoriteButton.swift:22–28`, `Views/Components/StarRatingView.swift:11,17`, `Views/Cart/CartItemRow.swift:53,63,76`, `Views/ProductDetail/ProductImageGallery.swift:26`, `Views/Cart/CartView.swift:60–88`, `Views/ProductDetail/AddToCartBar.swift:22–50`
- **Sorun:**
  - `.font(.system(size:))`, `size:` parametreleri ve sabit `frame` değerleri yazı boyutuyla büyümüyor.
  - Alt çubuklarda fiyat ve buton yan yana duruyor.
- **Neden önemli:** Büyük yazı boyutu kullanan kullanıcılar için ikonlar küçük kalıyor; alt çubuklarda metin kesilebiliyor.
- **Öneri:**
  - Boyutları `@ScaledMetric` ile tanımla.
  - Alt çubuklarda `ViewThatFits` ile büyük boyutta dikey yerleşime geç.
  - Simülatörde Accessibility Inspector ile en büyük boyutta dene.

#### O12 · Önemli · "Sepete Eklendi" butonunda kontrast yetersiz
- **Dosya:** `Views/ProductDetail/AddToCartBar.swift:48`
- **Sorun:** Ekleme sonrası buton 1,5 sn boyunca `.tint(.green)` ile yeşile dönüyor ve yazısı beyaz. Sistem yeşili açık temada `#34C759`, koyu temada `#30D158`; beyaz yazıyla kontrast ≈ 2,0–2,2:1. Büyük metin için bile WCAG AA en az 3:1 istiyor. Birinci turda O7 ile Assets'e erişilebilir renkler eklenmişti; bu yer onların dışında kaldı.
- **Neden önemli:** Geri bildirim metni ("Sepete Eklendi") az gören kullanıcılar için okunmuyor. Süre kısa olsa da bu, işlemin başarılı olduğunu söyleyen tek metin.
- **Öneri:** Assets'e açık ve koyu temada en az 4,5:1 veren bir `SuccessFill` rengi ekle (`StockAvailable`'a benzer koyu bir yeşil) ve onu kullan. Başarıyı yalnızca renkle değil, zaten var olan ✓ ikonuyla da anlat.

### Yerelleştirme

Koda gömülü metin kalmadı (Doğrulama'ya bakın). Kalan sorunlar seçilen dilin kapsamıyla ilgili.

#### S15 · Küçük · "Sistem" dili bölgeyi kaybediyor
- **Dosya:** `Models/AppLanguage.swift:37–42`
- **Sorun:** Çözülen dil `en` ise locale her zaman `en_US`, `tr` ise `tr_TR`. "Sistem" seçili ve cihaz `en-GB` ise:
  - tarihler "April 30, 2025" (ABD) biçiminde gösteriliyor,
  - İngiliz kullanıcının beklediği "30 April 2025" görünmüyor.
- **Neden önemli:** "Sistem" seçeneği, cihaz ayarını takip edeceğini vaat ediyor; ama bölge ayarını kaybediyor.
- **Öneri:** "Sistem" seçiliyken ve cihazın birinci dili desteklenen bir dilse `Locale.autoupdatingCurrent`'i kullan; yalnızca desteklenmeyen dilde `tr_TR`'ye düş. Açık seçimlerde (`turkish` / `english`) bugünkü sabit locale'ler kalabilir.

#### S16 · Küçük · Seçilen dilin ulaşmadığı yerler
- **Dosya:** `Networking/APIError.swift:28–30`, `Stores/CartStore.swift:31`, `Stores/FavoritesStore.swift:32`, `TrendyolBenzeriApp.swift:28`
- **Sorun:** Dil kökte yalnızca `.environment(\.locale, …)` ile uygulanıyor. Bunun ulaşmadığı yerler:
  - `APIError.errorDescription` `String(localized:)` ile cihaz dilinde çözülüyor. Arayüz `userMessage`'ı kullandığı için bugün görünmüyor, ama `error.localizedDescription` kullanan ilk kod yanlış dilde metin gösterir.
  - Sepet ve favoriler `localizedStandardCompare` ile cihazın locale'ine göre sıralanıyor. Kategoriler ise seçilen dile göre sıralanıyor.
  - Bilinen sınırlar (`PLAN.md`'de yazılı): sistem metinleri (geri, "Cancel"), açık bir alert ve VoiceOver'ın okuma dili cihaz dilinde kalıyor.
- **Neden önemli:** Kullanıcı İngilizce seçtiğinde ekranın bir kısmı Türkçe kalabilir; VoiceOver İngilizce metni Türkçe telaffuzla okur.
- **Öneri:**
  - `errorDescription`'ı kaldır ya da `LocalizedError` uyumunu bırak; arayüz yalnızca `message` kullansın.
  - Sıralamayı `CategoriesView`'daki gibi view'da `\.locale` ile yap.
  - Ayarlar'daki dil açıklamasına, sistem metinlerinin ve VoiceOver'ın cihaz dilini izlediğini ekle.

### Hatalar ve uç durumlar

#### S1 · Küçük · "%0" indirim rozeti (birinci turdan, açık)
- **Dosya:** `Models/Product.swift:25–27`, `Utilities/PriceFormatter.swift:65–68`
- **Sorun:** `hasDiscount` indirim 0'dan büyükse `true` döndürüyor, ama `discountRate` tam yüzdeye yuvarlanıyor. %0,5'in altındaki indirimlerde rozet "%0" ("0%") gösteriyor; simülatörde Green Bell Pepper kartında görüldü.
- **Neden önemli:** "%0 indirim" yazan bir rozet ve neredeyse aynı üstü çizili fiyat, hatalı bir uygulama izlenimi veriyor.
- **Öneri:** `hasDiscount`'u `discountRate > 0` (ya da fiyat farkı ≥ 1 kuruş) olarak tanımla. Rozet, üstü çizili fiyat ve indirimli fiyat rengi hep aynı kararı kullansın.

#### S2 · Küçük · Aramada `+` boşluk olarak gidiyor (birinci turdan, açık)
- **Dosya:** `Networking/APIClient.swift:24–26`, `Networking/ProductService.swift:29–35`
- **Sorun:** `URLComponents.queryItems`, `+` karakterini kodlamıyor; sunucu onu boşluk olarak okuyor. "a+b" araması "a b" gibi davranıyor.
- **Neden önemli:** Ürün adında `+` geçen aramalar (ör. "Galaxy S10+") yanlış sonuç döndürür.
- **Öneri:** `components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")`.

#### S3 · Küçük · Hatalı veriye karşı koruma yok (birinci turdan, açık)
- **Dosya:** `Views/ProductDetail/ProductDetailView.swift:109–125`, `Models/Product.swift:31–37`
- **Sorun:**
  - Stok negatif gelirse `default` dalı yeşil "Stokta -1 adet" yazar.
  - İndirim %100'ün üzerindeyse fiyat negatif olur ve TL'ye çevrilip sepete eklenebilir.
- **Neden önemli:** API'nin hatalı verisi doğrudan kullanıcıya ve sepet toplamına yansır.
- **Öneri:**
  - Stok anahtarını `case ...0` ile yaz.
  - `discountPercentage`'ı model katmanında 0–100 arasına sınırla.

#### S9 · Küçük · Yanıltıcı demo ödeme uyarısı (birinci turdan, açık)
- **Dosya:** `Views/Cart/CartView.swift:20–24`
- **Sorun:** Başlık "Siparişin alındı (demo)"; mesaj ise ödeme adımının olmadığını ve ürünlerin sepette kalacağını söylüyor.
- **Neden önemli:** Başlık ile mesaj birbiriyle çelişiyor; kullanıcı sipariş verdiğini sanabilir.
- **Öneri:** Başlığı "Ödeme adımı yakında" gibi bir metinle değiştir ve catalog'u güncelle.

### Kod tekrarı ve isimlendirme

#### S6 · Küçük · Tekrar eden kod (birinci turdan, kısmen düzeltildi)
- **Dosya:**
  - ViewModel'ler: `Views/Home/HomeViewModel.swift:26–40,73–86`, `Views/Categories/CategoriesViewModel.swift:19–44`, `Views/Categories/CategoryProductsViewModel.swift:22–46`
  - İndirim rozeti: `Views/Components/ProductCardView.swift:50–59`, `Views/ProductDetail/ProductDetailView.swift:73–90`
  - Fiyat gösterimi: `Views/Cart/CartItemRow.swift:29–37`
  - Önizleme klasörleri: `Views/Cart/CartView.swift:92,106`, `Views/Favorites/FavoritesView.swift:70`
  - "n ürün" başlığı: `Views/Favorites/FavoritesView.swift:41–45`, `Views/Categories/CategoryProductsView.swift:38–42`
- **Sorun:**
  - **Düzeltilen kısım:** Görsel kodu `ProductImageView`'da birleşti.
  - **Duranlar:**
    - Üç ViewModel'de `loadIfNeeded` / `load` / `refresh` / iptal mantığı satır satır aynı. O11'in üç yerde ayrı ayrı düzeltilmesi gerekmesinin sebebi bu.
    - İndirim rozeti iki yerde, üstü çizili fiyat + indirimli fiyat üç yerde ayrı yazılmış.
    - "n ürün" başlığı iki yerde.
- **Neden önemli:** Bir kural değiştiğinde (ör. S1'in rozet kararı, O11'in yenileme davranışı) her kopyanın ayrı ayrı düzeltilmesi gerekiyor.
- **Öneri:**
  - Genel bir `Loader<Value>` ya da `LoadState`'i yöneten küçük bir yardımcı çıkar.
  - `DiscountBadge` ve `PriceView(style:)` bileşenlerini oluştur.
  - "n ürün" için küçük bir `ResultCountHeader` yaz.

#### S7 · Küçük · İsimlendirme ve yerleşim (birinci turdan, kısmen düzeltildi)
- **Dosya:** `Views/MainTabView.swift:11–13`, `Networking/ProductService.swift:46–48`, `TrendyolBenzeriTests/TrendyolBenzeriTests.swift:13–17`, `Stores/CartStore.swift:24,94`, `Stores/FavoritesStore.swift:25,56`, `Persistence/PlistStorage.swift:46`
- **Sorun:**
  - **Düzeltilen kısım:** `discountLabel` kalktı.
  - **Duranlar:**
    - `MainTabView.Tab`, SwiftUI'ın iOS 18'deki `Tab` tipiyle aynı adı taşıyor.
    - `fetchProduct(id:)` kullanılmıyor.
    - Şablondan kalan boş `example()` testi duruyor (41 testin biri o).
    - Hatalar 5 yerde `print` ile yazılıyor.
- **Neden önemli:** `Tab`, iOS 18'e geçildiğinde ad çakışmasıyla kafa karıştırır. `print` Release'te de çalışır ama Console'da filtrelenemez. Boş test, test sayısını yanıltıcı gösteriyor.
- **Öneri:**
  - `AppTab` adını ver.
  - Boş testi sil.
  - `Logger(subsystem:category:)` kullan.
  - `fetchProduct(id:)`'yi O2 ile kullan ya da kaldır.

#### S13 · Küçük · Kullanılmayan dolar toplamları
- **Dosya:** `Models/CartItem.swift:15–18`, `Stores/CartStore.swift:43–45`, `CLAUDE.md:43`
- **Sorun:**
  - `CartItem.lineTotal` ve `CartStore.totalPrice` (dolar) uygulama kodunda hiçbir yerde kullanılmıyor; yalnızca birbirinde ve testlerde geçiyor. Stok ve sepet mantığı adet ile `product.stock`'u kullanıyor.
  - `CLAUDE.md:43` ise "Dolar hesapları (`discountedPrice`, `lineTotal`, `totalPrice`) stok ve sepet mantığı için kalır" diyor. Bu yalnızca `discountedPrice` için doğru.
  - `totalPrice` ile `totalPrice(in:)` aynı adı taşıdığı için, yanlış olanın seçilmesi kolay.
- **Neden önemli:** Ölü kod ve yanlış belge, sonraki değişikliklerde yanlış toplamın kullanılmasına yol açabilir.
- **Öneri:**
  - İkisini kaldır; testler `lineTotal(in: .dollar)` ve `totalPrice(in: .dollar)` kullansın.
  - `CLAUDE.md:43`'ü düzelt.

### Belgeler

#### S21 · Küçük · `PLAN.md` ve `CLAUDE.md` koddan ve yeni kurallardan geri kaldı
- **Dosya:** `PLAN.md:12,40,55,56,100`, `PLAN.md` adımlar tablosu (satır 17–30), `CLAUDE.md:28,43`
- **Sorun:**
  - **`PLAN.md`:**
    - Satır 12 ve 100: "main'e merge yok (hoca merge edecek). Push öncesi her zaman sorulur." `CLAUDE.md`'deki güncel kural ise push, PR ve merge'ün onay beklemeden yapılması.
    - Satır 40: "en_US". Satır 55: "sadece DEBUG". Satır 56: "`failed(String)`". Üçü de artık doğru değil.
    - Görsel yükleme düzeltmesi (#15) adımlar tablosunda yok.
  - **`CLAUDE.md`:** Satır 28 (O11) ve satır 43 (S13) kodla çelişiyor.
- **Neden önemli:** İki dosya da kalıcı bağlam olarak okunuyor; çelişen kurallar yanlış bir push, PR ya da merge kararına yol açabilir.
- **Öneri:**
  - `PLAN.md`'nin "Genel kurallar" ve "Her branch için iş akışı" bölümlerini `CLAUDE.md`'ye yönlendir ya da güncelle.
  - Eski adım açıklamalarına "o günkü hali" notu düş.
  - #15'i tabloya ekle.

### Kod kalitesi: önizlemeler

#### S8 · Küçük · Önizlemeler aynı geçici klasörü kullanıyor (birinci turdan, açık)
- **Dosya:** `Utilities/PreviewData.swift:44–48`, `Views/Favorites/FavoritesView.swift:55–58`
- **Sorun:** `PlistStorage.preview` her seferinde aynı geçici klasörü veriyor. Bu yüzden önizlemeler arasında veri birikiyor. `FavoritesView` önizlemesindeki `if` bunu telafi etmek için yazılmış; bazı önizlemeler de kendi klasörünü ayrıca oluşturuyor.
- **Neden önemli:** Önizleme sonuçları önceki önizlemelere bağlı oluyor; aynı önizleme farklı zamanlarda farklı görünüyor.
- **Öneri:** `preview`, her çağrıda `UUID` ile yeni bir klasör versin; elle yazılan klasörler kalksın.

#### S20 · Küçük · Bazı önizlemeler `CartStore` vermiyor
- **Dosya:** `Views/Home/HomeView.swift:94–99`, `Views/Categories/CategoryProductsView.swift:52–61`, `Views/Components/ProductGridView.swift:39–46`
- **Sorun:** Bu önizlemeler yalnızca `FavoritesStore` veriyor. Önizlemede bir karta basılırsa açılan `ProductDetailView` → `AddToCartBar`, `@Environment(CartStore.self)` bulamadığı için çöküyor.
- **Neden önemli:** Önizlemede gezinmek, uygulamanın kendisinde olmayan bir çökme üretiyor ve önizlemeye güveni azaltıyor.
- **Öneri:** Önizlemeler için iki store'u ve dili birlikte veren bir `.previewEnvironment()` modifier'ı yaz ve her önizlemede onu kullan.

### Test kapsamı

Bugün 41 test var: fiyat ve para birimi, dil ve tema, kategori adları, decode, store'lar ve aramanın iki senaryosu. Testler hızlı (≈1,4 sn) ve ağa çıkmıyor; arama testi `URLProtocol` tabanlı sahte bir oturum kullanıyor.

#### T1 · Önemli · Kritik akışların testi eksik (birinci turdan, kısmen düzeltildi)
- **Dosya:** `TrendyolBenzeriTests/`
- **Sorun:**
  - **Eklenenler:** Fiyat yuvarlama, TL ve dolar toplamları, eski arama testi.
  - **Hâlâ test edilmeyenler:**
    - ViewModel'lerin `load` → `.loaded` / `.failed` geçişleri.
    - İptalde `.idle`'a dönüş.
    - `refresh` davranışı (O11).
    - `APIClient`'ın hata eşlemesi: 2xx dışı kod → `badStatus`, bozuk JSON → `decoding`, `URLError.cancelled` → `CancellationError`.
- **Neden önemli:** O11 gibi bir hata, bu testler olsaydı yazıldığı gün yakalanırdı.
- **Öneri:**
  - `SearchStubURLProtocol`'ü genel bir `StubURLProtocol`'e çevir (yol → durum kodu, gövde, gecikme).
  - Üç ViewModel ve `APIClient` için durum geçişi testleri yaz.

#### T2 · Küçük · Ek test ve kontroller (birinci turdan, kısmen düzeltildi)
- **Sorun:**
  - **Eklenenler:** Eski arama ve bozuk plist testleri.
  - **Hâlâ eksik:**
    - `hasDiscount` / `discountRate` uç değerleri (S1).
    - `StarRatingView` eşikleri (0,25 / 0,75).
    - Gerçek bir API cevabının tamamıyla decode.
    - `+` kodlaması (S2).
    - Release derlemesinin PR'dan önce otomatik kontrolü (K1). Bu turda elle yapıldı.
- **Neden önemli:** Bu davranışların her biri bir kez bozulmuş ya da bozulmaya açık. Testi olmayan düzeltme sonraki değişiklikte geri gelebilir.
- **Öneri:**
  - Bu testleri ekle.
  - Gerçek cevabı `TrendyolBenzeriTests/Fixtures/` altına koy.
  - Release derlemesini PR kontrollerine ekle.

#### T3 · Küçük · Yeni kodun test edilmeyen kısımları
- **Dosya:** `Views/Components/ProductImageView.swift:59–71`, `Views/Categories/CategoriesView.swift:56–60`, `TrendyolBenzeriApp.swift:28–30`
- **Sorun:**
  - #15'teki yeniden deneme kuralının testi yok (S17).
  - Kategorilerin Türkçe alfabe sırası (`sortedByName`) view içinde `private` olduğu için test edilemiyor. Ç, Ö, Ü'nün doğru yerde olduğunu kimse doğrulamıyor.
  - Kökte locale ile para biriminin birlikte verildiği (S14) yalnızca simülatörde görülerek kontrol edildi.
- **Neden önemli:** Bunlar son iki PR'ın asıl davranışları. Bir refactor ile sessizce bozulabilirler.
- **Öneri:**
  - Yeniden deneme kuralını `ImageRetryPolicy`'ye çıkarıp test et.
  - Sıralamayı `[ProductCategory].sortedByDisplayName(locale:)` gibi test edilebilir bir fonksiyona taşı; `tr_TR` ve `en_US` için test yaz.
  - S14 uygulanırsa `Currency(locale:)` için test ekle.

## Sonraki adımlar

### Önerilen sıra
1. **O11 ve T1:** Yenileme hatasında listeyi koru. Ortak yükleyiciyi (S6) çıkar ve durum geçişlerini test et.
2. **O2 ve O3:** Sepet ve favoriler için sürümlü kayıt tipine geç (id + adet); ürünleri açılışta tazele. S18 de bununla çözülür.
3. **O4:** `APIClient.get`'i `@concurrent` yap; decoder ve tarih biçimlerini bir kez oluştur.
4. **O12, O9, O10:** Erişilebilirlik turu. Simülatörde Accessibility Inspector, VoiceOver ve en büyük yazı boyutuyla dene.
5. **S11:** Swift 6 dil moduna geç. Kod bugün hazır; ne kadar beklenirse o kadar zorlaşır.
6. **S21 ve S13:** `PLAN.md` ve `CLAUDE.md`'yi kodla ve güncel kurallarla eşitle.
7. Kalan küçük bulgular.

### Lint kurallarıyla otomatik yakalanabilecekler
Projede SwiftLint ya da başka bir lint aracı yok. Önerilenler:
- **SwiftLint kuralları:**
  - Hazır kurallar: `accessibility_label_for_image` ve `accessibility_trait_for_button` (opt-in), `unused_declaration` (analyzer).
  - **Özel kural, `print` yasak:** `print(` → `Logger` kullanılır (S7).
  - **Özel kural, `AsyncImage` yasak:** `ProductImageView.swift` dışında `AsyncImage(` kullanılmaz (#15, S17).
  - **Özel kural, sabit punto ve çerçeve:** `Views/` içinde `.system(size:`, `size: <sayı>` ve `frame(width: <sayı>` için uyarı (O10).
  - **Özel kural, sabit para birimi ve locale:** `.currency(code:`, `"TRY"`, `"USD"`, `Locale(identifier:` yalnızca `PriceFormatter.swift` ve `AppLanguage.swift` içinde (S10, S15).
  - **Özel kural, sistem renkleri:** Metin ve zemin için `.green`, `.red`, `.orange` yerine Assets renkleri (O7, O12).
  - **Özel kural, SwiftUI importu:** `Models/`, `Networking/`, `Persistence/` içinde `import SwiftUI` olmaz (S12).
  - **Özel kural, `String` metin:** `Views/` içinde `String(localized:` kullanılmaz; `resolved(in:)` kullanılır (S16).
- **Derleyici ayarları:** `SWIFT_VERSION = 6` (S11). Veri yarışı riskleri böylece derleme hatasına dönüşür.
- **Catalog kontrolü:** Bu turdaki taramayı her PR'da çalıştır. Kontrol edilecekler:
  - derleyicinin çıkardığı her anahtar catalog'da,
  - her anahtarın `en` ve `tr` karşılığı var,
  - kullanılmayan anahtar yok.
- **Ölü kod:** Periphery ile kullanılmayan tanımlar (`fetchProduct(id:)`, `lineTotal`, `totalPrice`; S7, S13).
- **Release derlemesi:** Her PR'dan önce `-configuration Release build` (K1).

### Testle korunması gerekenler
- **ViewModel'ler:**
  - Yenileme hatası mevcut listeyi silmez (O11).
  - `load` → `.loaded` / `.failed`; iptalde `.idle` (T1).
- **`APIClient`:**
  - Durum kodu, decode ve iptal hatalarının eşlenmesi (T1).
  - `+` karakterinin `%2B` gönderilmesi (S2).
- **Store'lar:**
  - Sepet ve favoriler ürünü tazeler.
  - Stok düşünce adet kırpılır (O2).
  - Eski sürüm plist göç eder ya da yedeklenir; ikinci bozulma eski yedeği silmez (O3).
- **Fiyat:**
  - `hasDiscount` ile rozetin aynı karar olması (S1).
  - Negatif stok ve %100 üstü indirim sınırlanır (S3).
  - TL ve dolar toplamlarının kuruşu kuruşuna tutması. Bugün testli; korunmalı (O1).
- **Dil ve para birimi:**
  - "Sistem" çözümlemesi (bugün testli).
  - Bölgenin korunması (S15).
  - `Currency(locale:)` (S14).
  - Kategori sıralaması `tr_TR` ve `en_US`'te (T3).
- **Görsel yükleme:** İptal yeniden denenir; kalıcı hata sınırlı denenir (S17, T3).
- **Erişilebilirlik:** UI testlerinde `performAccessibilityAudit()` kontrast, dokunma alanı, etiket ve Dynamic Type sorunlarını otomatik yakalar (O9, O10, O12).
  - Ancak `CLAUDE.md` şablon UI testlerinin scheme'e geri eklenmemesini söylüyor. Bunun için ayrı bir UI test scheme'i ya da bu kuralın gözden geçirilmesi gerekir; karar proje sahibinin.

### Mimari kural olarak yazılması gerekenler
Bunlar `CLAUDE.md`'ye kural olarak eklenmeli:
- **Yenileme:** `refresh()` hata verirse `state`'e dokunmaz; mevcut veri ekranda kalır, hata geçici olarak gösterilir. Yükleme mantığı tek bir ortak yardımcıdadır (O11, S6).
- **Kalıcı veri:**
  - Plist'e API modeli (`Product`) değil, sürümlü ve küçük bir kayıt tipi yazılır (id, adet).
  - Ürün bilgisi her zaman API'den tazelenir.
  - Şema değişikliğinde göç ya da yedek zorunludur (O2, O3, S18).
- **Veri doğrulama:** API'den gelen sayılar (stok, indirim, fiyat) model katmanında sınırlandırılır; view'lar ham değere güvenmez (S3).
- **Concurrency:** Ağ ve decode işi `@concurrent` fonksiyonlarda yapılır. Proje Swift 6 dil modunda tutulur (O4, S11).
- **Katmanlar:** `Models/`, `Networking/`, `Persistence/` SwiftUI import etmez. Environment anahtarları `Views/` altında tanımlanır (S12).
- **Tek kaynak:** Para birimi locale'den türetilir ya da her zaman locale ile birlikte verilir. Aynı kararın (ör. indirim var mı) birden fazla kopyası olmaz (S14, S1).
- **Görseller:** Ürün görseli yalnızca `ProductImageView` ile gösterilir; yeniden deneme kuralı test edilen bir tiptedir (S17). Bu kural `CLAUDE.md`'de var; lint ile zorlanmalı.
- **Loglama:** `print` yerine `Logger` (S7).
- **Erişilebilirlik:**
  - Metin ve zemin renkleri Assets'ten gelir ve iki temada en az 4,5:1 kontrast verir.
  - Punto ve ikon boyutları `@ScaledMetric` ya da metin stilleriyle tanımlanır.
  - Tekrarlanan butonların (kalp, adet) etiketi ürün adını içerir (O9, O10, O12).
- **Önizlemeler:** Her önizleme, ekranın ve gidilebilecek ekranların istediği bütün environment değerlerini tek bir yardımcıyla verir (S8, S20).
- **Belgeler:** Kural değiştiğinde `PLAN.md`'deki eski kurallar silinir ya da `CLAUDE.md`'ye yönlendirilir; iki dosya çelişmez (S21).
