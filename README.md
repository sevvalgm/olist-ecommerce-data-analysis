# SQL Server (SSMS) ile Olist E-Ticaret Veri Analizi (Case Study)

Bu proje, Brezilya'nın önde gelen e-ticaret platformu Olist'e ait halka açık veri setini kullanarak **Microsoft SQL Server (SSMS)** üzerinde kapsamlı bir **SQL Vaka Çalışması** (Case Study) sunmaktadır. Proje, veri temizliğinden ileri düzey metrik hesaplamalarına kadar bir veri analizi sürecini baştan sona uygulamayı amaçlamıştır. Çalışma, daha önce **BigQuery** üzerinde hazırlanan analizin SQL Server (T-SQL) ortamına taşınmış ve geliştirilmiş halidir.

<!-- Ekran görüntülerini GitHub'da README'yi düzenlerken sürükle-bırak ile ekleyebilirsin -->
<!-- <img width="1863" alt="image" src="..." /> -->

## 🎯 Proje Amaçları

SQL Server'ın gücünden yararlanılarak, Olist'in 100K+ sipariş verisi üzerinden aşağıdaki temel hedefler gerçekleştirilmiştir:

* Veri kalitesi kontrolü (NULL ve yinelenen kayıtların tespiti).
* Önce sorunları tespit edip sonra düzeltme yaklaşımıyla; coğrafi (şehir/eyalet) ve metinsel verilerin temizlenmesi ve standartlaştırılması.
* Satış, sipariş, kârlılık ve müşteri davranışları metriklerinin hesaplanması.
* Zaman serisi trendleri ve pazar dinamiklerinin analizi.
* Gerçek iş dünyasına uygulanabilir, aksiyon odaklı içgörüler üretilmesi.

## 🧩 Veri Seti ve Metodoloji

| Kriter | Detay |
| :--- | :--- |
| **Veri Kaynağı** | Brazilian E-Commerce Public Dataset by Olist (Kaggle) |
| **Veri Ambarı** | Microsoft SQL Server (SSMS), `dbo` şeması, 9 tablo |
| **Ana Teknoloji** | T-SQL |
| **Ana SQL Dosyası** | `olist_sqlserver_full.sql` |
| **Temiz Tablo Standardı** | `dbo.olist_real_<tablo>_cleaned` |

**Kullanılan tablolar:** `customers`, `geolocation`, `order_items`, `order_payments`, `order_reviews`, `orders`, `products`, `sellers`, `product_category_name_translation`

### 🛠️ Kapsamlı Analiz Akışı

| Bölüm | Konu | Kullanılan Temel SQL Fonksiyonları |
| :--- | :--- | :--- |
| 1️⃣ Veri Kalitesi Kontrolü | NULL ve duplicate analizleri | `COUNT(*), GROUP BY, HAVING` |
| 2️⃣ Veri Temizleme (Cleaning) | Metin normalizasyonu, boşluk ve özel karakter temizliği, mantık kontrolleri | `UPPER(), LTRIM(), RTRIM(), REPLACE(), TRANSLATE()` |
| 3️⃣ Cleaned Tabloların Oluşturulması | Temizlenmiş verinin kalıcı tablolara yazılması ve yeniden kontrolü | `SELECT INTO, ROW_NUMBER(), CTE` |
| 4️⃣ Sipariş Analizi | Toplam sipariş, teslimat, iptal, zaman trendi | `DATEFROMPARTS(), DATEPART(), CASE WHEN` |
| 5️⃣ Gelir ve Kârlılık Analizi | Ciro, AOV, kâr marjı, ödeme tipi dağılımı | `SUM(), ROUND(), GROUP BY` |
| 6️⃣ Satıcı Performansı | Aktif satıcı sayısı, satış hacmi, puan dağılımı | `JOIN, DATEDIFF(), AVG()` |
| 7️⃣ Müşteri Davranışları | Tekrar alım (sadakat) ve lokasyon yoğunluğu analizi | `COUNT(DISTINCT), HAVING, PARTITION BY` |
| 8️⃣ Ödeme Analizi | Ödeme yöntemi bazlı ciro, bölgesel kırılımlar | `WINDOW FUNCTIONS, RANK()` |

```sql
-- Örnek: temizlenmiş müşteri tablosu
SELECT
    customer_id,
    customer_unique_id,
    UPPER(LTRIM(RTRIM(customer_city)))  AS customer_city,
    UPPER(LTRIM(RTRIM(customer_state))) AS customer_state
INTO dbo.olist_real_customers_cleaned
FROM dbo.customers;
```

---

## 💡 Temel İş İçgörüleri (Key Insights)

Kapsamlı SQL sorgularından elde edilen en kritik iş sonuçları aşağıdadır:

| Metrik | Sonuç | İş Yorumu ve Önerisi |
| :--- | :--- | :--- |
| **Toplam Gelir** | **15.8M BRL** | Brüt satış hacmi, pazar büyüklüğünün temel göstergesidir. |
| **Teslim Edilen Sipariş Oranı** | **%97** | Mükemmel lojistik başarı oranı. Müşteri memnuniyetini olumlu etkiler. |
| **En Yoğun Sipariş Ayı** | **Kasım 2017** | Black Friday döneminin Brezilya e-ticaret pazarındaki dominant etkisini gösterir. Kampanyalar bu döneme yoğunlaştırılmalıdır. |
| **En Çok Sipariş Veren Eyalet** | **SP (São Paulo)** | Pazar yoğunluğunun coğrafi olarak São Paulo'da (Güneydoğu Bölgesi) toplandığını gösterir. |
| **Tekrar Alışveriş Yapan Müşteri Oranı** | **%5.7** | Sadakat oranının düşük olduğunu işaret eder. Müşteri tutma (retention) programlarına yatırım yapılmalıdır. |
| **Ortalama Kâr Marjı** | **%12.4** | Kârlılık marjı düşüktür. Özellikle lojistik maliyetleri ve ürün maliyetleri detaylı incelenmelidir. |
| **En Popüler Kategoriler** | `bed_bath_table`, `health_beauty` | Bu kategorilerde pazar liderliğini korumak için stok ve fiyatlama stratejileri optimize edilmelidir. |
| **En Yaygın Ödeme Tipi** | **Credit Card (%77)** | Kredi kartı entegrasyonu ve güvenliğine öncelik verilmelidir. Taksitli ödeme (installment) seçenekleri genişletilmelidir. |

---

## ▶️ Nasıl Çalıştırılır?

1. Kaggle'dan [Olist veri setini](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) indir.
2. SSMS'te yeni bir veritabanı oluştur ve CSV dosyalarını `dbo` şemasına içe aktar (*Tasks → Import Flat File*).
3. `olist_sqlserver_full.sql` dosyasını aç ve bölümleri sırayla çalıştır (önce kontroller, sonra temizleme, en son analizler).

## 📁 Repo Yapısı

```
├── README.md
├── olist_sqlserver_full.sql   # Kontrol + temizleme + analiz scripti
└── images/                    # Sorgu çıktısı ekran görüntüleri
```

## 👩‍💻 Yazar

**Şevval Nur Gümüşer** — Bilgisayar Mühendisi | Veri Analizi & Makine Öğrenmesi