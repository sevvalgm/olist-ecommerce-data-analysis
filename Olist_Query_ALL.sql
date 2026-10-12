/* =====================================================================
   OLIST BRAZILIAN E-COMMERCE
   DOSYA 1/2 | TEMIZLEME + ANALIZE HAZIRLIK

   Platform : SQL Server 2017+ / SSMS
   Sema     : dbo

   CALISTIRMA:
   Dosyanin TAMAMINI F5 ile calistir.

   Kurallar:
   - Ham tablolara dokunulmaz.
   - Tam birebir duplicate satirlar DISTINCT ile tekillestirilir.
   - Mantiksiz degerler silinmez, flag ile isaretlenir.
   - Sehir / eyalet / kategori / siparis durumu / odeme tipi BUYUK HARF.
   - ID kolonlari degistirilmez.
   - Yorum metinleri BUYUK HARFE cevrilmez.
   ===================================================================== */

-- USE [VeritabaniAdin];

SET NOCOUNT ON;


/* =====================================================================
   0) HAZIRLIK
   ===================================================================== */

DROP TABLE IF EXISTS #raw_tables;

CREATE TABLE #raw_tables
(
    table_name sysname PRIMARY KEY
);

INSERT INTO #raw_tables (table_name)
VALUES
    ('olist_customers_dataset'),
    ('olist_geolocation_dataset'),
    ('olist_order_items_dataset'),
    ('olist_order_payments_dataset'),
    ('olist_order_reviews_dataset'),
    ('olist_orders_dataset'),
    ('olist_products_dataset'),
    ('olist_sellers_dataset'),
    ('product_category_name_translation');


/* 0a) EKSIK TABLO KONTROLU */

SELECT
    t.table_name AS missing_table
FROM #raw_tables t
WHERE OBJECT_ID(N'dbo.' + t.table_name) IS NULL;


/* 0b) KOLON TIPLERI */

SELECT
    c.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN #raw_tables t
    ON t.table_name = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = 'dbo'
ORDER BY
    c.TABLE_NAME,
    c.ORDINAL_POSITION;


/* 0c) TRANSLATION TABLOSU KOLON KONTROLU */

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'product_category_name_translation'
ORDER BY ORDINAL_POSITION;


DECLARE
    @tc1 sysname,
    @tc2 sysname,
    @sql_stg nvarchar(max);


SELECT
    @tc1 = MAX(CASE
                    WHEN ORDINAL_POSITION = 1
                    THEN COLUMN_NAME
               END),
    @tc2 = MAX(CASE
                    WHEN ORDINAL_POSITION = 2
                    THEN COLUMN_NAME
               END)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'product_category_name_translation';


DROP TABLE IF EXISTS dbo.stg_category_translation;


SET @sql_stg =
      N'SELECT '
    + N'CAST(' + QUOTENAME(@tc1) + N' AS NVARCHAR(200)) AS product_category_name, '
    + N'CAST(' + QUOTENAME(@tc2) + N' AS NVARCHAR(200)) AS product_category_name_english '
    + N'INTO dbo.stg_category_translation '
    + N'FROM dbo.product_category_name_translation;';

EXEC sys.sp_executesql @sql_stg;

GO


/* =====================================================================
   1) SEHIR ADI TEMIZLEME FONKSIYONU
   ===================================================================== */

CREATE OR ALTER FUNCTION dbo.fn_clean_city
(
    @city       nvarchar(400),
    @strip_tail bit,
    @state      nvarchar(10)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        UPPER(a6.v) AS city_clean
    FROM
    (
        SELECT LOWER(LTRIM(RTRIM(@city))) AS v
    ) a0

    CROSS APPLY
    (
        SELECT
            CASE
                WHEN @strip_tail = 1
                THEN COALESCE(
                        LEFT(
                            a0.v,
                            NULLIF(
                                PATINDEX(N'%[/\,(]%', a0.v),
                                0
                            ) - 1
                        ),
                        a0.v
                     )
                ELSE a0.v
            END AS v
    ) a1

    CROSS APPLY
    (
        SELECT
            TRANSLATE(
                a1.v,

                CONCAT(
                    NCHAR(227),
                    NCHAR(225),
                    NCHAR(224),
                    NCHAR(226),
                    NCHAR(228),
                    NCHAR(231),
                    NCHAR(233),
                    NCHAR(232),
                    NCHAR(234),
                    NCHAR(235),
                    NCHAR(237),
                    NCHAR(236),
                    NCHAR(238),
                    NCHAR(239),
                    NCHAR(243),
                    NCHAR(242),
                    NCHAR(244),
                    NCHAR(245),
                    NCHAR(246),
                    NCHAR(250),
                    NCHAR(249),
                    NCHAR(251),
                    NCHAR(252),
                    NCHAR(241)
                ),

                N'aaaaaceeeeiiiiooooouuuun'
            ) AS v
    ) a2

    CROSS APPLY
    (
        SELECT
            TRANSLATE(
                REPLACE(
                    a2.v,
                    N'%26apos%3b',
                    N' '
                ),

                CONCAT(
                    N'''',
                    N'`',
                    NCHAR(180),
                    NCHAR(8217),
                    N'-',
                    N'.',
                    N',',
                    N'/',
                    N'\'
                ),

                REPLICATE(N' ', 9)
            ) AS v
    ) a3

    CROSS APPLY
    (
        SELECT
            LTRIM(
                RTRIM(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                a3.v,
                                N' ',
                                N'<>'
                            ),
                            N'><',
                            N''
                        ),
                        N'<>',
                        N' '
                    )
                )
            ) AS v
    ) a4

    CROSS APPLY
    (
        SELECT
            LTRIM(
                RTRIM(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            N' ' + a4.v + N' ',
                                            N' d oeste ',
                                            N' doeste '
                                        ),
                                        N' d arco ',
                                        N' darco '
                                    ),
                                    N' d agua ',
                                    N' dagua '
                                ),
                                N' d alianca ',
                                N' dalianca '
                            ),
                            N' d alho ',
                            N' dalho '
                        ),
                        N' d ajuda ',
                        N' dajuda '
                    )
                )
            ) AS v
    ) a5

    CROSS APPLY
    (
        SELECT
            CASE
                WHEN @strip_tail = 1
                 AND @state IS NOT NULL
                 AND LEN(a5.v) > 3
                 AND RIGHT(
                        a5.v,
                        3
                     ) = N' ' + LOWER(@state)
                THEN LTRIM(
                        RTRIM(
                            LEFT(
                                a5.v,
                                LEN(a5.v) - 3
                            )
                        )
                     )
                ELSE a5.v
            END AS v
    ) a6
);

GO


/* =====================================================================
   2) HAM VERI PROFILI
   ===================================================================== */


/* ---------------------------------------------------------------------
   2a) NULL KONTROLU
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS #null_profile;

CREATE TABLE #null_profile
(
    table_name  sysname,
    column_name sysname,
    total_rows  bigint,
    null_count  bigint,
    null_pct    decimal(6,2)
);


DECLARE @sql_null nvarchar(max) = N'';


SELECT
    @sql_null +=
        N'INSERT INTO #null_profile
          (
              table_name,
              column_name,
              total_rows,
              null_count
          )
          SELECT
              '''
        + c.TABLE_NAME
        + N''',
              '''
        + c.COLUMN_NAME
        + N''',
              COUNT_BIG(*),
              SUM(
                  CASE
                      WHEN '
        + QUOTENAME(c.COLUMN_NAME)
        + N' IS NULL
                      THEN 1
                      ELSE 0
                  END
              )
          FROM dbo.'
        + QUOTENAME(c.TABLE_NAME)
        + N';'
        + CHAR(10)
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN #raw_tables t
    ON t.table_name = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = 'dbo';


EXEC sys.sp_executesql @sql_null;


UPDATE #null_profile
SET null_pct =
    100.0 * null_count / NULLIF(total_rows, 0);


SELECT *
FROM #null_profile
WHERE null_count > 0
ORDER BY
    table_name,
    null_count DESC;


/* ---------------------------------------------------------------------
   2b) TAM SATIR DUPLICATE KONTROLU
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS #dup_profile;

CREATE TABLE #dup_profile
(
    table_name   sysname,
    total_rows   bigint,
    distinct_rows bigint
);


DECLARE @sql_dup nvarchar(max) = N'';


SELECT
    @sql_dup +=
        N'INSERT INTO #dup_profile
          SELECT
              '''
        + t.table_name
        + N''',
              COUNT_BIG(*),
              (
                  SELECT COUNT_BIG(*)
                  FROM
                  (
                      SELECT DISTINCT *
                      FROM dbo.'
        + QUOTENAME(t.table_name)
        + N'
                  ) d
              )
          FROM dbo.'
        + QUOTENAME(t.table_name)
        + N';'
        + CHAR(10)
FROM #raw_tables t;


EXEC sys.sp_executesql @sql_dup;


SELECT
    table_name,
    total_rows,
    distinct_rows,
    total_rows - distinct_rows AS duplicate_rows
FROM #dup_profile
ORDER BY table_name;


/* ---------------------------------------------------------------------
   2c) KEY BAZLI DUPLICATE KONTROLU
   --------------------------------------------------------------------- */

SELECT
    'customers (customer_id)' AS key_name,
    COUNT(*) AS duplicated_keys
FROM
(
    SELECT customer_id
    FROM dbo.olist_customers_dataset
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'orders (order_id)',
    COUNT(*)
FROM
(
    SELECT order_id
    FROM dbo.olist_orders_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'products (product_id)',
    COUNT(*)
FROM
(
    SELECT product_id
    FROM dbo.olist_products_dataset
    GROUP BY product_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'sellers (seller_id)',
    COUNT(*)
FROM
(
    SELECT seller_id
    FROM dbo.olist_sellers_dataset
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'order_items (order_id, order_item_id)',
    COUNT(*)
FROM
(
    SELECT
        order_id,
        order_item_id
    FROM dbo.olist_order_items_dataset
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'order_payments (order_id, payment_sequential)',
    COUNT(*)
FROM
(
    SELECT
        order_id,
        payment_sequential
    FROM dbo.olist_order_payments_dataset
    GROUP BY
        order_id,
        payment_sequential
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'order_reviews (review_id, order_id)',
    COUNT(*)
FROM
(
    SELECT
        review_id,
        order_id
    FROM dbo.olist_order_reviews_dataset
    GROUP BY
        review_id,
        order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'BILGI order_reviews (review_id)',
    COUNT(*)
FROM
(
    SELECT review_id
    FROM dbo.olist_order_reviews_dataset
    GROUP BY review_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'BILGI order_reviews (order_id)',
    COUNT(*)
FROM
(
    SELECT order_id
    FROM dbo.olist_order_reviews_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'category_translation (product_category_name)',
    COUNT(*)
FROM
(
    SELECT product_category_name
    FROM dbo.stg_category_translation
    GROUP BY product_category_name
    HAVING COUNT(*) > 1
) d;


/* ---------------------------------------------------------------------
   2d) MANTIKSAL DEGER / VERI KALITESI
   --------------------------------------------------------------------- */

SELECT
    'products: name_length < 0' AS rule_name,
    COUNT(*) AS violation_count
FROM dbo.olist_products_dataset
WHERE product_name_lenght < 0

UNION ALL

SELECT
    'products: description_length < 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_description_lenght < 0

UNION ALL

SELECT
    'products: photos_qty < 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_photos_qty < 0

UNION ALL

SELECT
    'products: weight_g <= 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_weight_g <= 0

UNION ALL

SELECT
    'products: length_cm <= 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_length_cm <= 0

UNION ALL

SELECT
    'products: height_cm <= 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_height_cm <= 0

UNION ALL

SELECT
    'products: width_cm <= 0',
    COUNT(*)
FROM dbo.olist_products_dataset
WHERE product_width_cm <= 0

UNION ALL

SELECT
    'products: kategorisi ceviri tablosunda yok',
    COUNT(*)
FROM dbo.olist_products_dataset p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.stg_category_translation t
      WHERE t.product_category_name = p.product_category_name
  )

UNION ALL

SELECT
    'order_items: price <= 0',
    COUNT(*)
FROM dbo.olist_order_items_dataset
WHERE price <= 0

UNION ALL

SELECT
    'order_items: freight_value < 0',
    COUNT(*)
FROM dbo.olist_order_items_dataset
WHERE freight_value < 0

UNION ALL

SELECT
    'payments: payment_value < 0',
    COUNT(*)
FROM dbo.olist_order_payments_dataset
WHERE payment_value < 0

UNION ALL

SELECT
    'payments: payment_value = 0',
    COUNT(*)
FROM dbo.olist_order_payments_dataset
WHERE payment_value = 0

UNION ALL

SELECT
    'payments: installments < 1',
    COUNT(*)
FROM dbo.olist_order_payments_dataset
WHERE payment_installments < 1

UNION ALL

SELECT
    'payments: payment_type = not_defined',
    COUNT(*)
FROM dbo.olist_order_payments_dataset
WHERE payment_type = 'not_defined'

UNION ALL

SELECT
    'reviews: score 1-5 disinda',
    COUNT(*)
FROM dbo.olist_order_reviews_dataset
WHERE review_score NOT BETWEEN 1 AND 5

UNION ALL

SELECT
    'reviews: bas/son bosluk (title)',
    COUNT(*)
FROM dbo.olist_order_reviews_dataset
WHERE review_comment_title IS NOT NULL
  AND DATALENGTH(review_comment_title)
      <> DATALENGTH(LTRIM(RTRIM(review_comment_title)))

UNION ALL

SELECT
    'reviews: bas/son bosluk (message)',
    COUNT(*)
FROM dbo.olist_order_reviews_dataset
WHERE review_comment_message IS NOT NULL
  AND DATALENGTH(review_comment_message)
      <> DATALENGTH(LTRIM(RTRIM(review_comment_message)))

UNION ALL

SELECT
    'reviews: bos string (title)',
    COUNT(*)
FROM dbo.olist_order_reviews_dataset
WHERE LTRIM(RTRIM(review_comment_title)) = ''

UNION ALL

SELECT
    'reviews: bos string (message)',
    COUNT(*)
FROM dbo.olist_order_reviews_dataset
WHERE LTRIM(RTRIM(review_comment_message)) = ''

UNION ALL

SELECT
    'orders: approved < purchase',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_approved_at < order_purchase_timestamp

UNION ALL

SELECT
    'orders: carrier_date < purchase',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_delivered_carrier_date < order_purchase_timestamp

UNION ALL

SELECT
    'orders: carrier_date < approved',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_delivered_carrier_date < order_approved_at

UNION ALL

SELECT
    'orders: customer_date < purchase',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_delivered_customer_date < order_purchase_timestamp

UNION ALL

SELECT
    'orders: customer_date < carrier_date',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_delivered_customer_date < order_delivered_carrier_date

UNION ALL

SELECT
    'orders: estimated < purchase',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_estimated_delivery_date < order_purchase_timestamp

UNION ALL

SELECT
    'orders: delivered ama teslim tarihi NULL',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL

UNION ALL

SELECT
    'orders: delivered degil ama teslim tarihi dolu',
    COUNT(*)
FROM dbo.olist_orders_dataset
WHERE order_status <> 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


/* 2e) SIPARIS DURUMLARI */

SELECT
    order_status,
    COUNT(*) AS order_count
FROM dbo.olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;


/* =====================================================================
   3) CLEANED TABLOLAR
   ===================================================================== */


/* ---------------------------------------------------------------------
   3.1 CUSTOMERS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_customers_cleaned;

SELECT DISTINCT
    x.customer_id,
    x.customer_unique_id,
    x.customer_zip_code_prefix,
    x.customer_city,
    x.customer_state
INTO dbo.olist_real_customers_cleaned
FROM
(
    SELECT
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,

        CASE
            WHEN fc.city_clean = N'QUILOMETRO 14 DO MUTUM'
             AND UPPER(LTRIM(RTRIM(c.customer_state))) = N'ES'
            THEN N'MUTUM'
            ELSE fc.city_clean
        END AS customer_city,

        UPPER(
            LTRIM(
                RTRIM(c.customer_state)
            )
        ) AS customer_state

    FROM dbo.olist_customers_dataset c

    CROSS APPLY dbo.fn_clean_city(
        c.customer_city,
        0,
        NULL
    ) fc
) x;


/* ---------------------------------------------------------------------
   3.2 GEOLOCATION
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_geolocation_cleaned;

SELECT DISTINCT
    x.geolocation_zip_code_prefix,
    x.geolocation_lat,
    x.geolocation_lng,
    x.geolocation_city,
    x.geolocation_state
INTO dbo.olist_real_geolocation_cleaned
FROM
(
    SELECT
        g.geolocation_zip_code_prefix,
        g.geolocation_lat,
        g.geolocation_lng,

        CASE
            WHEN TRY_CAST(g.geolocation_zip_code_prefix AS int) = 14407
                THEN N'FRANCA'

            WHEN TRY_CAST(g.geolocation_zip_code_prefix AS int) = 7174
                THEN N'GUARULHOS'

            WHEN TRY_CAST(g.geolocation_zip_code_prefix AS int) = 37200
                THEN N'LAVRAS'

            WHEN TRY_CAST(g.geolocation_zip_code_prefix AS int) = 38295
                THEN N'LIMEIRA DO OESTE'

            WHEN fc.city_clean = N'SP'
                THEN N'SAO PAULO'

            WHEN fc.city_clean = N'RJ'
                THEN N'RIO DE JANEIRO'

            WHEN fc.city_clean = N'BH'
                THEN N'BELO HORIZONTE'

            WHEN UPPER(LTRIM(RTRIM(g.geolocation_state))) = N'BA'
             AND fc.city_clean LIKE N'ARRAIAL D%'
                THEN N'ARRAIAL DAJUDA'

            ELSE fc.city_clean
        END AS geolocation_city,

        UPPER(
            LTRIM(
                RTRIM(g.geolocation_state)
            )
        ) AS geolocation_state

    FROM dbo.olist_geolocation_dataset g

    CROSS APPLY dbo.fn_clean_city(
        g.geolocation_city,
        0,
        NULL
    ) fc
) x;


/* ---------------------------------------------------------------------
   3.2b GEOLOCATION ZIP
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_geolocation_zip;

WITH zip_stats AS
(
    SELECT
        geolocation_zip_code_prefix,

        AVG(
            CAST(geolocation_lat AS float)
        ) AS geolocation_lat,

        AVG(
            CAST(geolocation_lng AS float)
        ) AS geolocation_lng,

        COUNT(*) AS point_count

    FROM dbo.olist_real_geolocation_cleaned

    GROUP BY geolocation_zip_code_prefix
),

zip_city AS
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,

        ROW_NUMBER() OVER
        (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY
                COUNT(*) DESC,
                geolocation_city
        ) AS rn

    FROM dbo.olist_real_geolocation_cleaned

    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
)

SELECT
    s.geolocation_zip_code_prefix,
    s.geolocation_lat,
    s.geolocation_lng,
    s.point_count,
    c.geolocation_city,
    c.geolocation_state
INTO dbo.olist_real_geolocation_zip
FROM zip_stats s
JOIN zip_city c
    ON c.geolocation_zip_code_prefix = s.geolocation_zip_code_prefix
   AND c.rn = 1;


/* ---------------------------------------------------------------------
   3.3 SELLERS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_sellers_cleaned;

SELECT DISTINCT
    x.seller_id,
    x.seller_zip_code_prefix,
    x.seller_city,
    x.seller_state
INTO dbo.olist_real_sellers_cleaned
FROM
(
    SELECT
        s.seller_id,
        s.seller_zip_code_prefix,

        CASE
            WHEN s.seller_city LIKE N'%@%'
             AND UPPER(LTRIM(RTRIM(s.seller_state))) = N'PR'
                THEN N'MARINGA'

            WHEN fc.city_clean = N'04482255'
                THEN N'RIO DE JANEIRO'

            WHEN fc.city_clean IN
            (
                N'SP',
                N'SAOPAULO',
                N'SAO PAULO SP'
            )
             AND UPPER(LTRIM(RTRIM(s.seller_state))) = N'SP'
                THEN N'SAO PAULO'

            WHEN fc.city_clean IN
            (
                N'SBC',
                N'SBC SP'
            )
                THEN N'SAO BERNARDO DO CAMPO'

            ELSE fc.city_clean
        END AS seller_city,

        UPPER(
            LTRIM(
                RTRIM(s.seller_state)
            )
        ) AS seller_state

    FROM dbo.olist_sellers_dataset s

    CROSS APPLY dbo.fn_clean_city(
        s.seller_city,
        1,
        UPPER(LTRIM(RTRIM(s.seller_state)))
    ) fc
) x;


/* ---------------------------------------------------------------------
   3.4 PRODUCT CATEGORY TRANSLATION
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_product_category_translation_cleaned;

SELECT DISTINCT
    UPPER(
        LTRIM(
            RTRIM(product_category_name)
        )
    ) AS product_category_name,

    UPPER(
        LTRIM(
            RTRIM(product_category_name_english)
        )
    ) AS product_category_name_english

INTO dbo.olist_real_product_category_translation_cleaned

FROM dbo.stg_category_translation;


INSERT INTO dbo.olist_real_product_category_translation_cleaned
(
    product_category_name,
    product_category_name_english
)
SELECT
    v.pt,
    v.en
FROM
(
    VALUES
        (
            N'PC_GAMER',
            N'PC_GAMER'
        ),
        (
            N'PORTATEIS_COZINHA_E_PREPARADORES_DE_ALIMENTOS',
            N'PORTABLE_KITCHEN_AND_FOOD_PREPARERS'
        )
) v(pt, en)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_product_category_translation_cleaned t
    WHERE t.product_category_name = v.pt
);


/* ---------------------------------------------------------------------
   3.5 PRODUCTS
   ---------------------------------------------------------------------

   ONEMLI:
   product_id kaynak tabloda NVARCHAR(MAX).
   INDEX icin NVARCHAR(MAX) kullanilamaz.

   Bu nedenle burada kalici olarak:
   CAST(product_id AS NVARCHAR(64))
   kullaniliyor.

   Boylece tablo her yeniden olusturuldugunda tekrar NVARCHAR(MAX)
   olmayacak.
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_products_cleaned;

SELECT DISTINCT

    CAST(
        p.product_id AS NVARCHAR(64)
    ) AS product_id,

    k.category_pt AS product_category_name,

    COALESCE(
        t.product_category_name_english,
        N'UNKNOWN'
    ) AS product_category_name_english,

    p.product_name_lenght AS product_name_length,

    p.product_description_lenght AS product_description_length,

    p.product_photos_qty,

    p.product_weight_g,

    p.product_length_cm,

    p.product_height_cm,

    p.product_width_cm,

    CASE
        WHEN p.product_weight_g <= 0
          OR p.product_length_cm <= 0
          OR p.product_height_cm <= 0
          OR p.product_width_cm <= 0
        THEN 1
        ELSE 0
    END AS has_invalid_dimensions

INTO dbo.olist_real_products_cleaned

FROM dbo.olist_products_dataset p

CROSS APPLY
(
    SELECT
        NULLIF(
            UPPER(
                LTRIM(
                    RTRIM(p.product_category_name)
                )
            ),
            N''
        ) AS category_pt
) k

LEFT JOIN dbo.olist_real_product_category_translation_cleaned t
    ON t.product_category_name = k.category_pt;


/* ---------------------------------------------------------------------
   3.6 ORDERS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_orders_cleaned;

SELECT DISTINCT

    order_id,

    customer_id,

    UPPER(
        LTRIM(
            RTRIM(order_status)
        )
    ) AS order_status,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    CASE
        WHEN order_approved_at < order_purchase_timestamp
          OR order_delivered_carrier_date < order_purchase_timestamp
          OR order_delivered_carrier_date < order_approved_at
          OR order_delivered_customer_date < order_purchase_timestamp
          OR order_delivered_customer_date < order_delivered_carrier_date
          OR order_estimated_delivery_date < order_purchase_timestamp
        THEN 1
        ELSE 0
    END AS date_anomaly_flag

INTO dbo.olist_real_orders_cleaned

FROM dbo.olist_orders_dataset;


/* ---------------------------------------------------------------------
   3.7 ORDER ITEMS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_order_items_cleaned;

SELECT DISTINCT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
INTO dbo.olist_real_order_items_cleaned
FROM dbo.olist_order_items_dataset;


/* ---------------------------------------------------------------------
   3.8 ORDER PAYMENTS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_order_payments_cleaned;

SELECT DISTINCT

    order_id,

    payment_sequential,

    UPPER(
        LTRIM(
            RTRIM(payment_type)
        )
    ) AS payment_type,

    payment_installments,
    payment_value

INTO dbo.olist_real_order_payments_cleaned

FROM dbo.olist_order_payments_dataset;


/* ---------------------------------------------------------------------
   3.9 ORDER REVIEWS
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS dbo.olist_real_order_reviews_cleaned;

SELECT DISTINCT

    review_id,
    order_id,
    review_score,

    NULLIF(
        LTRIM(RTRIM(review_comment_title)),
        ''
    ) AS review_comment_title,

    NULLIF(
        LTRIM(RTRIM(review_comment_message)),
        ''
    ) AS review_comment_message,

    review_creation_date,
    review_answer_timestamp

INTO dbo.olist_real_order_reviews_cleaned

FROM dbo.olist_order_reviews_dataset;


/* =====================================================================
   4) INDEXLER
   ===================================================================== */


/* CUSTOMERS: customer_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_customers_cleaned_customer_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_customers_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_customers_cleaned_customer_id

    ON dbo.olist_real_customers_cleaned
    (
        customer_id
    );

END;


/* CUSTOMERS: customer_unique_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_customers_cleaned_unique_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_customers_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_customers_cleaned_unique_id

    ON dbo.olist_real_customers_cleaned
    (
        customer_unique_id
    );

END;


/* CUSTOMERS: ZIP */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_customers_cleaned_zip'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_customers_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_customers_cleaned_zip

    ON dbo.olist_real_customers_cleaned
    (
        customer_zip_code_prefix
    );

END;


/* GEOLOCATION ZIP */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_geo_zip_zip'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_geolocation_zip'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_geo_zip_zip

    ON dbo.olist_real_geolocation_zip
    (
        geolocation_zip_code_prefix
    );

END;


/* SELLERS */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_sellers_cleaned_seller_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_sellers_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_sellers_cleaned_seller_id

    ON dbo.olist_real_sellers_cleaned
    (
        seller_id
    );

END;


/* PRODUCTS */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_products_cleaned_product_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_products_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_products_cleaned_product_id

    ON dbo.olist_real_products_cleaned
    (
        product_id
    );

END;


/* PRODUCT CATEGORY TRANSLATION */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_translation_cleaned_pt'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_product_category_translation_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_translation_cleaned_pt

    ON dbo.olist_real_product_category_translation_cleaned
    (
        product_category_name
    );

END;


/* ORDERS */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_orders_cleaned_order_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_orders_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_orders_cleaned_order_id

    ON dbo.olist_real_orders_cleaned
    (
        order_id
    );

END;


/* ORDERS: customer_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_orders_cleaned_customer_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_orders_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_orders_cleaned_customer_id

    ON dbo.olist_real_orders_cleaned
    (
        customer_id
    );

END;


/* ORDER ITEMS: order_id + order_item_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_items_cleaned_order_item'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_order_items_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_items_cleaned_order_item

    ON dbo.olist_real_order_items_cleaned
    (
        order_id,
        order_item_id
    );

END;


/* ORDER ITEMS: product_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_items_cleaned_product_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_order_items_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_items_cleaned_product_id

    ON dbo.olist_real_order_items_cleaned
    (
        product_id
    );

END;


/* ORDER ITEMS: seller_id */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_items_cleaned_seller_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_order_items_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_items_cleaned_seller_id

    ON dbo.olist_real_order_items_cleaned
    (
        seller_id
    );

END;


/* ORDER PAYMENTS */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ux_payments_cleaned_order_seq'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_order_payments_cleaned'
          )
)
BEGIN

    CREATE UNIQUE INDEX ux_payments_cleaned_order_seq

    ON dbo.olist_real_order_payments_cleaned
    (
        order_id,
        payment_sequential
    );

END;


/* ORDER REVIEWS */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_reviews_cleaned_order_id'
      AND object_id =
          OBJECT_ID(
              'dbo.olist_real_order_reviews_cleaned'
          )
)
BEGIN

    CREATE INDEX ix_reviews_cleaned_order_id

    ON dbo.olist_real_order_reviews_cleaned
    (
        order_id
    );

END;


/* =====================================================================
   5) CLEANED TABLOLARDA DOGRULAMA
   ===================================================================== */


/* 5a) SATIR SAYISI MUTABAKATI */

WITH recon AS
(
    SELECT
        'customers' AS table_name,
        (
            SELECT COUNT(*)
            FROM dbo.olist_customers_dataset
        ) AS raw_rows,
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_customers_cleaned
        ) AS cleaned_rows

    UNION ALL

    SELECT
        'geolocation',
        (
            SELECT COUNT(*)
            FROM dbo.olist_geolocation_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_geolocation_cleaned
        )

    UNION ALL

    SELECT
        'sellers',
        (
            SELECT COUNT(*)
            FROM dbo.olist_sellers_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_sellers_cleaned
        )

    UNION ALL

    SELECT
        'category_translation',
        (
            SELECT COUNT(*)
            FROM dbo.product_category_translation
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_product_category_translation_cleaned
        )

    UNION ALL

    SELECT
        'products',
        (
            SELECT COUNT(*)
            FROM dbo.olist_products_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_products_cleaned
        )

    UNION ALL

    SELECT
        'orders',
        (
            SELECT COUNT(*)
            FROM dbo.olist_orders_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_orders_cleaned
        )

    UNION ALL

    SELECT
        'order_items',
        (
            SELECT COUNT(*)
            FROM dbo.olist_order_items_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_order_items_cleaned
        )

    UNION ALL

    SELECT
        'order_payments',
        (
            SELECT COUNT(*)
            FROM dbo.olist_order_payments_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_order_payments_cleaned
        )

    UNION ALL

    SELECT
        'order_reviews',
        (
            SELECT COUNT(*)
            FROM dbo.olist_order_reviews_dataset
        ),
        (
            SELECT COUNT(*)
            FROM dbo.olist_real_order_reviews_cleaned
        )
)

SELECT
    table_name,
    raw_rows,
    cleaned_rows,
    raw_rows - cleaned_rows AS removed_rows
FROM recon
ORDER BY table_name;


/* 5b) OZEL KARAKTER / KUCUK HARF KONTROLU */

SELECT
    'customers.city' AS check_name,
    COUNT(*) AS offending_rows
FROM dbo.olist_real_customers_cleaned
WHERE customer_city COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z ]%'

UNION ALL

SELECT
    'geolocation.city',
    COUNT(*)
FROM dbo.olist_real_geolocation_cleaned
WHERE geolocation_city COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z ]%'

UNION ALL

SELECT
    'sellers.city',
    COUNT(*)
FROM dbo.olist_real_sellers_cleaned
WHERE seller_city COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z ]%'

UNION ALL

SELECT
    'customers.state',
    COUNT(*)
FROM dbo.olist_real_customers_cleaned
WHERE customer_state COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z]%'

UNION ALL

SELECT
    'sellers.state',
    COUNT(*)
FROM dbo.olist_real_sellers_cleaned
WHERE seller_state COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z]%'

UNION ALL

SELECT
    'geolocation.state',
    COUNT(*)
FROM dbo.olist_real_geolocation_cleaned
WHERE geolocation_state COLLATE Latin1_General_100_BIN2
      LIKE '%[^A-Z]%';


/* 5c) REFERANS BUTUNLUGU */

SELECT
    'orders -> customers yok' AS check_name,
    COUNT(*) AS row_count
FROM dbo.olist_real_orders_cleaned o
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_customers_cleaned c
    WHERE c.customer_id = o.customer_id
)

UNION ALL

SELECT
    'order_items -> orders yok',
    COUNT(*)
FROM dbo.olist_real_order_items_cleaned i
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_orders_cleaned o
    WHERE o.order_id = i.order_id
)

UNION ALL

SELECT
    'order_items -> products yok',
    COUNT(*)
FROM dbo.olist_real_order_items_cleaned i
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_products_cleaned p
    WHERE p.product_id = i.product_id
)

UNION ALL

SELECT
    'order_items -> sellers yok',
    COUNT(*)
FROM dbo.olist_real_order_items_cleaned i
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_sellers_cleaned s
    WHERE s.seller_id = i.seller_id
)

UNION ALL

SELECT
    'order_payments -> orders yok',
    COUNT(*)
FROM dbo.olist_real_order_payments_cleaned p
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_orders_cleaned o
    WHERE o.order_id = p.order_id
)

UNION ALL

SELECT
    'order_reviews -> orders yok',
    COUNT(*)
FROM dbo.olist_real_order_reviews_cleaned r
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_orders_cleaned o
    WHERE o.order_id = r.order_id
)

UNION ALL

SELECT
    'BILGI: kalemi olmayan siparis',
    COUNT(*)
FROM dbo.olist_real_orders_cleaned o
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_order_items_cleaned i
    WHERE i.order_id = o.order_id
)

UNION ALL

SELECT
    'BILGI: odemesi olmayan siparis',
    COUNT(*)
FROM dbo.olist_real_orders_cleaned o
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_order_payments_cleaned p
    WHERE p.order_id = o.order_id
)

UNION ALL

SELECT
    'BILGI: yorumu olmayan siparis',
    COUNT(*)
FROM dbo.olist_real_orders_cleaned o
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_order_reviews_cleaned r
    WHERE r.order_id = o.order_id
)

UNION ALL

SELECT
    'BILGI: birden fazla yorumu olan siparis',
    COUNT(*)
FROM
(
    SELECT order_id
    FROM dbo.olist_real_order_reviews_cleaned
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT
    'BILGI: customers zip geolocation''da yok',
    COUNT(*)
FROM dbo.olist_real_customers_cleaned c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_geolocation_zip g
    WHERE g.geolocation_zip_code_prefix =
          c.customer_zip_code_prefix
)

UNION ALL

SELECT
    'BILGI: sellers zip geolocation''da yok',
    COUNT(*)
FROM dbo.olist_real_sellers_cleaned s
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.olist_real_geolocation_zip g
    WHERE g.geolocation_zip_code_prefix =
          s.seller_zip_code_prefix
)

UNION ALL

SELECT
    'BILGI: customer eyaleti ile zip eyaleti farkli',
    COUNT(*)
FROM dbo.olist_real_customers_cleaned c
JOIN dbo.olist_real_geolocation_zip g
    ON g.geolocation_zip_code_prefix =
       c.customer_zip_code_prefix
WHERE g.geolocation_state <> c.customer_state

UNION ALL

SELECT
    'BILGI: date_anomaly_flag = 1 siparis',
    COUNT(*)
FROM dbo.olist_real_orders_cleaned
WHERE date_anomaly_flag = 1

UNION ALL

SELECT
    'BILGI: has_invalid_dimensions = 1 urun',
    COUNT(*)
FROM dbo.olist_real_products_cleaned
WHERE has_invalid_dimensions = 1

UNION ALL

SELECT
    'BILGI: kategorisi UNKNOWN urun',
    COUNT(*)
FROM dbo.olist_real_products_cleaned
WHERE product_category_name_english = N'UNKNOWN';

GO


/* =====================================================================
   6) ANALIZ VIEW'LARI
   ===================================================================== */


/* 6a) SIPARIS BASINA TEK YORUM */

CREATE OR ALTER VIEW dbo.vw_order_reviews_latest
AS

SELECT
    order_id,
    review_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM
(
    SELECT
        r.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY r.order_id

            ORDER BY
                r.review_answer_timestamp DESC,
                r.review_creation_date DESC,
                r.review_id
        ) AS rn

    FROM dbo.olist_real_order_reviews_cleaned r
) x

WHERE x.rn = 1;

GO


/* 6b) ORDER ITEMS ENRICHED */

CREATE OR ALTER VIEW dbo.vw_order_items_enriched
AS

SELECT

    i.order_id,
    i.order_item_id,

    o.order_status,
    o.order_purchase_timestamp,

    YEAR(
        o.order_purchase_timestamp
    ) AS purchase_year,

    MONTH(
        o.order_purchase_timestamp
    ) AS purchase_month,

    o.order_approved_at,
    o.customer_id,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    i.product_id,

    p.product_category_name,

    COALESCE(
        p.product_category_name_english,
        N'UNKNOWN'
    ) AS product_category_name_english,

    i.seller_id,

    s.seller_city,
    s.seller_state,

    i.shipping_limit_date,
    i.price,
    i.freight_value,

    i.price + i.freight_value AS item_total

FROM dbo.olist_real_order_items_cleaned i

LEFT JOIN dbo.olist_real_orders_cleaned o
    ON o.order_id = i.order_id

LEFT JOIN dbo.olist_real_customers_cleaned c
    ON c.customer_id = o.customer_id

LEFT JOIN dbo.olist_real_products_cleaned p
    ON p.product_id = i.product_id

LEFT JOIN dbo.olist_real_sellers_cleaned s
    ON s.seller_id = i.seller_id;

GO


/* 6c) ORDER SUMMARY */

CREATE OR ALTER VIEW dbo.vw_order_summary
AS

SELECT

    o.order_id,
    o.customer_id,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    o.order_status,
    o.order_purchase_timestamp,

    YEAR(
        o.order_purchase_timestamp
    ) AS purchase_year,

    MONTH(
        o.order_purchase_timestamp
    ) AS purchase_month,

    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.date_anomaly_flag,

    COALESCE(
        it.item_count,
        0
    ) AS item_count,

    it.distinct_products,
    it.distinct_sellers,
    it.items_price,
    it.freight_total,

    it.items_price + it.freight_total
        AS order_value_with_freight,

    pay.payment_total,
    pay.payment_count,
    pay.max_installments,
    pay.payment_type_count,

    r.review_score,

    DATEDIFF(
        DAY,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ) AS delivery_days,

    DATEDIFF(
        DAY,
        o.order_estimated_delivery_date,
        o.order_delivered_customer_date
    ) AS delivery_delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN NULL

        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
            THEN 1

        ELSE 0
    END AS is_late

FROM dbo.olist_real_orders_cleaned o

LEFT JOIN dbo.olist_real_customers_cleaned c
    ON c.customer_id = o.customer_id

LEFT JOIN
(
    SELECT

        order_id,

        COUNT(*) AS item_count,

        COUNT(
            DISTINCT product_id
        ) AS distinct_products,

        COUNT(
            DISTINCT seller_id
        ) AS distinct_sellers,

        SUM(price) AS items_price,

        SUM(freight_value) AS freight_total

    FROM dbo.olist_real_order_items_cleaned

    GROUP BY order_id

) it
    ON it.order_id = o.order_id

LEFT JOIN
(
    SELECT

        order_id,

        SUM(payment_value) AS payment_total,

        COUNT(*) AS payment_count,

        MAX(payment_installments) AS max_installments,

        COUNT(
            DISTINCT payment_type
        ) AS payment_type_count

    FROM dbo.olist_real_order_payments_cleaned

    GROUP BY order_id

) pay
    ON pay.order_id = o.order_id

LEFT JOIN dbo.vw_order_reviews_latest r
    ON r.order_id = o.order_id;

GO


/* 6d) CUSTOMER SUMMARY */

CREATE OR ALTER VIEW dbo.vw_customer_summary
AS

SELECT

    customer_unique_id,

    COUNT(*) AS order_count,

    SUM(
        COALESCE(
            payment_total,
            0
        )
    ) AS total_payment,

    MIN(
        order_purchase_timestamp
    ) AS first_order_date,

    MAX(
        order_purchase_timestamp
    ) AS last_order_date

FROM dbo.vw_order_summary

WHERE order_status <> N'CANCELED'

GROUP BY customer_unique_id;

GO


/* =====================================================================
   7) HIZLI TESTLER
   ===================================================================== */


/* 7a) CLEANED ORDERS = VIEW ORDERS */

SELECT

    (
        SELECT COUNT(*)
        FROM dbo.olist_real_orders_cleaned
    ) AS orders_cleaned,

    (
        SELECT COUNT(*)
        FROM dbo.vw_order_summary
    ) AS order_summary_rows;


/* 7b) TOPLAM URUN GELIRI */

SELECT

    (
        SELECT SUM(price)
        FROM dbo.olist_real_order_items_cleaned
    ) AS items_table_revenue,

    (
        SELECT SUM(items_price)
        FROM dbo.vw_order_summary
    ) AS order_summary_revenue,

    (
        SELECT SUM(price)
        FROM dbo.vw_order_items_enriched
    ) AS items_view_revenue;


/* 7c) SIPARIS DURUMLARI */

SELECT
    order_status,
    COUNT(*) AS order_count
FROM dbo.olist_real_orders_cleaned
GROUP BY order_status
ORDER BY order_count DESC;
--SİPARİŞ RAPORU--
--(TOPLAM SİPARİŞ SAYISI- 99.441)
SELECT DISTINCT (order_id)
from "olist_orders_dataset"

-- BAŞARIYLA TEST EDİLEN SİPARİŞ RAPORU
-- (BENZERSİZ SİPARİŞ SAYISI-96.478)

SELECT DISTINCT order_id
FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered';

-- TESLİM EDİLMEYEN SİPARİŞ RAPORU
-- (BENZERSİZ SİPARİŞ SAYISI- 2.963)

SELECT DISTINCT order_id
FROM dbo.olist_orders_dataset
WHERE order_status <> 'delivered';
/* =========================================================
   TESLİM EDİLMEYEN SİPARİŞLERİN DURUM KIRILIMI
   ========================================================= */

SELECT
    order_status,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM dbo.olist_orders_dataset
WHERE order_status <> 'delivered'
GROUP BY order_status
ORDER BY number_of_orders DESC;

/* =========================================================
   GÜNLÜK ALINAN SİPARİŞ ADEDİ
   EN ÇOK SİPARİŞ ALINAN GÜN EN ÜSTTE
   ========================================================= */

SELECT
    CAST(order_purchase_timestamp AS DATE) AS order_date,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM dbo.olist_orders_dataset
GROUP BY CAST(order_purchase_timestamp AS DATE)
ORDER BY number_of_orders DESC;


/* 7d) EN COK SIPARIS BULUNAN ILK 5 MUSTERI EYALATI */

SELECT TOP (5)

    customer_state,

    COUNT(*) AS number_of_orders

FROM dbo.vw_order_summary

GROUP BY customer_state

ORDER BY number_of_orders DESC;
/* 7di) EN AZ SIPARIS BULUNAN ILK 5 MUSTERI EYALATI */

SELECT TOP (5)

    customer_state,

    COUNT(*) AS number_of_orders

FROM dbo.vw_order_summary

GROUP BY customer_state

ORDER BY number_of_orders ASC;


/* 7e) EN COK SIPARIS BULUNAN ILK 5 MUSTERI EYALATI
       SADECE IPTAL EDILMEMIS SIPARISLER */

SELECT TOP (5)

    c.customer_state,

    COUNT(DISTINCT o.order_id) AS order_count

FROM dbo.olist_real_orders_cleaned o

JOIN dbo.olist_real_customers_cleaned c
    ON c.customer_id = o.customer_id

WHERE o.order_status <> N'CANCELED'

GROUP BY c.customer_state

ORDER BY order_count DESC;

/* =========================================================
   7f) EN ÇOK SİPARİŞE SAHİP İLK 10 MÜŞTERİ ŞEHRİ
   ========================================================= */

SELECT TOP 10
    customer_city AS sehir,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM dbo.vw_order_summary
GROUP BY customer_city
ORDER BY number_of_orders DESC;
/* =========================================================
   7g) EN AZ SİPARİŞE SAHİP İLK 10 MÜŞTERİ ŞEHRİ
   ========================================================= */


SELECT TOP 10
    customer_city AS city,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM dbo.vw_order_summary
GROUP BY customer_city
ORDER BY number_of_orders ASC;

/* 7h) SİPARİŞ SAYISI 500'DEN AZ OLAN ŞEHİRLER */

SELECT
    customer_city AS city,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM dbo.vw_order_summary
GROUP BY customer_city
HAVING COUNT(DISTINCT order_id) < 500
ORDER BY number_of_orders ASC;


/* =====================================================================
   8) SON KONTROL - PRODUCT_ID TIPI
   ===================================================================== */

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'olist_real_products_cleaned'
  AND COLUMN_NAME = 'product_id';


/* =====================================================================
   9) SON KONTROL - OLUSTURULAN CLEANED TABLOLAR
   ===================================================================== */

SELECT
    name AS table_name
FROM sys.tables
WHERE name IN
(
    'olist_real_customers_cleaned',
    'olist_real_geolocation_cleaned',
    'olist_real_geolocation_zip',
    'olist_real_sellers_cleaned',
    'olist_real_product_category_translation_cleaned',
    'olist_real_products_cleaned',
    'olist_real_orders_cleaned',
    'olist_real_order_items_cleaned',
    'olist_real_order_payments_cleaned',
    'olist_real_order_reviews_cleaned'
)
ORDER BY name;


/* =====================================================================
   10) SON KONTROL - VIEWLER
   ===================================================================== */

SELECT
    name AS view_name
FROM sys.views
WHERE name IN
(
    'vw_order_reviews_latest',
    'vw_order_items_enriched',
    'vw_order_summary',
    'vw_customer_summary'
)
ORDER BY name;


