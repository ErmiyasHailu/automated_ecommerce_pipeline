USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

SELECT
    DATA
FROM ECOMMERCE_DB.RAW.USERS_RAW
LIMIT 3;

-- ============================================
-- STEP 4: USER DATA QUALITY CHECKS
-- ============================================

WITH users AS (
    SELECT
        DATA:id::INTEGER AS user_id,
        DATA:name:firstname::VARCHAR AS first_name,
        DATA:name:lastname::VARCHAR AS last_name,
        DATA:email::VARCHAR AS email,
        DATA:username::VARCHAR AS username,
        DATA:phone::VARCHAR AS phone,
        DATA:address:city::VARCHAR AS city,
        DATA:address:street::VARCHAR AS street,
        DATA:address:number::INTEGER AS address_number,
        DATA:address:zipcode::VARCHAR AS zip_code
    FROM ECOMMERCE_DB.RAW.USERS_RAW
)

SELECT
    COUNT(*) AS total_users,
    COUNT_IF(user_id IS NULL) AS missing_user_id,
    COUNT_IF(first_name IS NULL) AS missing_first_name,
    COUNT_IF(last_name IS NULL) AS missing_last_name,
    COUNT_IF(email IS NULL) AS missing_email,
    COUNT_IF(username IS NULL) AS missing_username,
    COUNT_IF(city IS NULL) AS missing_city,
    COUNT_IF(user_id IS NOT NULL)
        - COUNT(DISTINCT user_id) AS duplicate_user_ids
FROM users;

-- STEP 5: PREVIEW CLEANED USERS

WITH users AS (
    SELECT
        DATA:id::INTEGER AS user_id,
        DATA:name:firstname::VARCHAR AS first_name,
        DATA:name:lastname::VARCHAR AS last_name,
        DATA:email::VARCHAR AS email,
        DATA:username::VARCHAR AS username,
        DATA:phone::VARCHAR AS phone,
        DATA:address:city::VARCHAR AS city,
        DATA:address:street::VARCHAR AS street,
        DATA:address:number::INTEGER AS address_number,
        DATA:address:zipcode::VARCHAR AS zip_code
    FROM ECOMMERCE_DB.RAW.USERS_RAW
),
cleaned_users AS (
    SELECT
        user_id,
        INITCAP(TRIM(first_name)) AS first_name,
        INITCAP(TRIM(last_name)) AS last_name,
        LOWER(TRIM(email)) AS email,
        TRIM(username) AS username,
        TRIM(phone) AS phone,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(street)) AS street,
        address_number,
        TRIM(zip_code) AS zip_code,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY user_id
        ) AS row_num
    FROM users
    WHERE user_id IS NOT NULL
      AND first_name IS NOT NULL
      AND TRIM(first_name) <> ''
      AND last_name IS NOT NULL
      AND TRIM(last_name) <> ''
      AND email IS NOT NULL
      AND TRIM(email) <> ''
)
SELECT *
FROM cleaned_users
WHERE row_num = 1;


-- ============================================
-- STEP 6: CREATE FINAL USERS TABLE
-- ============================================

CREATE OR REPLACE TABLE ECOMMERCE_DB.ANALYTICS.USERS AS

WITH users AS (
    SELECT
        DATA:id::INTEGER AS user_id,
        DATA:name:firstname::VARCHAR AS first_name,
        DATA:name:lastname::VARCHAR AS last_name,
        DATA:email::VARCHAR AS email,
        DATA:username::VARCHAR AS username,
        DATA:phone::VARCHAR AS phone,
        DATA:address:city::VARCHAR AS city,
        DATA:address:street::VARCHAR AS street,
        DATA:address:number::INTEGER AS address_number,
        DATA:address:zipcode::VARCHAR AS zip_code
    FROM ECOMMERCE_DB.RAW.USERS_RAW
),

cleaned_users AS (
    SELECT
        user_id,
        INITCAP(TRIM(first_name)) AS first_name,
        INITCAP(TRIM(last_name)) AS last_name,
        LOWER(TRIM(email)) AS email,
        TRIM(username) AS username,
        TRIM(phone) AS phone,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(street)) AS street,
        address_number,
        TRIM(zip_code) AS zip_code,

        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY user_id
        ) AS row_num

    FROM users

    WHERE user_id IS NOT NULL
      AND first_name IS NOT NULL
      AND TRIM(first_name) <> ''
      AND last_name IS NOT NULL
      AND TRIM(last_name) <> ''
      AND email IS NOT NULL
      AND TRIM(email) <> ''
)

SELECT
    user_id,
    first_name,
    last_name,
    email,
    username,
    phone,
    city,
    street,
    address_number,
    zip_code

FROM cleaned_users
WHERE row_num = 1;

-- ============================================
-- STEP 7: VALIDATE FINAL USERS TABLE
-- ============================================

-- Check total users
SELECT COUNT(*) AS total_users
FROM ECOMMERCE_DB.ANALYTICS.USERS;

-- Preview the final table
SELECT *
FROM ECOMMERCE_DB.ANALYTICS.USERS
ORDER BY user_id;

-- Check duplicate user IDs
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM ECOMMERCE_DB.ANALYTICS.USERS
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Check missing required values
SELECT
    COUNT_IF(user_id IS NULL) AS missing_user_id,
    COUNT_IF(first_name IS NULL) AS missing_first_name,
    COUNT_IF(last_name IS NULL) AS missing_last_name,
    COUNT_IF(email IS NULL) AS missing_email
FROM ECOMMERCE_DB.ANALYTICS.USERS;