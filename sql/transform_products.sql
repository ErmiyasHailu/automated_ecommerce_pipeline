USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

SELECT
    DATA:id,
    DATA:title,
    DATA:price,
    DATA:category
FROM PRODUCTS_RAW
LIMIT 10;

SELECT
    DATA:id::INTEGER AS product_id,
    DATA:title::VARCHAR AS product_name,
    DATA:price::NUMBER(10,2) AS price,
    DATA:category::VARCHAR AS category
FROM PRODUCTS_RAW
LIMIT 10;

-- ============================================
-- STEP 3: DATA QUALITY CHECKS
-- Purpose: Identify data quality issues
-- ============================================

-- Create a reusable dataset for quality checks


-- ============================================
-- E-COMMERCE DATA PIPELINE
-- STEP 3: DATA QUALITY CHECKS
-- Table: PRODUCTS_RAW
-- Purpose: Identify data quality issues
-- ============================================

USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;


-- STEP 3.1: Extract and convert JSON fields
-- Create a CTE to reuse the extracted product data
-- within the quality-check query.

WITH products AS (

    SELECT
        DATA:id::INTEGER AS product_id,
        DATA:title::VARCHAR AS product_name,
        DATA:price::NUMBER(10,2) AS price,
        DATA:category::VARCHAR AS category

    FROM PRODUCTS_RAW

)


-- STEP 3.2: Run all data quality checks

SELECT

    -- Total number of records
    COUNT(*) AS total_records,

    -- Check missing values
    COUNT_IF(product_id IS NULL) AS missing_product_id,
    COUNT_IF(product_name IS NULL) AS missing_product_name,
    COUNT_IF(price IS NULL) AS missing_price,
    COUNT_IF(category IS NULL) AS missing_category,

    -- Check invalid values
    COUNT_IF(price <= 0) AS invalid_price,
    COUNT_IF(TRIM(product_name) = '') AS empty_product_name,
    COUNT_IF(TRIM(category) = '') AS empty_category,

    -- Check duplicate product IDs
    COUNT(DISTINCT product_id) AS unique_product_ids,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_product_ids

FROM products;



-- ============================================
-- STEP 4: DATA CLEANING AND STANDARDIZATION
-- Table: PRODUCTS_RAW
-- Purpose: Prepare clean product data
-- ============================================

-- STEP 5: Create ANALYTICS schema

CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- ============================================
-- STEP 5.2: CREATE FINAL PRODUCTS TABLE
-- Purpose: Store cleaned and transformed data
-- ============================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.PRODUCTS AS

WITH products AS (

    SELECT
        DATA:id::INTEGER AS product_id,
        DATA:title::VARCHAR AS product_name,
        DATA:price::NUMBER(10,2) AS price,
        DATA:category::VARCHAR AS category
    FROM ECOMMERCE_DB.RAW.PRODUCTS_RAW

),

cleaned_products AS (

    SELECT
        product_id,
        INITCAP(TRIM(product_name)) AS product_name,
        price,
        INITCAP(TRIM(category)) AS category,

        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY product_id
        ) AS row_num

    FROM products

    WHERE product_id IS NOT NULL
      AND product_name IS NOT NULL
      AND TRIM(product_name) <> ''
      AND price > 0
      AND category IS NOT NULL
      AND TRIM(category) <> ''

)

SELECT
    product_id,
    product_name,
    price,
    category
FROM cleaned_products
WHERE row_num = 1;

-- ============================================
-- STEP 6: VALIDATE FINAL PRODUCTS TABLE
-- Purpose: Verify transformed data
-- ============================================

-- Check total records
SELECT COUNT(*) AS total_products
FROM ECOMMERCE_DB.ANALYTICS.PRODUCTS;


-- Preview transformed data
SELECT *
FROM ECOMMERCE_DB.ANALYTICS.PRODUCTS
ORDER BY product_id;


-- Check for duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM ECOMMERCE_DB.ANALYTICS.PRODUCTS
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check for missing values
SELECT
    COUNT_IF(product_id IS NULL) AS missing_product_id,
    COUNT_IF(product_name IS NULL) AS missing_product_name,
    COUNT_IF(price IS NULL) AS missing_price,
    COUNT_IF(category IS NULL) AS missing_category
FROM ECOMMERCE_DB.ANALYTICS.PRODUCTS;
