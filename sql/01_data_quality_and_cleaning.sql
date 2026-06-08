/*
  SQL Retail Sales Analysis
  Step 01: Data quality checks and cleaned analysis view

  Dialect: MySQL 8.0
  Expected source table: uk_retail_raw
*/

-- Preview the highest-value completed order lines.
SELECT
    order_id,
    customer_id,
    customer_name,
    city,
    product_name,
    unit_price,
    quantity,
    line_amount,
    ROUND(unit_price * quantity, 2) AS calculated_line_amount
FROM uk_retail_raw
WHERE LOWER(TRIM(order_status)) = 'completed'
ORDER BY calculated_line_amount DESC
LIMIT 20;

-- Find line amount records that do not match unit_price * quantity.
SELECT
    order_id,
    product_id,
    product_name,
    line_amount,
    ROUND(unit_price * quantity, 2) AS calculated_line_amount,
    ROUND(line_amount - (unit_price * quantity), 2) AS difference
FROM uk_retail_raw
WHERE ROUND(line_amount, 2) <> ROUND(unit_price * quantity, 2)
ORDER BY ABS(line_amount - (unit_price * quantity)) DESC;

-- Identify duplicated order/product line items.
SELECT
    order_id,
    product_id,
    COUNT(*) AS duplicate_rows
FROM uk_retail_raw
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC, order_id, product_id;

-- Check missing values in important columns.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS missing_customer_name,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS missing_product_name,
    SUM(CASE WHEN line_amount IS NULL THEN 1 ELSE 0 END) AS missing_line_amount
FROM uk_retail_raw;

-- Review order status values after standardization.
SELECT
    LOWER(TRIM(order_status)) AS normalized_order_status,
    COUNT(*) AS row_count
FROM uk_retail_raw
GROUP BY LOWER(TRIM(order_status))
ORDER BY row_count DESC;

-- Review text values that may need standardization.
SELECT
    'region' AS field_name,
    region AS raw_value,
    TRIM(region) AS trimmed_value,
    COUNT(*) AS row_count
FROM uk_retail_raw
GROUP BY region, TRIM(region)
HAVING region <> TRIM(region)

UNION ALL

SELECT
    'city' AS field_name,
    city AS raw_value,
    TRIM(city) AS trimmed_value,
    COUNT(*) AS row_count
FROM uk_retail_raw
GROUP BY city, TRIM(city)
HAVING city <> TRIM(city)

UNION ALL

SELECT
    'category' AS field_name,
    category AS raw_value,
    TRIM(category) AS trimmed_value,
    COUNT(*) AS row_count
FROM uk_retail_raw
GROUP BY category, TRIM(category)
HAVING category <> TRIM(category);

-- Cleaned view used by the portfolio analysis.
CREATE OR REPLACE VIEW clean_uk_retail AS
SELECT
    order_id,
    CAST(order_date AS DATE) AS order_date,
    LOWER(TRIM(order_status)) AS order_status,
    CAST(shipping_days AS UNSIGNED) AS shipping_days,

    customer_id,
    TRIM(customer_name) AS customer_name,
    LOWER(TRIM(email)) AS email,
    COALESCE(NULLIF(TRIM(region), ''), 'Unknown') AS region,
    COALESCE(NULLIF(TRIM(city), ''), 'Unknown') AS city,
    LOWER(TRIM(tier)) AS tier,
    CAST(signup_date AS DATE) AS signup_date,

    product_id,
    TRIM(product_name) AS product_name,
    LOWER(TRIM(category)) AS category,
    CAST(unit_price AS DECIMAL(10, 2)) AS unit_price,
    CAST(quantity AS SIGNED) AS quantity,
    CAST(line_amount AS DECIMAL(10, 2)) AS line_amount,

    LOWER(TRIM(payment_method)) AS payment_method,
    LOWER(TRIM(acquisition_channel)) AS acquisition_channel,

    NULLIF(TRIM(refund_id), '') AS refund_id,
    CASE
        WHEN refund_date IS NULL OR TRIM(refund_date) = '' THEN NULL
        ELSE CAST(refund_date AS DATE)
    END AS refund_date,
    COALESCE(CAST(refund_amount AS DECIMAL(10, 2)), 0.00) AS refund_amount,
    COALESCE(NULLIF(LOWER(TRIM(refund_reason)), ''), 'not_refunded') AS refund_reason
FROM uk_retail_raw;

-- Confirm the cleaned view can be queried.
SELECT *
FROM clean_uk_retail
LIMIT 20;
