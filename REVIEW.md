# Vitrin – Kod İncelemesi

Kapsam: `main..chore/claude-md` (PR #1–#10'daki tüm uygulama kodu ve testler). İnceleme tarihi: 16.10.2026.

## Genel değerlendirme

Mimari temiz ve tutarlı:
- View → ViewModel → `ProductService` → `APIClient` akışına her yerde uyuluyor.
- Paylaşılan state iki `@Observable` store'da toplanmış.
- Yükleme, hata ve boş durumlar her ekranda ele alınmış.
- İptal edilen istekler hata ekranı göstermiyor.

Debug derlemesi ve 22 unit test sorunsuz. Ancak:
- **Release derlemesi hiç derlenmiyor.**
- Sepette kuruş farkı oluşuyor: 194 ürünün 146'sında, ekranda görünen birim fiyat × adet, satır toplamını tutmuyor.

Bunların dışındaki önemli konular şunlar:
- Sepet ve favorilerde ürünlerin eski kopyalarının saklanması.
- Plist verisinin şema değişikliğinde sessizce kaybolması.
- JSON çözümünün ana thread'de yapılması.
- Arama sonuçlarındaki küçük bir yarış durumu.
- Erişilebilirlik: kontrast, dokunma alanı, VoiceOver ve Dynamic Type.

Önem dereceleri:
- **Kritik:** Uygulamayı dağıtmayı engelleyen ya da veriyi bozan sorun.
- **Önemli:** Kullanıcının fark edeceği hata ya da kalite sorunu.
- **Küçük:** İyileştirme.

Doğrulama yöntemi: Release derlemesi, gerçek API verisi, kontrast oranları, derleyici bayrakları ve URL kodlaması çalıştırılarak kontrol edildi. Dynamic Type ve VoiceOver bulguları kod okumasına dayanıyor, simülatörde denenmedi.

## Öncelik sırasına göre özet

| # | Önem | Bulgu |
| --- | --- | --- |
| K1 | Kritik | Release derlemesi başarısız: `PreviewData` yalnızca DEBUG'da var, `#Preview`'lar her yapılandırmada derleniyor |
| O1 | Önemli | İndirimli fiyat yuvarlanmadan çarpılıyor; satır ve sepet toplamında kuruş farkı |
| O2 | Önemli | Sepet ve favoriler ürünün eski kopyasını saklıyor; fiyat ve stok hiç güncellenmiyor |
| O3 | Önemli | Plist çözülemezse sepet ve favoriler sessizce siliniyor |
| O4 | Önemli | JSON çözümü ve tarih ayrıştırma ana thread'de yapılıyor |
| O5 | Önemli | Eski bir aramanın sonucu yeni aramanın üzerine yazılabiliyor |
| O6 | Önemli | Arayüz sistem metinleri ve VoiceOver dili İngilizce (uygulamada Türkçe yerelleştirme yok) |
| O7 | Önemli | Stok ve indirim metinlerinde renk kontrastı WCAG AA'nın altında |
| O8 | Önemli | Kalp ve adet butonlarının dokunma alanı 44 pt'den küçük |
| O9 | Önemli | VoiceOver ürün kartını parça parça ve bağlamsız okuyor |
| O10 | Önemli | Sabit font ve çerçeve boyutları Dynamic Type ile büyümüyor |
| T1 | Önemli | ViewModel, `APIClient` ve fiyat hesaplama testleri eksik |
| S1 | Küçük | %0,5'in altındaki indirimler "%0" rozeti olarak görünüyor |
| S2 | Küçük | Arama metnindeki `+` sunucuya boşluk olarak gidiyor |
| S3 | Küçük | Negatif stok ya da %100'ün üzerindeki indirim gibi hatalı verilere karşı koruma yok |
| S4 | Küçük | Sıralı listeler her erişimde yeniden hesaplanıyor; gözlem tüm sözlüğü kapsıyor |
| S5 | Küçük | Görsel önbelleği küçük; 194 ürün tek istekte yükleniyor |
| S6 | Küçük | Yükleme mantığı, fiyat gösterimi ve görsel yükleme kodu tekrar ediyor |
| S7 | Küçük | İsimlendirme ve yerleşim: `MainTabView.Tab`, `discountLabel`'ın yeri, kullanılmayan kod, `print` |
| S8 | Küçük | `PlistStorage.preview` tüm önizlemelerde aynı klasörü kullanıyor |
| S9 | Küçük | Demo ödeme uyarısı "Siparişin alındı" diyor ama sepet olduğu gibi duruyor |
| S10 | Küçük | Sayı biçimleri karışık: fiyat en_US, tarih tr_TR, puan cihaz dili |
| T2 | Küçük | Arama, plist, uç durumlar ve Release derlemesi için ek test ve kontroller |

## Bulgular

### Hatalar ve uç durumlar

#### K1 · Kritik · Release derlemesi başarısız
- **Dosya:** `Utilities/PreviewData.swift:6–50`. Hatalar örneğin `Views/Components/FavoriteButton.swift:35`, `Views/ProductDetail/ProductDetailView.swift:141`, `Views/MainTabView.swift:54`'te.
- **Sorun:** Örnek veriler (`Product.previewMascara`, `PlistStorage.preview`) `#if DEBUG` içinde. Ancak `#Preview` blokları Release'te de derleniyor. `-configuration Release` ile alınan derleme 22 hatayla başarısız oluyor; Archive ve TestFlight alınamıyor. Sorun PR #4'te ortaya çıktı. Testler ve ⌘R yalnızca Debug derlediği için şimdiye kadar fark edilmedi.
- **Öneri:** `PreviewData.swift`'teki `#if DEBUG`'ı kaldır; veri küçük olduğu için Release'te kalmasının zararı yok. Alternatif olarak her `#Preview`'ı `#if DEBUG` içine al. Her PR'ın kontrol adımlarına bir Release derlemesi ekle. `CLAUDE.md`'deki "`PreviewData` (yalnızca DEBUG)" notunu da güncelle.

#### O1 · Önemli · Sepet toplamında kuruş farkı
- **Dosya:** `Models/Product.swift:30–32`, `Models/CartItem.swift:16–18`, `Stores/CartStore.swift:41–43`
- **Sorun:** `discountedPrice` yuvarlanmıyor; örneğin 9,99 × 0,8952 = 8,943048. Ekranda birim fiyat `$8.94` görünüyor, ama satır ve sepet toplamı yuvarlanmamış değerden hesaplanıyor. Gerçek veriyle kontrol edildi: 194 ürünün 146'sında 2, 3 ya da 5 adette fark çıkıyor. Örnekler:
  - Maskara: 2 × $8.94 = $17.88 olmalı, ekranda **$17.89** görünüyor.
  - Göz farı paleti: 2 × $16.35 = $32.70 olmalı, ekranda **$32.71** görünüyor.
- **Öneri:** İndirimli birim fiyatı bir kez kuruşa yuvarla, satır ve sepet toplamını bu yuvarlanmış değerden hesapla. Para hesabı için `Double` yerine `Decimal` kullanmak en sağlamı. Bu durumu test eden bir test ekle (bkz. T1).

#### O2 · Önemli · Sepet ve favorilerde ürünün eski kopyası saklanıyor
- **Dosya:** `Stores/CartStore.swift:57–59`, `Stores/FavoritesStore.swift:41–48`, `Views/Cart/CartItemRow.swift:86`
- **Sorun:** Store'lar, ürün eklendiği andaki `Product` kopyasını plist'e kaydediyor ve bu kopya bir daha güncellenmiyor. Ürün sepette zaten varken yeniden eklenince yalnızca adet artıyor, ürün bilgisi eski kalıyor. Sonuçları:
  - Fiyat değişirse sepet eski fiyattan toplar.
  - Stok düşerse sepetteki adet stoktan fazla kalabilir.
  - Sepet satırındaki `+` butonu stok kontrolünü eski stokla yapıyor.
  - Favoriler ve sepetten açılan detay ekranı eski bilgiyi gösteriyor.
- **Öneri:**
  - `add` içinde satırın `product` bilgisini gelen yeni ürünle güncelle.
  - Sepet ekranı açılırken ürünleri id ile tazele; kullanılmayan `ProductService.fetchProduct(id:)` bunun için hazır.
  - Sepetteki adet yeni stoktan fazlaysa adedi stoğa indir.

#### O3 · Önemli · Plist çözülemezse veri sessizce kayboluyor
- **Dosya:** `Stores/CartStore.swift:20–24`, `Stores/FavoritesStore.swift:21–25`
- **Sorun:** Dosya çözülemezse hata yalnızca `print` ile yazılıyor ve store boş başlıyor. İlk değişiklikte boş içerik, eski dosyanın üzerine yazılıyor. Plist'te `Product`'ın tamamı saklandığı için ileride modele zorunlu tek bir alan eklemek bile kullanıcının bütün sepetini ve favorilerini siler.
- **Öneri:**
  - Çözülemeyen dosyayı silmeden önce `.corrupt` uzantısıyla yedekle.
  - Kalıcı veri için ayrı ve sürümlü bir tip kullan; örneğin yalnızca id, adet ve gereken alanlar.
  - Hataları `Logger` ile kaydet.

#### S1 · Küçük · "%0" indirim rozeti
- **Dosya:** `Models/Product.swift:25–27`, `Utilities/PriceFormatter.swift:17–19`
- **Sorun:** `hasDiscount`, indirim 0'dan büyükse `true` döndürüyor; ama rozet metni yuvarlanıyor. %0,04–0,16 indirimli 3 üründe (id 21, 25, 92) rozette "%0" yazıyor ve neredeyse aynı fiyat üstü çizili görünüyor.
- **Öneri:** İndirimi ancak rozet en az "%1" gösterecekse ya da fiyat farkı en az 1 kuruşsa göster.

#### S2 · Küçük · Aramada `+` boşluk olarak gidiyor
- **Dosya:** `Networking/APIClient.swift:24–26`, `Networking/ProductService.swift:32`
- **Sorun:** `URLComponents` `+` karakterini kodlamıyor; sunucu da onu boşluk olarak okuyor. Doğrulandı: "a+b" araması "a b" araması gibi 21 sonuç döndürüyor, `%2B` ile gönderilince ise 0 sonuç.
- **Öneri:** `percentEncodedQuery` içinde `+` karakterini `%2B` ile değiştir.

#### S3 · Küçük · Hatalı veriye karşı koruma yok
- **Dosya:** `Views/ProductDetail/ProductDetailView.swift:97–101`, `Models/Product.swift:30–32`
- **Sorun:** Stok negatif gelirse ekranda yeşil "Stokta -1 adet" yazar. İndirim %100'ün üzerinde gelirse fiyat negatif olur.
- **Öneri:** Stok kontrolünü `case ...0` ile yap; indirim yüzdesini 0–100 arasına sınırla.

#### S9 · Küçük · Yanıltıcı demo ödeme uyarısı
- **Dosya:** `Views/Cart/CartView.swift:18–22`
- **Sorun:** Uyarının başlığı "Siparişin alındı", ama sepet olduğu gibi kalıyor.
- **Öneri:** Başlığı "Ödeme adımı yakında" gibi bir metinle değiştir.

### State management

#### S4 · Küçük · Gereksiz yeniden hesaplama
- **Dosya:** `Stores/CartStore.swift:28–30`, `Stores/FavoritesStore.swift:29–31`, `Views/Cart/CartView.swift:40,50`, `Views/MainTabView.swift:43`
- **Sorun:**
  - `sortedItems` ve `products` her erişimde listeyi yeniden sıralıyor; `CartView` her çizimde bunu iki kez yapıyor.
  - `@Observable` değişiklikleri sözlük düzeyinde izliyor, ürün düzeyinde değil. Bu yüzden tek bir favori değiştiğinde ekrandaki bütün `FavoriteButton`'lar yeniden hesaplanıyor. Sepet değiştiğinde de `MainTabView`'ın tamamı yeniden hesaplanıyor.
  - Bu ölçekte fark edilmez, ama ürün sayısı arttıkça büyür.
- **Öneri:** Sıralı listeyi değişiklik anında hesaplayıp sakla; `CartView`'da tek bir yerel değişkene al.

### Concurrency

#### O4 · Önemli · JSON çözümü ana thread'de yapılıyor
- **Dosya:** `Networking/APIClient.swift:20,50,61–71`
- **Sorun:** Projede `SWIFT_APPROACHABLE_CONCURRENCY` açık. Derleyici bayraklarında `NonisolatedNonsendingByDefault` görünüyor. Bu ayarla `nonisolated async` bir fonksiyon, onu çağıranın actor'ünde çalışır. ViewModel'ler MainActor'da olduğu için bu iş ana thread'de yapılıyor:
  - 194 ürünlük, yaklaşık 300 KB'lık cevabın çözümü.
  - Yaklaşık 580 yorum tarihinin ayrıştırılması; her tarih için yeni bir `ISO8601FormatStyle` oluşturuluyor.

  Bu yük, özellikle eski cihazlarda kaydırma sırasında takılmaya yol açabilir. `CLAUDE.md`'deki "ağ katmanı `nonisolated`" ifadesi ağ katmanının arka planda çalıştığını düşündürüyor, oysa bu ayarla öyle değil.
- **Öneri:** `get` fonksiyonunu `@concurrent func get<T: Decodable & Sendable>` yap. Tarih biçimlendiricilerini `static let` olarak bir kez oluştur.

#### O5 · Önemli · Eski arama sonucu yenisinin üzerine yazılabiliyor
- **Dosya:** `Views/Home/HomeViewModel.swift:52–53`, `Views/Common/ErrorView.swift:21`, `Views/Home/HomeView.swift:65–67`
- **Sorun:** Ağ cevabı geldikten sonra görevin iptal edilip edilmediği kontrol edilmiyor. Cevap, iptalle aynı anda gelirse eski sorgunun sonucu `searchState`'e yazılıyor. Yeni sorgunun 400 ms beklemesi sırasında ekranda yanlış sonuç ya da yanlış "Sonuç bulunamadı" görünebiliyor. Ayrıca `ErrorView`'ın "Tekrar Dene" butonu iptal edilmeyen bir `Task {}` başlatıyor. Bu görev eski sorguyla sonradan bitip yeni sonucun üzerine yazabiliyor.
- **Öneri:**
  - Sonucu atamadan önce `try Task.checkCancellation()` çağır, ya da sonucu sorguyla birlikte sakla ve sorgu güncel değilse yok say.
  - Tekrar deneme işini de `.task(id:)` üzerinden yap.

### Performans

#### S5 · Küçük · Görsel önbelleği ve tek seferde yükleme
- **Dosya:** `Views/Components/ProductCardView.swift:44`, `Views/Home/HomeViewModel.swift:64`
- **Sorun:**
  - `AsyncImage` yalnızca varsayılan `URLCache`'i kullanıyor ve bunun bellek kapasitesi küçük. Grid'de geri kaydırınca görseller yeniden yükleniyor ve yer tutucular yanıp sönüyor.
  - Ana sayfa 194 ürünü yorumlarıyla birlikte tek istekte çekiyor.
- **Öneri:** Uygulama açılışında `URLCache` kapasitesini büyüt ya da küçük bir görsel önbelleği ekle. Veri büyürse `limit` ve `skip` ile sayfalı yüklemeye geç.

### Erişilebilirlik

#### O6 · Önemli · Uygulamada Türkçe yerelleştirme yok
- **Dosya:** `TrendyolBenzeri.xcodeproj/project.pbxproj:190–195`
- **Sorun:** Projede `developmentRegion = en`, `knownRegions` ise yalnızca `en` ve `Base`. Uygulama Türkçe dilini desteklediğini bildirmediği için Türkçe cihazda bile şunlar İngilizce:
  - arama çubuğundaki "Cancel" gibi sistem metinleri,
  - sistem erişilebilirlik metinleri,
  - VoiceOver'ın okuma dili; Türkçe metinler İngilizce telaffuzla okunuyor.

  Bu, `CLAUDE.md`'deki "arayüz metinleri Türkçe" kuralına aykırı.
- **Öneri:** Geliştirme dilini `tr` yap ya da String Catalog ile Türkçe dilini ekle.

#### O7 · Önemli · Renk kontrastı yetersiz
- **Dosya:** `Views/ProductDetail/ProductDetailView.swift:97–100`, `Views/ProductDetail/ProductDetailView.swift:73–78`, `Views/Components/ProductCardView.swift:62–69`
- **Sorun:** Açık temada ölçülen kontrast oranları:

  | Metin | Oran |
  | --- | --- |
  | Turuncu "Son n ürün!" | 2,2:1 |
  | Yeşil "Stokta n adet" | 2,2:1 |
  | Kırmızı "Tükendi" | 3,55:1 |
  | Kırmızı zemin üzerinde beyaz indirim rozeti | 3,55:1 |

  Küçük metin için WCAG AA en az 4,5:1 istiyor. Koyu temada sorun yok.
- **Öneri:** Açık ve koyu tema için ayrı, daha koyu tonları Assets'e ekle. Stok durumunu yalnızca renkle değil ikonla da anlat; ikon zaten var.

#### O8 · Önemli · Dokunma alanı küçük
- **Dosya:** `Views/Components/FavoriteButton.swift:24` (34×34), `Views/Cart/CartItemRow.swift:71,84` (32×32)
- **Sorun:** Apple'ın arayüz yönergeleri (HIG) en az 44×44 pt'lik dokunma alanı öneriyor. Grid'deki kalp ve sepetteki adet butonlarına isabet ettirmek zor.
- **Öneri:** Görsel boyutu koru, dokunma alanını büyüt: `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())`.

#### O9 · Önemli · VoiceOver ürün kartını bağlamsız okuyor
- **Dosya:** `Views/Components/ProductGridView.swift:22–24`, `Views/Components/ProductCardView.swift:14–41`, `Views/Components/FavoriteButton.swift:30`, `Views/ProductDetail/ProductImageGallery.swift:18`, `Views/Cart/CartItemRow.swift:50,75`
- **Sorun:**
  - Karttaki her metin ayrı ayrı okunuyor. Üstü çizili eski fiyat bağlamsız kalıyor: "$9.99, $8.94".
  - Görsellerin erişilebilirlik etiketi yok.
  - Kalp butonu her kartta yalnızca "Favorilere ekle" diyor; hangi ürün olduğu anlaşılmıyor.
  - Sepet satırındaki adet yalnızca "2" diye okunuyor.
- **Öneri:**
  - Kartı `.accessibilityElement(children: .combine)` ile tek öğe yap ve şu tür bir etiket ver: "Essence, Essence Mascara Lash Princess, 2,6 puan, %10 indirim, eski fiyat 9,99 dolar, indirimli fiyat 8,94 dolar".
  - Kalp etiketine ürün adını ekle.
  - Görselleri etiketle ya da `.accessibilityHidden` ile VoiceOver'dan gizle.
  - Adet kontrolünü `accessibilityAdjustableAction` ile ayarlanabilir bir öğe yap.

#### O10 · Önemli · Dynamic Type desteği eksik
- **Dosya:** `Views/Components/FavoriteButton.swift:22`, `Views/Components/StarRatingView.swift:17`, `Views/Cart/CartItemRow.swift:60,71,84`, `Views/Cart/CartView.swift:58–86`, `Views/ProductDetail/AddToCartBar.swift:20–44`
- **Sorun:**
  - `.font(.system(size:))` ve sabit `frame` değerleri sistem yazı boyutu büyütüldüğünde büyümüyor.
  - Sepet ve detaydaki alt çubuklarda fiyat ve buton yan yana duruyor. Erişilebilirlik boyutlarında bu çubukların sıkışması ya da metnin kesilmesi muhtemel. Bu madde kod okumasına dayanıyor, simülatörde denenmedi.
- **Öneri:** Boyutları `@ScaledMetric` ile tanımla. Alt çubuklarda `ViewThatFits` kullanarak büyük boyutta dikey yerleşime geç.

### Kod kalitesi

#### S6 · Küçük · Tekrar eden kod
- **Dosya:** `Views/Home/HomeViewModel.swift:24–74`, `Views/Categories/CategoriesViewModel.swift:19–48`, `Views/Categories/CategoryProductsViewModel.swift:22–46`, `Views/ProductDetail/ProductDetailView.swift:70–87`, `Views/Cart/CartItemRow.swift:27–35,50–59`
- **Sorun:**
  - Üç ViewModel'de aynı yükleme, yenileme ve iptal mantığı tekrar ediyor.
  - Fiyat ve indirim gösterimi `PriceView` dışında iki yerde yeniden yazılmış. Bu, `CLAUDE.md`'deki "`PriceView` kullanılır" kuralına aykırı.
  - Görsel yükleme kodu (`AsyncImage` durumları) üç yerde tekrar ediyor.
  - "n ürün" başlığı iki yerde tekrar ediyor.
- **Öneri:** Şu ortak parçaları çıkar:
  - genel bir `Loader<Value>`,
  - farklı boyutlara uyarlanabilen bir `PriceView(style:)`,
  - `DiscountBadge`,
  - `ProductImage`.

#### S7 · Küçük · İsimlendirme ve yerleşim
- **Dosya:** `Views/MainTabView.swift:11`, `Utilities/PriceFormatter.swift:15–20`, `Networking/ProductService.swift:46`, `TrendyolBenzeriTests/TrendyolBenzeriTests.swift`, `Stores/CartStore.swift:23,87`, `Stores/FavoritesStore.swift:24,54`
- **Sorun:**
  - `MainTabView.Tab`, SwiftUI'ın iOS 18'de eklenen `Tab` tipiyle aynı adı taşıyor.
  - `discountLabel` fiyat biçimlendirme dosyasında duruyor.
  - `fetchProduct(id:)` kullanılmıyor; O2 düzeltilirse kullanılacak.
  - Şablondan kalan boş `example()` testi duruyor.
  - Hatalar `print` ile yazılıyor.
- **Öneri:**
  - `Tab`'ın adını `AppTab` yap.
  - `discountLabel`'ı `Product+Display.swift` gibi ayrı bir dosyaya taşı.
  - Boş şablon testini sil.
  - Hataları `print` yerine `Logger` (os) ile kaydet.

#### S8 · Küçük · Önizlemeler aynı geçici klasörü kullanıyor
- **Dosya:** `Utilities/PreviewData.swift:46–48`, `Views/Favorites/FavoritesView.swift:56`
- **Sorun:** `PlistStorage.preview` her seferinde aynı geçici klasörü veriyor. Bu yüzden önizlemeler arasında favori ve sepet verisi birikiyor. `FavoritesView` önizlemesindeki `if` koşulu bunu telafi etmek için yazılmış.
- **Öneri:** Her çağrıda yeni, benzersiz bir klasör oluştur.

#### S10 · Küçük · Karışık sayı biçimleri
- **Dosya:** `Views/Components/ProductCardView.swift:83`, `Views/ProductDetail/ProductDetailView.swift:59`, `Views/ProductDetail/ReviewRowView.swift:18`
- **Sorun:** Fiyatlar en_US, tarihler tr_TR, puan ise cihaz diliyle biçimleniyor. Türkçe bir cihazda aynı kartta hem "4,5" hem "$8.94" görünüyor.
- **Öneri:** Hangi değerin hangi dil ayarıyla biçimleneceğini tek bir yerde belirle.

### Testler

#### T1 · Önemli · Kritik akışların testi yok
- **Dosya:** `TrendyolBenzeriTests/`
- **Sorun:** Şu akışlar hiç test edilmiyor:
  - ViewModel durum geçişleri: başarılı yükleme, hata, yenilemede listenin korunması, iptalde `.idle`'a dönüş.
  - `APIClient`'ın hata eşlemesi: 2xx dışı durum kodu, çözme hatası, `URLError.cancelled` → `CancellationError`.
  - Kuruş yuvarlaması (O1) ve gerçekçi fiyatlarla sepet toplamı.
- **Öneri:** `URLProtocol` tabanlı sahte bir oturumla `APIClient` ve ViewModel'leri test et. Fiyat testlerinde maskara örneğini (2 × $8.94 = $17.88) kullan.

#### T2 · Küçük · Ek test ve kontroller
- **Sorun:** Şunlar için test ya da kontrol yok:
  - Arama: 400 ms'lik bekleme ve eski sonucun yok sayılması (O5).
  - Bozuk plist dosyasıyla açılış (O3).
  - `hasDiscount` ve `discountLabel` uç değerleri (S1).
  - `StarRatingView` yıldız eşikleri.
  - Gerçek API cevabının tamamıyla çözme.
  - Release derlemesi (K1).
- **Öneri:** Bu testleri ekle. Release derlemesini her PR'dan önceki kontrollere dahil et.
