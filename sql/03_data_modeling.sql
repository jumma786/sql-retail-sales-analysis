/*
  SQL Retail Sales Analysis
  Step 03: Normalize the cleaned retail data

  Run after sql/01_data_quality_and_cleaning.sql.
*/

DROP TABLE IF EXISTS refunds;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- Customers table: one row per customer.
CREATE TABLE customers AS
SELECT
    customer_id,
    MAX(customer_name) AS customer_name,
    MAX(email) AS email,
    MAX(region) AS region,
    MAX(city) AS city,
    MAX(tier) AS tier,
    MIN(signup_date) AS signup_date
FROM clean_uk_retail
GROUP BY customer_id;

-- Products table: one row per product.
CREATE TABLE products AS
SELECT
    product_id,
    MAX(product_name) AS product_name,
    MAX(category) AS category,
    MAX(unit_price) AS unit_price
FROM clean_uk_retail
GROUP BY product_id;

-- Orders table: one row per order.
CREATE TABLE orders AS
SELECT
    order_id,
    MIN(order_date) AS order_date,
    MAX(order_status) AS order_status,
    MAX(shipping_days) AS shipping_days,
    MAX(customer_id) AS customer_id,
    MAX(payment_method) AS payment_method,
    MAX(acquisition_channel) AS acquisition_channel
FROM clean_uk_retail
GROUP BY order_id;

-- Order items table: one row per order/product pair.
CREATE TABLE order_items AS
SELECT
    order_id,
    product_id,
    SUM(quantity) AS quantity,
    ROUND(SUM(line_amount), 2) AS line_amount
FROM clean_uk_retail
GROUP BY order_id, product_id;

-- Refunds table: one row per refund.
CREATE TABLE refunds AS
SELECT
    refund_id,
    MAX(order_id) AS order_id,
    MAX(product_id) AS product_id,
    MAX(refund_date) AS refund_date,
    ROUND(MAX(refund_amount), 2) AS refund_amount,
    MAX(refund_reason) AS refund_reason
FROM clean_uk_retail
WHERE refund_id IS NOT NULL
GROUP BY refund_id;

-- Validation: each dimension/entity table should have unique keys.
SELECT 'customers' AS table_name, customer_id AS key_value, COUNT(*) AS row_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'products' AS table_name, product_id AS key_value, COUNT(*) AS row_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'orders' AS table_name, order_id AS key_value, COUNT(*) AS row_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1

UNION ALL

SELECT 'refunds' AS table_name, refund_id AS key_value, COUNT(*) AS row_count
FROM refunds
GROUP BY refund_id
HAVING COUNT(*) > 1;

-- Validation: completed revenue should match between clean view and normalized tables.
SELECT
    source,
    completed_revenue
FROM (
    SELECT
        'clean_uk_retail' AS source,
        ROUND(SUM(line_amount), 2) AS completed_revenue
    FROM clean_uk_retail
    WHERE order_status = 'completed'

    UNION ALL

    SELECT
        'normalized_tables' AS source,
        ROUND(SUM(oi.line_amount), 2) AS completed_revenue
    FROM order_items oi
    JOIN orders o
      ON oi.order_id = o.order_id
    WHERE o.order_status = 'completed'
) revenue_check;
