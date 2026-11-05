-- ============================================
-- ANALYTICS QUERY 1: JOIN THREE TABLES
-- ============================================
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;
SELECT
    c.cart_id,
    c.cart_date,

    u.first_name,
    u.last_name,

    p.product_name,
    p.category,
    p.price,

    c.quantity,

    p.price * c.quantity AS item_value

FROM ECOMMERCE_DB.ANALYTICS.CARTS c

JOIN ECOMMERCE_DB.ANALYTICS.USERS u
    ON c.user_id = u.user_id

JOIN ECOMMERCE_DB.ANALYTICS.PRODUCTS p
    ON c.product_id = p.product_id

ORDER BY c.cart_id, p.product_id;

-- ============================================
-- ANALYTICS QUERY 2: TOTAL QUANTITY PER CART
-- ============================================

SELECT
    cart_id,
    user_id,
    SUM(quantity) AS total_products
FROM ECOMMERCE_DB.ANALYTICS.CARTS
GROUP BY
    cart_id,
    user_id
ORDER BY cart_id;

-- ============================================
-- ANALYTICS QUERY 3: TOTAL CARTS PER USER
-- ============================================

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(DISTINCT c.cart_id) AS total_carts

FROM ECOMMERCE_DB.ANALYTICS.USERS u

LEFT JOIN ECOMMERCE_DB.ANALYTICS.CARTS c
    ON u.user_id = c.user_id

GROUP BY
    u.user_id,
    u.first_name,
    u.last_name

ORDER BY total_carts DESC;

SELECT
    product_id,
    product_name,
    price,
    RANK() OVER (
        ORDER BY price DESC
    ) AS price_rank
FROM ECOMMERCE_DB.ANALYTICS.PRODUCTS;