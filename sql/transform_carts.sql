USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

SELECT DATA
FROM ECOMMERCE_DB.RAW.CARTS_RAW
LIMIT 3;

SELECT
    DATA:id::INTEGER AS cart_id,
    DATA:userId::INTEGER AS user_id,
    DATA:date::TIMESTAMP_NTZ AS cart_date,
    DATA:products AS products
FROM ECOMMERCE_DB.RAW.CARTS_RAW;

SELECT
    c.DATA:id::INTEGER AS cart_id,
    c.DATA:userId::INTEGER AS user_id,
    c.DATA:date::TIMESTAMP_NTZ AS cart_date,

    f.VALUE:productId::INTEGER AS product_id,
    f.VALUE:quantity::INTEGER AS quantity

FROM ECOMMERCE_DB.RAW.CARTS_RAW c,
LATERAL FLATTEN(INPUT => c.DATA:products) f;

-- ============================================
-- STEP 4: CART DATA QUALITY CHECKS
-- ============================================

WITH carts AS (
    SELECT
        DATA:id::INTEGER AS cart_id,
        DATA:userId::INTEGER AS user_id,
        DATA:date::TIMESTAMP_NTZ AS cart_date
    FROM ECOMMERCE_DB.RAW.CARTS_RAW
)

SELECT
    COUNT(*) AS total_carts,
    COUNT_IF(cart_id IS NULL) AS missing_cart_id,
    COUNT_IF(user_id IS NULL) AS missing_user_id,
    COUNT_IF(cart_date IS NULL) AS missing_cart_date,
    COUNT(DISTINCT cart_id) AS unique_cart_ids,
    COUNT(*) - COUNT(DISTINCT cart_id) AS duplicate_cart_ids
FROM carts;

-- ============================================
-- STEP 5: CART PRODUCT DATA QUALITY CHECKS
-- ============================================

WITH flattened_carts AS (
    SELECT
        c.DATA:id::INTEGER AS cart_id,
        c.DATA:userId::INTEGER AS user_id,
        c.DATA:date::TIMESTAMP_NTZ AS cart_date,
        f.VALUE:productId::INTEGER AS product_id,
        f.VALUE:quantity::INTEGER AS quantity
    FROM ECOMMERCE_DB.RAW.CARTS_RAW c,
    LATERAL FLATTEN(INPUT => c.DATA:products) f
)

SELECT
    COUNT(*) AS total_cart_products,
    COUNT_IF(cart_id IS NULL) AS missing_cart_id,
    COUNT_IF(user_id IS NULL) AS missing_user_id,
    COUNT_IF(cart_date IS NULL) AS missing_cart_date,
    COUNT_IF(product_id IS NULL) AS missing_product_id,
    COUNT_IF(quantity IS NULL) AS missing_quantity,
    COUNT_IF(quantity <= 0) AS invalid_quantity,
    COUNT(DISTINCT cart_id) AS unique_carts,
    COUNT(DISTINCT product_id) AS unique_products
FROM flattened_carts;

-- ============================================
-- STEP 6: PREVIEW CLEANED CARTS
-- ============================================

WITH carts AS (
    SELECT
        DATA:id::INTEGER AS cart_id,
        DATA:userId::INTEGER AS user_id,
        DATA:date::TIMESTAMP_NTZ AS cart_date,
        DATA:products AS products
    FROM ECOMMERCE_DB.RAW.CARTS_RAW
),

flattened_carts AS (
    SELECT
        c.cart_id,
        c.user_id,
        c.cart_date,
        f.VALUE:productId::INTEGER AS product_id,
        f.VALUE:quantity::INTEGER AS quantity
    FROM carts c,
    LATERAL FLATTEN(INPUT => c.products) f
),

cleaned_carts AS (
    SELECT
        cart_id,
        user_id,
        cart_date,
        product_id,
        quantity,
        ROW_NUMBER() OVER (
            PARTITION BY cart_id, product_id
            ORDER BY cart_id
        ) AS row_num
    FROM flattened_carts
    WHERE cart_id IS NOT NULL
      AND user_id IS NOT NULL
      AND cart_date IS NOT NULL
      AND product_id IS NOT NULL
      AND quantity > 0
)

SELECT
    cart_id,
    user_id,
    cart_date,
    product_id,
    quantity
FROM cleaned_carts
WHERE row_num = 1;

-- ============================================
-- STEP 7: CREATE FINAL CARTS TABLE
-- ============================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.CARTS AS

WITH carts AS (
    SELECT
        DATA:id::INTEGER AS cart_id,
        DATA:userId::INTEGER AS user_id,
        DATA:date::TIMESTAMP_NTZ AS cart_date,
        DATA:products AS products
    FROM ECOMMERCE_DB.RAW.CARTS_RAW
),

flattened_carts AS (
    SELECT
        c.cart_id,
        c.user_id,
        c.cart_date,
        f.VALUE:productId::INTEGER AS product_id,
        f.VALUE:quantity::INTEGER AS quantity
    FROM carts c,
    LATERAL FLATTEN(INPUT => c.products) f
),

cleaned_carts AS (
    SELECT
        cart_id,
        user_id,
        cart_date,
        product_id,
        quantity,
        ROW_NUMBER() OVER (
            PARTITION BY cart_id, product_id
            ORDER BY cart_id
        ) AS row_num
    FROM flattened_carts
    WHERE cart_id IS NOT NULL
      AND user_id IS NOT NULL
      AND cart_date IS NOT NULL
      AND product_id IS NOT NULL
      AND quantity > 0
)

SELECT
    cart_id,
    user_id,
    cart_date,
    product_id,
    quantity
FROM cleaned_carts
WHERE row_num = 1;

-- ============================================
-- STEP 8: VALIDATE FINAL CARTS TABLE
-- ============================================

-- Check total rows
SELECT COUNT(*) AS total_cart_products
FROM ECOMMERCE_DB.ANALYTICS.CARTS;

-- Preview final data
SELECT *
FROM ECOMMERCE_DB.ANALYTICS.CARTS
ORDER BY cart_id, product_id;

-- Check duplicate cart-product combinations
SELECT
    cart_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM ECOMMERCE_DB.ANALYTICS.CARTS
GROUP BY cart_id, product_id
HAVING COUNT(*) > 1;

-- Check missing values
SELECT
    COUNT_IF(cart_id IS NULL) AS missing_cart_id,
    COUNT_IF(user_id IS NULL) AS missing_user_id,
    COUNT_IF(cart_date IS NULL) AS missing_cart_date,
    COUNT_IF(product_id IS NULL) AS missing_product_id,
    COUNT_IF(quantity IS NULL OR quantity <= 0) AS invalid_quantity
FROM ECOMMERCE_DB.ANALYTICS.CARTS;

SHOW TABLES IN SCHEMA ECOMMERCE_DB.ANALYTICS;